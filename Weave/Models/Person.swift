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
    var overdueRatio: Double? {
        guard let last = lastContactDate else { return nil }
        let daysSince = Date.now.timeIntervalSince(last) / 86_400
        return max(daysSince, 0) / Double(cadence.days)
    }

    var healthState: HealthState {
        if isPaused { return .paused }
        guard let ratio = overdueRatio else { return .unranked }
        if ratio < 0.8 { return .onTrack }
        if ratio <= 1.2 { return .drifting }
        return .overdue
    }

    /// Days past the cadence deadline. Negative means not due yet.
    var daysPastCadence: Int? {
        guard let last = lastContactDate else { return nil }
        let daysSince = Int(Date.now.timeIntervalSince(last) / 86_400)
        return daysSince - cadence.days
    }

    /// Compact "how late" label for list rows, e.g. "3mo over" or "due soon".
    /// nil when the state itself (on track, new, paused) says everything.
    var overdueLabel: String? {
        guard healthState == .overdue || healthState == .drifting,
              let over = daysPastCadence else { return nil }
        if over <= 0 { return "due soon" }
        if over < 14 { return "\(over)d over" }
        if over < 60 { return "\(over / 7)w over" }
        return "\(over / 30)mo over"
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
        case .overdue: "Overdue"
        case .drifting: "Drifting"
        case .onTrack: "On track"
        case .unranked: "New"
        case .paused: "Paused"
        }
    }

    var color: Color {
        switch self {
        case .overdue: .red
        case .drifting: .orange
        case .onTrack: .green
        case .unranked: .blue
        case .paused: .gray
        }
    }

    /// Healthy/inactive sections start collapsed so overdue people
    /// never scroll off screen.
    var collapsedByDefault: Bool {
        self == .onTrack || self == .paused
    }
}
