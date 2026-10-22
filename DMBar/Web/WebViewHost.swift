import AppKit
import WebKit

/// Dono único do WKWebView. Quando o popover fecha, a view volta para uma janela
/// oculta, para o macOS não suspender a página e as mensagens continuarem chegando.
final class WebViewHost: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    static let shared = WebViewHost()

    static let inboxURL = URL(string: "https://www.instagram.com/direct/inbox/")!
    // Só o sufixo muda: o resto do user agent vem do WebKit real, então não destoa da engine instalada.
    private static let userAgentSuffix = "Version/27.0.1 Safari/605.1.15"

    let webView: WKWebView
    private let hiddenWindow: NSWindow
    private var popupWindows: [ObjectIdentifier: NSWindow] = [:]

    /// Chamado quando o número de conversas não lidas muda.
    var onUnreadChange: ((Int) -> Void)?
    private(set) var unreadCount = 0

    private override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()  // mantém o login entre aberturas
        config.applicationNameForUserAgent = Self.userAgentSuffix
        config.userContentController.addUserScript(Scripts.userScript)

        let size = NSRect(x: 0, y: 0, width: 380, height: 560)
        webView = WKWebView(frame: size, configuration: config)

        hiddenWindow = NSWindow(contentRect: size, styleMask: .borderless, backing: .buffered, defer: false)
        hiddenWindow.isReleasedWhenClosed = false
        hiddenWindow.ignoresMouseEvents = true
        hiddenWindow.alphaValue = 0
        hiddenWindow.setFrameOrigin(NSPoint(x: -10000, y: -10000))

        super.init()
        config.userContentController.add(self, name: "unread")
        #if DEBUG
        if #available(macOS 13.3, *) { webView.isInspectable = true }
        // Foto da página a cada 3 s em tmp/dmbar.png, para ajustar o CSS sem abrir o popover.
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.webView.takeSnapshot(with: nil) { image, _ in
                guard let tiff = image?.tiffRepresentation,
                      let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
                try? png.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("dmbar.png"))
            }
            self?.domOutline { text in
                try? text.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("dom.txt"), atomically: true, encoding: .utf8)
            }
        }
        #endif
        webView.navigationDelegate = self
        webView.uiDelegate = self
        park()
        var start = Self.inboxURL
        #if DEBUG
        // Permite reabrir direto numa conversa ao testar CSS: DMBAR_URL=https://www.instagram.com/direct/t/...
        if let env = ProcessInfo.processInfo.environment["DMBAR_URL"], let url = URL(string: env) { start = url }
        #endif
        webView.load(URLRequest(url: start))
    }

    /// Devolve a view para a janela oculta.
    func park() {
        webView.removeFromSuperview()
        hiddenWindow.contentView = webView
        hiddenWindow.orderFrontRegardless()
    }

    #if DEBUG
    func copyDOMOutline() {
        domOutline { text in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    /// Esboço da árvore do DOM (tag, role, aria-label, tamanho e y) para achar seletores do CSS.
    func domOutline(_ completion: @escaping (String) -> Void) {
        let js = """
        (function walk(el, d) {
          if (d > 40 || !el.children) return '';
          let out = '';
          for (const c of el.children) {
            if (['SCRIPT','STYLE','LINK','META','SVG','PATH'].includes(c.tagName.toUpperCase())) continue;
            const box = c.getBoundingClientRect();
            if (box.width === 0 || box.height === 0) continue;  // invisível, só ruído
            const r = c.getAttribute('role'), a = c.getAttribute('aria-label'), h = c.getAttribute('href');
            out += ' '.repeat(d) + c.tagName.toLowerCase() + (r ? '[role=' + r + ']' : '') +
              (a ? '[aria-label=' + a + ']' : '') + (h ? '[href=' + h + ']' : '') +
              ' ' + Math.round(box.width) + 'x' + Math.round(box.height) + ' y' + Math.round(box.top) + '\\n';
            out += walk(c, d + 1);
          }
          return out;
        })(document.body, 0) + location.href
        """
        webView.evaluateJavaScript(js) { result, _ in
            if let text = result as? String { completion(text) }
        }
    }
    #endif

    func reload() {
        if webView.url == nil {
            webView.load(URLRequest(url: Self.inboxURL))
        } else {
            webView.reload()
        }
    }

    // MARK: WKScriptMessageHandler

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let count = body["count"] as? Int else { return }
        #if DEBUG
        NSLog("DMBAR title %@ count %d", body["title"] as? String ?? "-", count)
        #endif
        guard count != unreadCount else { return }
        unreadCount = count
        onUnreadChange?(count)
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        #if DEBUG
        NSLog("DMBAR nav %@ %@", "\(navigationAction.navigationType.rawValue)", navigationAction.request.url?.absoluteString.prefix(160).description ?? "-")
        #endif
        // Links clicados para fora do Instagram/Facebook (login 2FA e SSO usam esses domínios) abrem no navegador.
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           let host = url.host,
           !(host.hasSuffix("instagram.com") || host.hasSuffix("facebook.com")) {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    #if DEBUG
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("DMBAR fail %@", error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("DMBAR failProv %@", error.localizedDescription)
    }
    #endif

    // MARK: WKUIDelegate

    /// O login com Facebook abre um popup que devolve o resultado ao opener via postMessage.
    /// Por isso o popup precisa ser um WKWebView real criado com a configuração recebida.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        let size = NSSize(width: windowFeatures.width?.doubleValue ?? 520,
                          height: windowFeatures.height?.doubleValue ?? 640)
        let popup = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self

        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = popup
        window.center()
        window.makeKeyAndOrderFront(nil)
        popupWindows[ObjectIdentifier(popup)] = window
        return popup
    }

    func webViewDidClose(_ webView: WKWebView) {
        popupWindows.removeValue(forKey: ObjectIdentifier(webView))?.close()
    }
}
