import Foundation

protocol NewsServing: Sendable {
    func fetchBriefing() async throws -> [NewsStory]
}

struct DemoNewsService: NewsServing {
    func fetchBriefing() async throws -> [NewsStory] {
        try await Task.sleep(for: .milliseconds(350))
        let now = Date.now
        return [
            NewsStory(
                id: "demo-energy-transition",
                section: "ENERGY",
                headline: "The grid is becoming the center of the energy transition",
                summary: "Electricity demand is rising as transport, buildings, and industry electrify. The bottleneck is increasingly the speed at which new generation, storage, and transmission can connect to the grid.",
                whyItMatters: "The next phase of clean energy depends as much on infrastructure and permitting as it does on cheaper technology.",
                sourceName: "Demo briefing",
                sourceURL: URL(string: "https://example.com/energy")!,
                publishedAt: now,
                readTimeMinutes: 2
            ),
            NewsStory(
                id: "demo-world-trade",
                section: "WORLD",
                headline: "Trade policy is reshaping where companies build",
                summary: "Governments are using tariffs, subsidies, and procurement rules to pull strategic manufacturing closer to home. Companies are responding with more regional and redundant supply chains.",
                whyItMatters: "Resilience can reduce disruption, but duplicated capacity may also raise costs for consumers and businesses.",
                sourceName: "Demo briefing",
                sourceURL: URL(string: "https://example.com/world")!,
                publishedAt: now,
                readTimeMinutes: 2
            ),
            NewsStory(
                id: "demo-tech-agents",
                section: "TECHNOLOGY",
                headline: "AI products are moving from answers toward actions",
                summary: "Software teams are designing agents that can complete multi-step work across tools. Reliability, permissions, and clear human oversight remain the central product challenges.",
                whyItMatters: "The largest impact may come from redesigning workflows, rather than placing a chatbot beside an existing process.",
                sourceName: "Demo briefing",
                sourceURL: URL(string: "https://example.com/technology")!,
                publishedAt: now,
                readTimeMinutes: 2
            ),
            NewsStory(
                id: "demo-science-climate",
                section: "SCIENCE",
                headline: "Better forecasts are changing how communities prepare",
                summary: "New observing systems and faster models are improving short-term predictions for extreme weather. The harder step is turning an earlier warning into action people can take.",
                whyItMatters: "Forecasting only saves lives when alerts are clear, trusted, and connected to practical local plans.",
                sourceName: "Demo briefing",
                sourceURL: URL(string: "https://example.com/science")!,
                publishedAt: now,
                readTimeMinutes: 2
            )
        ]
    }
}

struct RemoteNewsService: NewsServing {
    let baseURL: URL
    let topics: Set<NewsTopic>
    let storyCount: Int
    let accessToken: String

    func fetchBriefing() async throws -> [NewsStory] {
        var components = URLComponents(url: baseURL.appending(path: "v1/briefing"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "topics", value: topics.map(\.rawValue).sorted().joined(separator: ",")),
            URLQueryItem(name: "count", value: String(storyCount))
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadRevalidatingCacheData
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { container in
            let value = try container.singleValueContainer().decode(String.self)
            if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value) {
                return date
            }
            if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: try container.singleValueContainer(),
                debugDescription: "Invalid ISO 8601 date: \(value)"
            )
        }
        return try decoder.decode(BriefingResponse.self, from: data).stories
    }
}

