import Contacts
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var people: [Person]

    @State private var showingContactPicker = false
    @State private var showingManualAdd = false
    @State private var path = NavigationPath()
    @State private var searchText = ""
    @State private var expandedSections: Set<HealthState> = []

    private var filteredPeople: [Person] {
        guard !searchText.isEmpty else { return Array(people) }
        return people.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var sections: [(state: HealthState, members: [Person])] {
        let grouped = Dictionary(grouping: filteredPeople, by: \.healthState)
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
                            Section {
                                if isExpanded(section.state) {
                                    ForEach(section.members) { person in
                                        NavigationLink(value: person) {
                                            PersonRow(person: person)
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                quickLog(person)
                                            } label: {
                                                Label("Talked", systemImage: "checkmark.bubble.fill")
                                            }
                                            .tint(.green)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button {
                                                person.isPaused.toggle()
                                            } label: {
                                                if person.isPaused {
                                                    Label("Resume", systemImage: "play.fill")
                                                } else {
                                                    Label("Pause", systemImage: "pause.fill")
                                                }
                                            }
                                            .tint(.indigo)
                                        }
                                    }
                                }
                            } header: {
                                sectionHeader(for: section.state, count: section.members.count)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search people")
                    .refreshable {
                        ContactsManager.shared.refresh(people)
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

    // MARK: - Sections

    private func isExpanded(_ state: HealthState) -> Bool {
        !state.collapsedByDefault || expandedSections.contains(state) || !searchText.isEmpty
    }

    @ViewBuilder
    private func sectionHeader(for state: HealthState, count: Int) -> some View {
        if state.collapsedByDefault && searchText.isEmpty {
            Button {
                withAnimation {
                    if expandedSections.contains(state) {
                        expandedSections.remove(state)
                    } else {
                        expandedSections.insert(state)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text("\(state.label) · \(count)")
                    Image(systemName: isExpanded(state) ? "chevron.down" : "chevron.forward")
                        .font(.caption2.weight(.semibold))
                }
            }
        } else {
            Text("\(state.label) · \(count)")
        }
    }

    // MARK: - Actions

    private func quickLog(_ person: Person) {
        let interaction = Interaction(type: .other, source: .manual)
        modelContext.insert(interaction)
        interaction.person = person
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
            if let label = person.overdueLabel {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(person.healthState.color)
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        if person.isPaused { return "Paused" }
        guard let last = person.lastContactDate else {
            return "No history yet · \(person.cadence.shortLabel)"
        }
        let ago = last.formatted(.relative(presentation: .named))
        return "\(ago) · \(person.cadence.shortLabel)"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Person.self, Interaction.self], inMemory: true)
}
