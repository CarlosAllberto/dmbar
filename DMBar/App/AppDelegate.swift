import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var preferences: PreferencesWindow?
    private let notifications = NotificationService()
    private var lastUnread = 0
    private var hotKey: HotKeyService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.contentSize = NSSize(width: 380, height: 560)
        // transient fecha ao clicar fora; trocar por .applicationDefined se atrapalhar o chat
        popover.behavior = .transient
        popover.contentViewController = PopoverController()
        popover.delegate = self
        _ = WebViewHost.shared  // carrega a página já na abertura, para receber mensagens em segundo plano

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "DMBar")
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeading
        }
        hotKey = HotKeyService { [weak self] in self?.togglePopover() }
        notifications.requestPermission()
        notifications.onOpen = { [weak self] in self?.showPopover() }
        WebViewHost.shared.onUnreadChange = { [weak self] count in
            guard let self else { return }
            // O número muda a largura do ícone, e o popover aberto não acompanha: só atualiza com ele fechado.
            if !popover.isShown { updateBadge() }
            // Só avisa quando o contador sobe e o usuário não está olhando as DMs.
            if count > lastUnread && !popover.isShown {
                notifications.notifyUnread(count)
            } else if count == 0 {
                notifications.clear()
            }
            lastUnread = count
        }
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateBadge() {
        let count = WebViewHost.shared.unreadCount
        statusItem.button?.title = count > 0 ? " \(count)" : ""
    }

    func popoverDidClose(_ notification: Notification) {
        updateBadge()
    }

    private func showPopover() {
        if !popover.isShown { togglePopover() }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Atualizar", action: #selector(reload), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Preferências…", action: #selector(showPreferences), keyEquivalent: ",").target = self
        #if DEBUG
        menu.addItem(withTitle: "Debug: copiar DOM", action: #selector(copyDOM), keyEquivalent: "").target = self
        #endif
        menu.addItem(.separator())
        menu.addItem(withTitle: "Sair da conta…", action: #selector(logout), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Sair", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        // Atribuir o menu só durante o clique evita que o botão passe a ignorar o left click.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func reload() {
        WebViewHost.shared.reload()
    }

    #if DEBUG
    @objc private func copyDOM() {
        WebViewHost.shared.copyDOMOutline()
    }
    #endif

    @objc private func logout() {
        let alert = NSAlert()
        alert.messageText = "Sair da conta do Instagram?"
        alert.informativeText = "O DMBar apaga a sessão salva. Para voltar, você entra de novo com usuário e senha."
        alert.addButton(withTitle: "Sair da conta")
        alert.addButton(withTitle: "Cancelar")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            WebViewHost.shared.logout()
        }
    }

    @objc private func showPreferences() {
        if preferences == nil { preferences = PreferencesWindow() }
        preferences?.show()
    }
}
