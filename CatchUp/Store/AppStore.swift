import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var stories: [NewsStory] = []
    var loadState: LoadState = .idle
    var progress: ReadingProgress
    var alarmTime: Date
    var alarmEnabled: Bool
    var alarmMessage: String?
    var settings: AppSettings
    var briefingNotice: String?
    var backendAccessToken: String
    let focusMode = FocusModeController()

    private let injectedNewsService: (any NewsServing)?
    private let defaults: UserDefaults
    private let cache = BriefingCache()
    private let keychain = KeychainStore()
    private let alarmScheduler = AlarmScheduler()
    private let progressKey = "readingProgress"
    private let alarmTimeKey = "alarmTime"
    private let alarmEnabledKey = "alarmEnabled"
    private let alarmIDKey = "alarmID"
    private let settingsKey = "appSettings"

    init(newsService: (any NewsServing)? = nil, defaults: UserDefaults = .standard) {
        injectedNewsService = newsService
        self.defaults = defaults

        if let data = defaults.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(ReadingProgress.self, from: data) {
            progress = decoded
        } else {
            progress = ReadingProgress()
        }

        if let savedTime = defaults.object(forKey: alarmTimeKey) as? Date {
            alarmTime = savedTime
        } else {
            alarmTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
        }
        alarmEnabled = defaults.bool(forKey: alarmEnabledKey)
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
        backendAccessToken = keychain.read(account: "access-token")
    }

    var completedCount: Int {
        stories.filter { progress.completedStoryIDs.contains($0.id) }.count
    }

    var isCaughtUp: Bool {
        !stories.isEmpty && completedCount == stories.count
    }

    func loadBriefing() async {
        guard loadState != .loading else { return }
        loadState = .loading
        briefingNotice = nil
        do {
            let service = try newsService()
            stories = try await service.fetchBriefing()
            await cache.save(stories)
            resetStoryProgressIfNeeded()
            loadState = .loaded
        } catch {
            if let cached = await cache.load() {
                stories = cached.stories
                resetStoryProgressIfNeeded()
                briefingNotice = "Offline copy from \(cached.fetchedAt.formatted(date: .abbreviated, time: .shortened))"
                loadState = .loaded
            } else {
                loadState = .failed("Couldn't load today's briefing. Pull down to try again.")
            }
        }
    }

    func completeOnboarding() {
        settings.onboardingCompleted = true
        saveSettings()
        Task { await loadBriefing() }
    }

    func saveSettings() {
        settings.dailyStoryCount = min(max(settings.dailyStoryCount, 3), 7)
        if settings.selectedTopics.isEmpty {
            settings.selectedTopics = [.world]
        }
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
        keychain.write(backendAccessToken.trimmingCharacters(in: .whitespacesAndNewlines), account: "access-token")
        if settings.shieldingEnabled && focusMode.isAuthorized && alarmEnabled {
            try? focusMode.scheduleMorningShield(at: alarmTime)
        } else if !settings.shieldingEnabled {
            focusMode.disableMorningShieldSchedule()
        }
    }

    func markRead(_ story: NewsStory) {
        progress.beginDayIfNeeded()
        progress.completedStoryIDs.insert(story.id)
        if isCaughtUp {
            progress.completeDay()
            focusMode.endSession()
        }
        saveProgress()
    }

    func saveAlarm() async {
        alarmMessage = nil
        do {
            let authorized = try await alarmScheduler.requestAuthorization()
            guard authorized else {
                alarmEnabled = false
                alarmMessage = "Alarm access was not allowed. You can enable it in Settings."
                return
            }
            let existingID = defaults.string(forKey: alarmIDKey).flatMap(UUID.init(uuidString:))
            let newID = try await alarmScheduler.scheduleDaily(at: alarmTime, replacing: existingID)
            defaults.set(newID.uuidString, forKey: alarmIDKey)
            defaults.set(alarmTime, forKey: alarmTimeKey)
            defaults.set(true, forKey: alarmEnabledKey)
            alarmEnabled = true
            if settings.shieldingEnabled && focusMode.isAuthorized {
                try focusMode.scheduleMorningShield(at: alarmTime)
            }
            alarmMessage = "Daily alarm scheduled."
        } catch {
            alarmEnabled = false
            alarmMessage = "The alarm couldn't be scheduled: \(error.localizedDescription)"
        }
    }

    func disableAlarm() {
        if let rawID = defaults.string(forKey: alarmIDKey), let id = UUID(uuidString: rawID) {
            try? alarmScheduler.cancel(id: id)
        }
        defaults.removeObject(forKey: alarmIDKey)
        defaults.set(false, forKey: alarmEnabledKey)
        alarmEnabled = false
        focusMode.disableMorningShieldSchedule()
        alarmMessage = "Alarm turned off."
    }

    private func resetStoryProgressIfNeeded() {
        progress.beginDayIfNeeded()
        saveProgress()
    }

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }

    private func newsService() throws -> any NewsServing {
        if let injectedNewsService { return injectedNewsService }
        let trimmed = settings.backendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return DemoNewsService() }
        guard let url = URL(string: trimmed), url.scheme == "https" else { throw URLError(.badURL) }
        return RemoteNewsService(
            baseURL: url,
            topics: settings.selectedTopics,
            storyCount: settings.dailyStoryCount,
            accessToken: backendAccessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

