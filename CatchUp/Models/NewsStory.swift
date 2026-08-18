import Foundation

struct NewsStory: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let section: String
    let headline: String
    let summary: String
    let whyItMatters: String
    let sourceName: String
    let sourceURL: URL
    let publishedAt: Date
    let readTimeMinutes: Int
}

struct BriefingResponse: Codable, Sendable {
    let stories: [NewsStory]
}


