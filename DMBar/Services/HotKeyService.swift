import Carbon

/// Atalho global via Carbon: funciona com sandbox e sem permissão de Acessibilidade.
/// shortcut: fixo em Option+D; trocar por um gravador nas Preferências se pedirem atalho configurável.
final class HotKeyService {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { service.action() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)

        let id = EventHotKeyID(signature: OSType(0x444D4252), id: 1)  // "DMBR"
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_D), UInt32(optionKey), id,
                                         GetApplicationEventTarget(), 0, &hotKey)
        if status != noErr {
            NSLog("DMBar: atalho Option+D indisponível (%d), outro app pode estar usando", status)
        }
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
