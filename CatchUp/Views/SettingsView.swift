import SwiftUI
#if !FREE_SIDELOAD
import FamilyControls
#endif

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAppPicker = false

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Briefing") {
                Stepper("\(store.settings.dailyStoryCount) stories", value: $store.settings.dailyStoryCount, in: 3...7)
                ForEach(NewsTopic.allCases) { topic in
                    Toggle(topic.rawValue, isOn: Binding(
                        get: { store.settings.selectedTopics.contains(topic) },
                        set: { selected in
                            if selected { store.settings.selectedTopics.insert(topic) }
                            else { store.settings.selectedTopics.remove(topic) }
                        }
                    ))
                }
            }

            Section("News service") {
                TextField("https://your-backend.example", text: $store.settings.backendURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                SecureField("Private access token", text: $store.backendAccessToken)
                    .textInputAutocapitalization(.never)
                Text(store.settings.backendURL.isEmpty ? "Demo mode is active." : "Live news will refresh from this secure backend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            #if FREE_SIDELOAD
            Section("Morning focus") {
                Text("This free AltStore edition uses the alarm's Start Catch-up button instead of blocking other apps. Screen Time shielding requires special Apple provisioning.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            #else
            Section("Morning focus") {
                Toggle("Shield distracting apps", isOn: $store.settings.shieldingEnabled)
                if store.settings.shieldingEnabled {
                    Button(store.focusMode.isAuthorized ? "Screen Time access enabled" : "Enable Screen Time access") {
                        Task { await store.focusMode.requestAuthorization() }
                    }
                    .foregroundStyle(.black)
                    Button("Choose distracting apps") { showAppPicker = true }
                        .foregroundStyle(.black)
                    if let message = store.focusMode.message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            #endif

            Section {
                Button("Save and refresh") {
                    store.saveSettings()
                    Task { await store.loadBriefing() }
                }
                .foregroundStyle(.black)
            }

            Section("Privacy") {
                Text("Reading progress and preferences stay on this device. The backend receives only the selected topics and requested story count.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
        .tint(.black)
        .modifier(FreeCompatiblePickerModifier(isPresented: $showAppPicker, store: store))
    }
}

private struct FreeCompatiblePickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let store: AppStore

    @ViewBuilder
    func body(content: Content) -> some View {
        #if FREE_SIDELOAD
        content
        #else
        content.familyActivityPicker(isPresented: $isPresented, selection: Binding(
            get: { store.focusMode.selection },
            set: { selection in
                store.focusMode.selection = selection
                store.focusMode.saveSelection()
            }
        ))
        #endif
    }
}

