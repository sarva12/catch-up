import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("CATCH UP")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(2.5)
                Spacer()
                Text("\(page + 1) / 3")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }

            Spacer()

            if page == 0 {
                Text("Wake up.\nCatch up.\nMove on.")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .tracking(-1.8)
                Text("A short daily briefing with a clear finish—built to make staying informed automatic.")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .lineSpacing(5)
            } else if page == 1 {
                Text("Choose what\nmatters.")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                VStack(spacing: 0) {
                    ForEach(NewsTopic.allCases) { topic in
                        Button {
                            if store.settings.selectedTopics.contains(topic) {
                                store.settings.selectedTopics.remove(topic)
                            } else {
                                store.settings.selectedTopics.insert(topic)
                            }
                        } label: {
                            HStack {
                                Text(topic.rawValue)
                                Spacer()
                                Image(systemName: store.settings.selectedTopics.contains(topic) ? "checkmark.square.fill" : "square")
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.vertical, 15)
                        }
                        Divider()
                    }
                }
            } else {
                Text("Keep it\nfinite.")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                VStack(alignment: .leading, spacing: 5) {
                    Text("4 stories each morning")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("Usually 8–12 minutes")
                        .foregroundStyle(.secondary)
                }
                Text("Completing four ends the required session and advances your streak. If curiosity wins, the full Perplexity Discover feed is waiting in Explore.")
                    .font(.system(size: 17, design: .serif))
                    .lineSpacing(4)
            }

            Spacer()

            Button {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    store.completeOnboarding()
                }
            } label: {
                Text(page < 2 ? "CONTINUE" : "START CATCHING UP")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(MonochromeButtonStyle(filled: true))
        }
        .padding(24)
        .interactiveDismissDisabled()
        .background(Color.white)
    }
}

