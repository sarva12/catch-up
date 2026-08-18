import Foundation
import SwiftUI
import AlarmKit
import AppIntents

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

    func requestAuthorization() async throws -> Bool {
        try await manager.requestAuthorization() == .authorized
    }

    func scheduleDaily(at date: Date, replacing existingID: UUID?) async throws -> UUID {
        if let existingID {
            try? manager.cancel(id: existingID)
        }

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
            title: "Your morning catch-up is ready",
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

    func cancel(id: UUID) throws {
        try manager.cancel(id: id)
    }
}

