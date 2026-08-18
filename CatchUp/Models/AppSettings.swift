import Foundation

enum NewsTopic: String, CaseIterable, Codable, Identifiable, Sendable {
    case world = "World"
    case energy = "Energy"
    case technology = "Technology"
    case business = "Business"
    case science = "Science"

    var id: String { rawValue }
}

struct AppSettings: Codable, Sendable {
    var selectedTopics: Set<NewsTopic> = [.world, .energy, .technology]
    var dailyStoryCount = 3
    var backendURL = ""
    var onboardingCompleted = false
    var shieldingEnabled = false
}


