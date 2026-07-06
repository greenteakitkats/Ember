#if DEBUG
import Foundation
import SwiftData

/// Launch-argument hooks for simulator screenshots and manual testing:
///   xcrun simctl launch <device> ryantdo.Weave -demoData
///   -demoData        wipes the store and seeds a sample network
///   -openFirstPerson navigates to the most overdue person on launch
///   -showManualAdd   presents the manual add sheet on launch
enum DemoData {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-demoData")
    }

    static var shouldOpenFirstPerson: Bool {
        ProcessInfo.processInfo.arguments.contains("-openFirstPerson")
    }

    static var shouldShowManualAdd: Bool {
        ProcessInfo.processInfo.arguments.contains("-showManualAdd")
    }

    static var shouldSimulateOutreach: Bool {
        ProcessInfo.processInfo.arguments.contains("-simulateOutreach")
    }

    static var shouldShowCaptureSheet: Bool {
        ProcessInfo.processInfo.arguments.contains("-showCaptureSheet")
    }

    static var shouldShowLogSheet: Bool {
        ProcessInfo.processInfo.arguments.contains("-showLogSheet")
    }

    static func seed(into context: ModelContext) {
        try? context.delete(model: Interaction.self)
        try? context.delete(model: Person.self)

        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        }

        @discardableResult
        func person(
            _ name: String,
            cadence: Cadence,
            phone: String? = nil,
            email: String? = nil,
            notes: String = "",
            birthday: Date? = nil,
            paused: Bool = false
        ) -> Person {
            let p = Person(name: name)
            p.cadence = cadence
            p.phoneNumber = phone
            p.email = email
            p.notes = notes
            p.birthday = birthday
            p.isPaused = paused
            context.insert(p)
            return p
        }

        func log(
            _ p: Person,
            _ type: InteractionType,
            daysAgo days: Int,
            source: InteractionSource = .manual,
            note: String = ""
        ) {
            let interaction = Interaction(date: daysAgo(days), type: type, source: source, note: note)
            context.insert(interaction)
            interaction.person = p
        }

        let kenji = person(
            "Kenji Watanabe",
            cadence: .quarterly,
            phone: "+81 90 1234 5678",
            email: "kenji@example.com",
            notes: "Moved to Osaka in the spring. Ask how the new apartment and the ramen hunt are going.",
            birthday: calendar.date(from: DateComponents(year: 1994, month: 11, day: 8))
        )
        kenji.phoneNumbers = ["+81 90 1234 5678", "+1 (555) 010-4455"]
        kenji.emails = ["kenji@example.com"]
        kenji.askAboutNext = "How the apartment hunt ended"
        log(kenji, .call, daysAgo: 200, note: "Caught up about his move")
        log(kenji, .inPerson, daysAgo: 320, note: "Dinner in Umeda before I flew home")

        let dan = person("Dan Tran", cadence: .monthly, phone: "+1 (555) 010-2233")
        log(dan, .message, daysAgo: 45, source: .outreach)

        let sarah = person("Sarah Kim", cadence: .monthly, phone: "+1 (555) 010-3344")
        log(sarah, .message, daysAgo: 27)

        let priya = person("Priya Sharma", cadence: .quarterly, email: "priya@example.com")
        log(priya, .email, daysAgo: 80, source: .outreach)

        let mom = person(
            "Mom",
            cadence: .weekly,
            phone: "+1 (555) 010-0001",
            birthday: calendar.date(from: DateComponents(year: 1962, month: 7, day: 21))
        )
        log(mom, .call, daysAgo: 2, source: .outreach)

        let alex = person("Alex Rivera", cadence: .twiceAYear, phone: "+1 (555) 010-5566")
        log(alex, .inPerson, daysAgo: 60, note: "Grabbed coffee while he was in town")

        person("Jordan Lee", cadence: .monthly, phone: "+1 (555) 010-7788")

        person("Chris Okafor", cadence: .quarterly, paused: true)
    }
}
#endif
