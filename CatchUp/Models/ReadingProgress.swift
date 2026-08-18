import Foundation

struct ReadingProgress: Codable, Sendable {
    var completedStoryIDs: Set<String> = []
    var briefingDay: Date?
    var currentStreak = 0
    var longestStreak = 0
    var lastCompletionDay: Date?

    mutating func completeDay(now: Date = .now, calendar: Calendar = .current) {
        guard lastCompletionDay.map({ !calendar.isDate($0, inSameDayAs: now) }) ?? true else {
            return
        }

        if let lastCompletionDay,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(lastCompletionDay, inSameDayAs: yesterday) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastCompletionDay = now
    }

    mutating func beginDayIfNeeded(now: Date = .now, calendar: Calendar = .current) {
        guard briefingDay.map({ !calendar.isDate($0, inSameDayAs: now) }) ?? true else {
            return
        }
        completedStoryIDs.removeAll()
        briefingDay = now
    }
}

