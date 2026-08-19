import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "newspaper") }

            NavigationStack {
                AlarmView()
            }
            .tabItem { Label("Alarm", systemImage: "alarm") }

            NavigationStack {
                StreakView()
            }
            .tabItem { Label("Streak", systemImage: "flame") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "safari") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.black)
        .task { await store.loadBriefing() }
        .fullScreenCover(isPresented: Binding(
            get: { !store.settings.onboardingCompleted },
            set: { _ in }
        )) {
            OnboardingView()
        }
    }
}

