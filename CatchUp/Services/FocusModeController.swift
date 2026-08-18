import Foundation
import Observation

#if FREE_SIDELOAD
@MainActor
@Observable
final class FocusModeController {
    var isAuthorized = false
    var message: String?

    func requestAuthorization() async {
        message = "App blocking is available only in the fully provisioned edition."
    }

    func scheduleMorningShield(at alarmTime: Date) throws {}
    func endSession() {}
    func disableMorningShieldSchedule() {}
}
#else
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
@Observable
final class FocusModeController {
    var selection: FamilyActivitySelection
    var isAuthorized = false
    var message: String?

    private let authorization = AuthorizationCenter.shared
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore(named: .init("catchUpMorning"))

    init() {
        selection = ScreenTimeShared.loadSelection()
        isAuthorized = authorization.authorizationStatus == .approved
    }

    func requestAuthorization() async {
        do {
            try await authorization.requestAuthorization(for: .individual)
            isAuthorized = authorization.authorizationStatus == .approved
            message = isAuthorized ? "Screen Time access enabled." : "Screen Time access wasn't enabled."
        } catch {
            isAuthorized = false
            message = error.localizedDescription
        }
    }

    func saveSelection() {
        ScreenTimeShared.save(selection)
        message = selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty
            ? "Choose at least one app or category to shield."
            : "Distracting apps saved."
    }

    func scheduleMorningShield(at alarmTime: Date) throws {
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: alarmTime)
        let endDate = calendar.date(byAdding: .hour, value: 3, to: alarmTime) ?? alarmTime
        let end = calendar.dateComponents([.hour, .minute], from: endDate)
        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: true
        )
        center.stopMonitoring([ScreenTimeShared.activityName])
        try center.startMonitoring(ScreenTimeShared.activityName, during: schedule)
    }

    func endSession() {
        ScreenTimeShared.removeShield(store: store)
    }

    func disableMorningShieldSchedule() {
        center.stopMonitoring([ScreenTimeShared.activityName])
        endSession()
    }
}
#endif

