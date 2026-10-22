import AppKit
import ServiceManagement
import SwiftUI

struct PreferencesView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var error: String?

    var body: some View {
        Form {
            Toggle("Abrir ao iniciar o Mac", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        error = nil
                    } catch {
                        self.error = error.localizedDescription
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            LabeledContent("Abrir e fechar o DMBar", value: "⌥D")
            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

final class PreferencesWindow {
    private let window: NSWindow

    init() {
        window = NSWindow(contentViewController: NSHostingController(rootView: PreferencesView()))
        window.title = "Preferências do DMBar"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
