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
    var alarms: [CatchUpAlarm]
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
    private let alarmsKey = "alarms.v2"
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

        if let data = defaults.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([CatchUpAlarm].self, from: data) {
            alarms = decoded
        } else if defaults.bool(forKey: alarmEnabledKey) {
            let savedTime = defaults.object(forKey: alarmTimeKey) as? Date
                ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 0))
                ?? .now
            let systemID = defaults.string(forKey: alarmIDKey).flatMap(UUID.init(uuidString:))
            alarms = [CatchUpAlarm(
                time: savedTime,
                isEnabled: true,
                systemID: systemID,
                deliveryMode: systemID == nil ? nil : .alarmKit
            )]
        } else {
            alarms = []
        }
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
        settings.dailyStoryCount = 4
        backendAccessToken = keychain.read(account: "access-token")
    }

    var requiredStories: [NewsStory] {
        Array(stories.prefix(4))
    }

    var completedCount: Int {
        requiredStories.filter { progress.completedStoryIDs.contains($0.id) }.count
    }

    var isCaughtUp: Bool {
        !requiredStories.isEmpty && completedCount == requiredStories.count
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
        settings.dailyStoryCount = 4
        if settings.selectedTopics.isEmpty {
            settings.selectedTopics = [.world]
        }
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
        keychain.write(backendAccessToken.trimmingCharacters(in: .whitespacesAndNewlines), account: "access-token")
        if settings.shieldingEnabled,
           focusMode.isAuthorized,
           let firstAlarm = earliestEnabledAlarm {
            try? focusMode.scheduleMorningShield(at: firstAlarm.time)
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

    @discardableResult
    func saveAlarm(id: UUID? = nil, time: Date, label: String) async -> Bool {
        alarmMessage = nil
        let cleanLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalLabel = cleanLabel.isEmpty ? "Morning catch-up" : cleanLabel
        let existingIndex = id.flatMap { alarmID in alarms.firstIndex { $0.id == alarmID } }
        let shouldEnable = existingIndex.map { alarms[$0].isEnabled } ?? true

        if !shouldEnable, let existingIndex {
            alarms[existingIndex].time = time
            alarms[existingIndex].label = finalLabel
            persistAlarms()
            alarmMessage = "Alarm updated. Turn it on when you're ready."
            return true
        }

        do {
            let scheduled = try await alarmScheduler.scheduleDaily(at: time, label: finalLabel)
            if let existingIndex {
                let previous = alarms[existingIndex]
                if let oldSystemID = previous.systemID {
                    alarmScheduler.cancel(id: oldSystemID, deliveryMode: previous.deliveryMode)
                }
                alarms[existingIndex].time = time
                alarms[existingIndex].label = finalLabel
                alarms[existingIndex].isEnabled = true
                alarms[existingIndex].systemID = scheduled.systemID
                alarms[existingIndex].deliveryMode = scheduled.deliveryMode
            } else {
                alarms.append(CatchUpAlarm(
                    time: time,
                    label: finalLabel,
                    isEnabled: true,
                    systemID: scheduled.systemID,
                    deliveryMode: scheduled.deliveryMode
                ))
            }
            sortAndPersistAlarms()
            refreshShieldSchedule()
            alarmMessage = scheduled.deliveryMode == .alarmKit
                ? "System alarm scheduled. It can ring through Silent Mode and Focus."
                : "AlarmKit isn't available with this signing profile, so a daily notification was scheduled instead. Keep Catch Up notifications and sound enabled."
            return true
        } catch {
            alarmMessage = error.localizedDescription
            return false
        }
    }

    func setAlarmEnabled(id: UUID, enabled: Bool) async {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarmMessage = nil

        if !enabled {
            if let systemID = alarms[index].systemID {
                alarmScheduler.cancel(id: systemID, deliveryMode: alarms[index].deliveryMode)
            }
            alarms[index].isEnabled = false
            alarms[index].systemID = nil
            alarms[index].deliveryMode = nil
            persistAlarms()
            refreshShieldSchedule()
            alarmMessage = "Alarm turned off."
            return
        }

        do {
            let scheduled = try await alarmScheduler.scheduleDaily(
                at: alarms[index].time,
                label: alarms[index].label
            )
            alarms[index].isEnabled = true
            alarms[index].systemID = scheduled.systemID
            alarms[index].deliveryMode = scheduled.deliveryMode
            persistAlarms()
            refreshShieldSchedule()
            alarmMessage = scheduled.deliveryMode == .alarmKit
                ? "Alarm turned on."
                : "Alarm turned on as a daily notification because AlarmKit isn't available with this signing profile."
        } catch {
            alarms[index].isEnabled = false
            persistAlarms()
            alarmMessage = error.localizedDescription
        }
    }

    func deleteAlarm(id: UUID) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        let alarm = alarms.remove(at: index)
        if let systemID = alarm.systemID {
            alarmScheduler.cancel(id: systemID, deliveryMode: alarm.deliveryMode)
        }
        persistAlarms()
        refreshShieldSchedule()
        alarmMessage = "Alarm deleted."
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

    private var earliestEnabledAlarm: CatchUpAlarm? {
        alarms
            .filter(\.isEnabled)
            .min { minutesFromMidnight($0.time) < minutesFromMidnight($1.time) }
    }

    private func minutesFromMidnight(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private func sortAndPersistAlarms() {
        alarms.sort { minutesFromMidnight($0.time) < minutesFromMidnight($1.time) }
        persistAlarms()
    }

    private func persistAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            defaults.set(data, forKey: alarmsKey)
        }
        defaults.removeObject(forKey: alarmTimeKey)
        defaults.removeObject(forKey: alarmEnabledKey)
        defaults.removeObject(forKey: alarmIDKey)
    }

    private func refreshShieldSchedule() {
        guard settings.shieldingEnabled,
              focusMode.isAuthorized,
              let firstAlarm = earliestEnabledAlarm else {
            focusMode.disableMorningShieldSchedule()
            return
        }
        try? focusMode.scheduleMorningShield(at: firstAlarm.time)
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

