import Foundation
import SwiftUI
@preconcurrency import AlarmKit
import AppIntents
@preconcurrency import UserNotifications

struct CatchUpAlarmMetadata: AlarmMetadata {}

struct OpenCatchUpIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Catch-up"
    static let description = IntentDescription("Opens today's news briefing.")
    static let openAppWhenRun = true

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

@MainActor
struct AlarmScheduler {
    private let manager = AlarmManager.shared

    func scheduleDaily(at date: Date, label: String) async throws -> ScheduledAlarm {
        do {
            let authorization = try await manager.requestAuthorization()
            if authorization == .authorized {
                let id = try await scheduleAlarmKit(at: date, label: label)
                return ScheduledAlarm(systemID: id, deliveryMode: .alarmKit)
            }
        } catch {
            // Personal SideStore profiles can reject AlarmKit on physical devices.
            // A standard notification keeps the saved alarm functional in that case.
        }

        return try await scheduleNotification(at: date, label: label)
    }

    func cancel(id: UUID, deliveryMode: AlarmDeliveryMode?) {
        if deliveryMode == .notification {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: [notificationIdentifier(for: id)]
            )
        } else {
            try? manager.cancel(id: id)
        }
    }

    private func scheduleAlarmKit(at date: Date, label: String) async throws -> UUID {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let time = Alarm.Schedule.Relative.Time(
            hour: components.hour ?? 7,
            minute: components.minute ?? 0
        )
        let weekdays: [Locale.Weekday] = [
            .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
        ]
        let schedule = Alarm.Schedule.relative(.init(time: time, repeats: .weekly(weekdays)))
        let startButton = AlarmButton(
            text: "Start Catch-up",
            textColor: .white,
            systemImageName: "newspaper"
        )
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "stop.fill"
        )
        let alert = AlarmPresentation.Alert(
            title: label,
            stopButton: stopButton,
            secondaryButton: startButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<CatchUpAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: CatchUpAlarmMetadata(),
            tintColor: .black
        )
        let id = UUID()
        let configuration = AlarmManager.AlarmConfiguration<CatchUpAlarmMetadata>(
            schedule: schedule,
            attributes: attributes,
            secondaryIntent: OpenCatchUpIntent(alarmID: id.uuidString)
        )
        _ = try await manager.schedule(id: id, configuration: configuration)
        return id
    }

    private func scheduleNotification(at date: Date, label: String) async throws -> ScheduledAlarm {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else { throw AlarmSchedulingError.notificationsDenied }

        let id = UUID()
        let content = UNMutableNotificationContent()
        content.title = label
        content.body = "Your daily briefing is ready. Tap to start your catch-up."
        content.sound = .default
        content.categoryIdentifier = "CATCH_UP_ALARM"

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: id),
            content: content,
            trigger: trigger
        )
        try await center.add(request)
        return ScheduledAlarm(systemID: id, deliveryMode: .notification)
    }

    private func notificationIdentifier(for id: UUID) -> String {
        "catch-up.alarm.\(id.uuidString)"
    }
}

enum AlarmSchedulingError: LocalizedError {
    case notificationsDenied

    var errorDescription: String? {
        switch self {
        case .notificationsDenied:
            "Alarm and notification access are turned off. Enable notifications for Catch Up in iPhone Settings."
        }
    }
}

