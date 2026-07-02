import Contacts
import Foundation

/// Reads linked people from the system contact store and keeps their
/// cached fields (name, photo, phone, email, birthday) fresh.
final class ContactsManager {
    static let shared = ContactsManager()
    private let store = CNContactStore()

    private init() {}

    static var fetchKeys: [CNKeyDescriptor] {
        [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
        ]
    }

    var isAuthorized: Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return status == .authorized || status == .limited
    }

    func requestAccess() async -> Bool {
        if isAuthorized { return true }
        return (try? await store.requestAccess(for: .contacts)) ?? false
    }

    /// Copies the fields Weave caches from a system contact onto a Person.
    func apply(_ contact: CNContact, to person: Person) {
        person.contactIdentifier = contact.identifier
        person.contactLinkBroken = false

        let name = CNContactFormatter.string(from: contact, style: .fullName)
        if let name, !name.isEmpty {
            person.name = name
        }
        person.photoData = contact.thumbnailImageData
        person.phoneNumber = contact.phoneNumbers.first?.value.stringValue
        person.email = contact.emailAddresses.first?.value as String?
        if let birthday = contact.birthday, birthday.month != nil, birthday.day != nil {
            person.birthday = Calendar.current.date(from: birthday)
        }
    }

    /// Refreshes every linked person from the contact store, flagging
    /// people whose system contact no longer exists.
    func refresh(_ people: [Person]) {
        guard isAuthorized else { return }
        for person in people {
            guard let identifier = person.contactIdentifier else { continue }
            do {
                let contact = try store.unifiedContact(
                    withIdentifier: identifier,
                    keysToFetch: Self.fetchKeys
                )
                apply(contact, to: person)
            } catch {
                // Contact was deleted or is unavailable; keep Weave's copy.
                person.contactLinkBroken = true
            }
        }
    }
}
