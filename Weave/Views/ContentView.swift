import Contacts
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]

    @State private var showingContactPicker = false
    @State private var showingManualAdd = false
    @State private var path = NavigationPath()

    private var sections: [(state: HealthState, members: [Person])] {
        let grouped = Dictionary(grouping: people, by: \.healthState)
        return HealthState.allCases.compactMap { state in
            guard var members = grouped[state], !members.isEmpty else { return nil }
            switch state {
            case .unranked, .paused:
                members.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            default:
                members.sort { ($0.overdueRatio ?? 0) > ($1.overdueRatio ?? 0) }
            }
            return (state, members)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if people.isEmpty {
                    ContentUnavailableView {
                        Label("No one here yet", systemImage: "person.2")
                    } description: {
                        Text("Add the people you want to stay close to. Weave keeps track of who's drifting.")
                    } actions: {
                        Button("Add from Contacts") { addFromContacts() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(sections, id: \.state) { section in
                            Section(section.state.label) {
                                ForEach(section.members) { person in
                                    NavigationLink(value: person) {
                                        PersonRow(person: person)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(person: person)
            }
            .navigationTitle("Weave")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("From Contacts", systemImage: "person.crop.circle.badge.plus") {
                            addFromContacts()
                        }
                        Button("Add Manually", systemImage: "plus") {
                            showingManualAdd = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView { contacts in
                    importContacts(contacts)
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showingManualAdd) {
                AddManualPersonSheet()
            }
            .task {
                #if DEBUG
                if DemoData.isRequested {
                    DemoData.seed(into: modelContext)
                }
                if DemoData.shouldShowManualAdd {
                    showingManualAdd = true
                }
                if DemoData.shouldOpenFirstPerson {
                    let everyone = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
                    if let target = everyone.max(by: { ($0.overdueRatio ?? -1) < ($1.overdueRatio ?? -1) }) {
                        path.append(target)
                    }
                }
                #endif
                ContactsManager.shared.refresh(people)
            }
        }
    }

    private func addFromContacts() {
        Task {
            // Ask in context; the picker itself works either way, but sync
            // of names/photos/birthdays needs real access.
            _ = await ContactsManager.shared.requestAccess()
            showingContactPicker = true
        }
    }

    private func importContacts(_ contacts: [CNContact]) {
        let existing = Set(people.compactMap(\.contactIdentifier))
        for contact in contacts where !existing.contains(contact.identifier) {
            let person = Person(name: "", contactIdentifier: contact.identifier)
            ContactsManager.shared.apply(contact, to: person)
            guard !person.name.isEmpty else { continue }
            modelContext.insert(person)
        }
    }
}

private struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(person: person)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(person.healthState.color)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        if person.isPaused { return "Paused" }
        guard let last = person.lastContactDate else {
            return "No history yet · \(person.cadence.label.lowercased())"
        }
        let ago = last.formatted(.relative(presentation: .named))
        return "Last talked \(ago) · \(person.cadence.label.lowercased())"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Person.self, Interaction.self], inMemory: true)
}
