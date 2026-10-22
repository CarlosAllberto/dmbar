import AppKit

/// Conteúdo do popover: mostra o WebView compartilhado enquanto está aberto.
final class PopoverController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 560))
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        let webView = WebViewHost.shared.webView
        webView.removeFromSuperview()
        webView.frame = view.bounds
        webView.autoresizingMask = [.width, .height]
        view.addSubview(webView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Abrir pelo teclado (Option+D) faz o WebKit mostrar o anel de foco no último elemento focado, como a aba Primary.
        WebViewHost.shared.webView.evaluateJavaScript("document.activeElement?.blur()")
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        WebViewHost.shared.park()
    }
}
