import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

enum ScreenTimeShared {
    static let appGroupID = "group.com.example.CatchUp"
    static let selectionKey = "focusSelection"
    static let activityName = DeviceActivityName("morningCatchUp")

    static func save(_ selection: FamilyActivitySelection) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? PropertyListEncoder().encode(selection) else { return }
        defaults.set(data, forKey: selectionKey)
    }

    static func loadSelection() -> FamilyActivitySelection {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: selectionKey),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }

    static func applyShield(selection: FamilyActivitySelection, store: ManagedSettingsStore) {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    static func removeShield(store: ManagedSettingsStore) {
        store.clearAllSettings()
    }
}

