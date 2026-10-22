import UserNotifications

/// Notificações nativas. Sem texto da mensagem: o app só sabe o contador de não lidas.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    /// Chamado quando o usuário clica na notificação.
    var onOpen: (() -> Void)?

    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            #if DEBUG
            NSLog("DMBAR notif granted %@ %@", "\(granted)", error?.localizedDescription ?? "")
            #endif
        }
    }

    func notifyUnread(_ count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Nova mensagem no Instagram"
        content.body = count == 1 ? "1 conversa não lida" : "\(count) conversas não lidas"
        content.sound = .default
        // Mesmo identificador: a notificação nova substitui a anterior em vez de empilhar.
        center.add(UNNotificationRequest(identifier: "unread", content: content, trigger: nil))
    }

    func clear() {
        center.removeDeliveredNotifications(withIdentifiers: ["unread"])
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async { self.onOpen?() }
        completionHandler()
    }
}
