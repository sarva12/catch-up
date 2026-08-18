import Foundation

struct CachedBriefing: Codable, Sendable {
    let fetchedAt: Date
    let stories: [NewsStory]
}

actor BriefingCache {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        fileURL = directory.appending(path: "latest-briefing.json")
    }

    func load() -> CachedBriefing? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CachedBriefing.self, from: data)
    }

    func save(_ stories: [NewsStory], now: Date = .now) {
        let cached = CachedBriefing(fetchedAt: now, stories: stories)
        guard let data = try? JSONEncoder().encode(cached) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}


