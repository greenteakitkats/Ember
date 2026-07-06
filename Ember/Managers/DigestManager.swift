import Foundation
import SwiftData
import UserNotifications

/// Schedules the daily digest: one local notification per morning, only
/// on mornings where someone is actually drifting or a birthday is near.
/// Content is projected per-day (health states move as time passes), and
/// the whole schedule is rebuilt whenever the app goes to background so
/// it always reflects the latest interactions. Nothing fires when
/// everyone's in touch — silence is the reward, not a missed ping.
@MainActor
final class DigestManager {
    static let shared = DigestManager()

    static let enabledKey = "digestEnabled"
    static let hourKey = "digestHour"
    static let minuteKey = "digestMinute"

    private let daysAhead = 7

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    var fireHour: Int {
        UserDefaults.standard.object(forKey: Self.hourKey) as? Int ?? 9
    }

    var fireMinute: Int {
        UserDefaults.standard.object(forKey: Self.minuteKey) as? Int ?? 0
    }

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    func reschedule(container: ModelContainer) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: (0..<daysAhead).map { "digest-\($0)" }
        )
        guard isEnabled else { return }

        let people = (try? container.mainContext.fetch(FetchDescriptor<Person>())) ?? []
        guard !people.isEmpty else { return }

        let calendar = Calendar.current
        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now),
                  let fireDate = calendar.date(
                    bySettingHour: fireHour, minute: fireMinute, second: 0, of: day
                  ),
                  fireDate > .now,
                  let content = digestContent(people: people, on: fireDate)
            else { continue }

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let request = UNNotificationRequest(
                identifier: "digest-\(offset)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            center.add(request)
        }
    }

    /// nil when that morning has nothing worth saying.
    private func digestContent(people: [Person], on date: Date) -> UNMutableNotificationContent? {
        let due = people
            .filter {
                let state = $0.healthState(at: date)
                return state == .overdue || state == .drifting
            }
            .sorted { ($0.overdueRatio(at: date) ?? 0) > ($1.overdueRatio(at: date) ?? 0) }

        let birthdayLine = upcomingBirthdayLine(people: people, on: date)
        guard !due.isEmpty || birthdayLine != nil else { return nil }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if !due.isEmpty {
            content.title = due.count == 1
                ? "1 person would love to hear from you"
                : "\(due.count) people would love to hear from you"
            let names = due.prefix(2).map(firstName)
            var body = names.count == 1
                ? "It's been a while since you talked to \(names[0])."
                : "It's been a while since you talked to \(names[0]) and \(names[1])."
            if let birthdayLine {
                body += " \(birthdayLine)"
            }
            content.body = body
        } else if let birthdayLine {
            content.title = "A birthday is coming up"
            content.body = birthdayLine
        }
        return content
    }

    private func upcomingBirthdayLine(people: [Person], on date: Date) -> String? {
        let soon = people
            .filter { !$0.isPaused }
            .compactMap { person -> (name: String, days: Int)? in
                guard let days = person.daysUntilNextBirthday(from: date), days <= 3 else {
                    return nil
                }
                return (firstName(person), days)
            }
            .min { $0.days < $1.days }
        guard let soon else { return nil }
        switch soon.days {
        case 0: return "\(soon.name)'s birthday is today!"
        case 1: return "\(soon.name)'s birthday is tomorrow."
        default: return "\(soon.name)'s birthday is in \(soon.days) days."
        }
    }

    private func firstName(_ person: Person) -> String {
        person.name.split(separator: " ").first.map(String.init) ?? person.name
    }

    #if DEBUG
    /// Prints the next week of digest content without touching the
    /// notification center, so scheduling logic is testable in the
    /// simulator where permission prompts can't be tapped.
    func debugDump(container: ModelContainer) {
        let people = (try? container.mainContext.fetch(FetchDescriptor<Person>())) ?? []
        let calendar = Calendar.current
        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now),
                  let fireDate = calendar.date(
                    bySettingHour: fireHour, minute: fireMinute, second: 0, of: day
                  ) else { continue }
            if let content = digestContent(people: people, on: fireDate) {
                print("DIGEST day+\(offset): \(content.title) | \(content.body)")
            } else {
                print("DIGEST day+\(offset): (quiet)")
            }
        }
    }
    #endif
}
