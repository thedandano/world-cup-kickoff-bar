import UserNotifications
import WorldCupBarCore

@MainActor
protocol NotificationScheduling: AnyObject {
    func requestPermission() async
    func schedule(matches: [WorldCupMatch], followedCodes: Set<String>, minutesBefore: Int) async
    func cancelAll()
}

@MainActor
final class NotificationScheduler: NotificationScheduling {
    static let shared = NotificationScheduler()

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func schedule(matches: [WorldCupMatch], followedCodes: Set<String>, minutesBefore: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: matches.map { "kickoff-\($0.id)" })

        guard minutesBefore > 0 else { return }

        let now = Date()
        for match in matches {
            guard match.status == .scheduled else { continue }
            let isFollowed = followedCodes.contains(match.home.code)
                || followedCodes.contains(match.away.code)
            guard isFollowed else { continue }

            let fireDate = match.kickoffDate.addingTimeInterval(-Double(minutesBefore) * 60)
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Kickoff in \(minutesBefore) min"
            content.body = "\(match.home.name) vs \(match.away.name) · \(match.venue)"
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "kickoff-\(match.id)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
