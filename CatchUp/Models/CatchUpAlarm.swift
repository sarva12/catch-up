import Foundation

enum AlarmDeliveryMode: String, Codable, Sendable {
    case alarmKit
    case notification
}

struct CatchUpAlarm: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var time: Date
    var label: String
    var isEnabled: Bool
    var systemID: UUID?
    var deliveryMode: AlarmDeliveryMode?

    init(
        id: UUID = UUID(),
        time: Date,
        label: String = "Morning catch-up",
        isEnabled: Bool = true,
        systemID: UUID? = nil,
        deliveryMode: AlarmDeliveryMode? = nil
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.systemID = systemID
        self.deliveryMode = deliveryMode
    }
}

struct ScheduledAlarm: Sendable {
    let systemID: UUID
    let deliveryMode: AlarmDeliveryMode
}

