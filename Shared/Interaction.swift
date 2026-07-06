import Foundation
import SwiftData

@Model
final class Interaction {
    var date: Date = Date.now
    var typeRaw: String = InteractionType.call.rawValue
    var sourceRaw: String = InteractionSource.manual.rawValue
    var note: String = ""
    var person: Person?

    init(date: Date = .now, type: InteractionType, source: InteractionSource = .manual, note: String = "") {
        self.date = date
        self.typeRaw = type.rawValue
        self.sourceRaw = source.rawValue
        self.note = note
    }

    var type: InteractionType {
        get { InteractionType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var source: InteractionSource {
        get { InteractionSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

enum InteractionType: String, CaseIterable, Identifiable {
    case call
    case facetime
    case message
    case email
    case inPerson
    case gift
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .call: "Call"
        case .facetime: "FaceTime"
        case .message: "Message"
        case .email: "Email"
        case .inPerson: "In person"
        case .gift: "Gift"
        case .other: "Catch-up"
        }
    }

    var icon: String {
        switch self {
        case .call: "phone.fill"
        case .facetime: "video.fill"
        case .message: "message.fill"
        case .email: "envelope.fill"
        case .inPerson: "person.2.fill"
        case .gift: "gift.fill"
        case .other: "bubble.left.and.bubble.right.fill"
        }
    }
}

enum InteractionSource: String {
    case manual
    case outreach   // logged automatically because outreach started from Ember
    case calendar   // future: confirmed from a calendar match

    var label: String {
        switch self {
        case .manual: "Logged manually"
        case .outreach: "Started from Ember"
        case .calendar: "From calendar"
        }
    }
}
