import SwiftUI

struct TodayView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            switch store.loadState {
            case .idle, .loading:
                ProgressView().tint(.black)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Briefing unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") { Task { await store.loadBriefing() } }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                }
            case .loaded:
                ScrollView {
                    LazyVStack(spacing: 0) {
                        CatchUpHeader()
                        if let notice = store.briefingNotice {
                            Text(notice.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(Array(store.stories.enumerated()), id: \.element.id) { index, story in
                            StoryCard(story: story, number: index + 1)
                            Divider().padding(.horizontal, 20)
                        }
                        if store.isCaughtUp {
                            CompletionCard()
                        }
                    }
                }
                .refreshable { await store.loadBriefing() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white)
    }
}

private struct CatchUpHeader: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("CATCH UP")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(2.5)
                Spacer()
                Label("\(store.progress.currentStreak)", systemImage: "flame.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            Text("What matters\nthis morning.")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .tracking(-1.5)
                .lineSpacing(-3)
            HStack {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                Spacer()
                Text("\(store.completedCount) / \(store.stories.count) READ")
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            ProgressView(value: Double(store.completedCount), total: Double(max(store.stories.count, 1)))
                .tint(.black)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 28)
    }
}

private struct StoryCard: View {
    @Environment(AppStore.self) private var store
    let story: NewsStory
    let number: Int

    private var isRead: Bool { store.progress.completedStoryIDs.contains(story.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(String(format: "%02d", number))
                Text(story.section)
                Spacer()
                Text("\(story.readTimeMinutes) MIN")
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.secondary)

            Text(story.headline)
                .font(.system(size: 27, weight: .bold, design: .serif))
                .lineSpacing(1)

            Text(story.summary)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 6) {
                Text("WHY IT MATTERS")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                Text(story.whyItMatters)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .lineSpacing(3)
            }
            .padding(16)
            .background(Color.black.opacity(0.055))

            HStack(spacing: 12) {
                Button {
                    store.markRead(story)
                } label: {
                    Label(isRead ? "READ" : "MARK AS READ", systemImage: isRead ? "checkmark" : "arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MonochromeButtonStyle(filled: !isRead))
                .disabled(isRead)

                Link(destination: story.sourceURL) {
                    Image(systemName: "arrow.up.right")
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(.black)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
                .accessibilityLabel("Open source from \(story.sourceName)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}

private struct CompletionCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
            Text("YOU'RE CAUGHT UP")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .tracking(1.5)
            Text("\(store.progress.currentStreak) day streak")
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text("Go live your day. We'll be here tomorrow.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
        .padding(.horizontal, 20)
    }
}

struct MonochromeButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundStyle(filled ? Color.white : Color.black)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(filled ? Color.black : Color.white)
            .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

