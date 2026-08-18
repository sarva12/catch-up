import DeviceActivity
import ManagedSettings
import FamilyControls

final class CatchUpMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init("catchUpMorning"))

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity == ScreenTimeShared.activityName else { return }
        ScreenTimeShared.applyShield(selection: ScreenTimeShared.loadSelection(), store: store)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == ScreenTimeShared.activityName else { return }
        ScreenTimeShared.removeShield(store: store)
    }
}


