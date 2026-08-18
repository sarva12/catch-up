import XCTest
@testable import CatchUp

final class ReadingProgressTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testConsecutiveCompletionsGrowStreak() throws {
        var progress = ReadingProgress()
        let firstDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 17)))
        let secondDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: firstDay))

        progress.completeDay(now: firstDay, calendar: calendar)
        progress.completeDay(now: secondDay, calendar: calendar)

        XCTAssertEqual(progress.currentStreak, 2)
        XCTAssertEqual(progress.longestStreak, 2)
    }

    func testMissingDayRestartsStreak() throws {
        var progress = ReadingProgress()
        let firstDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 15)))
        let thirdDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 2, to: firstDay))

        progress.completeDay(now: firstDay, calendar: calendar)
        progress.completeDay(now: thirdDay, calendar: calendar)

        XCTAssertEqual(progress.currentStreak, 1)
        XCTAssertEqual(progress.longestStreak, 1)
    }

    func testNewDayClearsStoryProgress() throws {
        var progress = ReadingProgress(completedStoryIDs: ["story"], briefingDay: nil)
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 18)))

        progress.beginDayIfNeeded(now: day, calendar: calendar)

        XCTAssertTrue(progress.completedStoryIDs.isEmpty)
        XCTAssertEqual(progress.briefingDay, day)
    }

    func testSameDayCompletionDoesNotGrowStreakTwice() throws {
        var progress = ReadingProgress()
        let morning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 7)))
        let evening = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 20)))

        progress.completeDay(now: morning, calendar: calendar)
        progress.completeDay(now: evening, calendar: calendar)

        XCTAssertEqual(progress.currentStreak, 1)
    }
}

