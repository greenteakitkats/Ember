import Foundation
import SwiftData
import SwiftUI

// All stored properties have defaults and relationships are optional so the
// schema stays CloudKit-compatible for a future sync release.
@Model
final class Person {
    var name: String = ""
    var contactIdentifier: String?
    var photoData: Data?
    // The number/email used for outreach. When the linked contact has
    // several, the user picks one; the full lists live in the arrays below.
    var phoneNumber: String?
    var email: String?
    var phoneNumbers: [String] = []
    var emails: [String] = []
    var birthday: Date?
    var cadenceRaw: String = Cadence.monthly.rawValue
    var notes: String = ""
    // One-line reminder surfaced before outreach; cleared once asked.
    var askAboutNext: String?
    // Hobbies, favorite things, the little stuff that makes people
    // feel noticed ("Ramen, A24 films, her cat Mochi").
    var loves: String = ""
    var isPaused: Bool = false
    var contactLinkBroken: Bool = false
    // Onboarding seed for people whose real history predates the app.
    var estimatedLastContact: Date?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Interaction.person)
    var interactions: [Interaction]? = []

    init(name: String, contactIdentifier: String? = nil) {
        self.name = name
        self.contactIdentifier = contactIdentifier
    }

    var cadence: Cadence {
        get { Cadence(rawValue: cadenceRaw) ?? .monthly }
        set { cadenceRaw = newValue.rawValue }
    }

    var sortedInteractions: [Interaction] {
        (interactions ?? []).sorted { $0.date > $1.date }
    }

    var lastContactDate: Date? {
        let logged = (interactions ?? []).map(\.date).max()
        return [logged, estimatedLastContact].compactMap { $0 }.max()
    }

    /// Days since last contact divided by the cadence length.
    /// 1.0 means exactly at cadence; nil means no history to rank by.
    /// Parameterized on the reference date so the daily digest can
    /// project health into future mornings when scheduling ahead.
    func overdueRatio(at date: Date) -> Double? {
        guard let last = lastContactDate else { return nil }
        let daysSince = date.timeIntervalSince(last) / 86_400
        return max(daysSince, 0) / Double(cadence.days)
    }

    var overdueRatio: Double? {
        overdueRatio(at: .now)
    }

    func healthState(at date: Date) -> HealthState {
        if isPaused { return .paused }
        guard let ratio = overdueRatio(at: date) else { return .unranked }
        if ratio < 0.8 { return .onTrack }
        if ratio <= 1.2 { return .drifting }
        return .overdue
    }

    var healthState: HealthState {
        healthState(at: .now)
    }

    /// Days past the cadence deadline. Negative means not due yet.
    var daysPastCadence: Int? {
        guard let last = lastContactDate else { return nil }
        let daysSince = Int(Date.now.timeIntervalSince(last) / 86_400)
        return daysSince - cadence.days
    }

    /// Compact "how quiet" label for list rows, e.g. "quiet 3mo".
    /// nil when the state itself (in touch, new, resting) says everything.
    var overdueLabel: String? {
        guard healthState == .overdue || healthState == .drifting,
              let over = daysPastCadence else { return nil }
        if over <= 0 { return "check in soon" }
        if over < 14 { return "quiet \(over)d" }
        if over < 60 { return "quiet \(over / 7)w" }
        return "quiet \(over / 30)mo"
    }

    /// How full the relationship "battery" is: 1 right after contact,
    /// draining toward the cadence deadline. Never fully empty — an
    /// overdue person keeps a small ember, not a guilt-void.
    var ringFraction: Double {
        if isPaused { return 0 }
        guard let ratio = overdueRatio else { return 1 }
        return max(0.08, 1 - ratio)
    }

    func daysUntilNextBirthday(from referenceDate: Date) -> Int? {
        guard let birthday else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthday)
        let today = calendar.startOfDay(for: referenceDate)
        let todayComponents = calendar.dateComponents([.month, .day], from: today)
        if todayComponents.month == components.month && todayComponents.day == components.day {
            return 0
        }
        guard let next = calendar.nextDate(
            after: today,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) else { return nil }
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next)).day
    }

    var daysUntilNextBirthday: Int? {
        daysUntilNextBirthday(from: .now)
    }

    /// Most recent interaction of a given type — powers "last seen in
    /// person" and "last gift" without the user maintaining anything.
    func lastDate(of type: InteractionType) -> Date? {
        (interactions ?? [])
            .filter { $0.type == type }
            .map(\.date)
            .max()
    }

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

enum Cadence: String, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case monthly
    case quarterly
    case twiceAYear
    case yearly

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .weekly: 7
        case .biweekly: 14
        case .monthly: 30
        case .quarterly: 91
        case .twiceAYear: 182
        case .yearly: 365
        }
    }

    var label: String {
        switch self {
        case .weekly: "Weekly"
        case .biweekly: "Every 2 weeks"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .twiceAYear: "Twice a year"
        case .yearly: "Yearly"
        }
    }

    /// Fits on one list-row line next to "Last talked … ·".
    var shortLabel: String {
        switch self {
        case .weekly: "weekly"
        case .biweekly: "2×/month"
        case .monthly: "monthly"
        case .quarterly: "quarterly"
        case .twiceAYear: "2×/year"
        case .yearly: "yearly"
        }
    }
}

enum HealthState: Int, CaseIterable, Identifiable {
    case overdue
    case drifting
    case onTrack
    case unranked
    case paused

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .overdue: "Been too long"
        case .drifting: "Drifting"
        case .onTrack: "In touch"
        case .unranked: "Just added"
        case .paused: "Resting"
        }
    }

    var color: Color {
        switch self {
        case .overdue: Color(light: 0xC94E2C, dark: 0xE8724E)
        case .drifting: Color(light: 0xB07514, dark: 0xE0A33B)
        case .onTrack: Color(light: 0x6B7F4A, dark: 0x9BB472)
        case .unranked: Color(light: 0x8A7A6D, dark: 0xAA9B8D)
        case .paused: Color(light: 0x9A918A, dark: 0x847C74)
        }
    }

    /// Healthy/inactive sections start collapsed so overdue people
    /// never scroll off screen.
    var collapsedByDefault: Bool {
        self == .onTrack || self == .paused
    }
}
