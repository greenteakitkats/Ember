import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @Bindable var person: Person

    @State private var showingLogSheet = false
    @State private var showingCaptureSheet = false
    @State private var showingDeleteConfirm = false
    @State private var undoableInteraction: Interaction?
    @State private var undoDismissTask: Task<Void, Never>?

    var body: some View {
        List {
            headerSection
                .listRowBackground(Theme.card)
            recallSection
                .listRowBackground(Theme.card)
            outreachSection
            if person.lastContactDate == nil && !person.isPaused {
                seedSection
                    .listRowBackground(Theme.card)
            }
            if person.phoneNumber != nil || person.email != nil {
                contactSection
                    .listRowBackground(Theme.card)
            }
            settingsSection
                .listRowBackground(Theme.card)
            historySection
                .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Remove from Ember", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Remove \(person.name) from Ember? Their interaction history will be deleted. Your iOS contact is not affected.",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                modelContext.delete(person)
                dismiss()
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogInteractionSheet(person: person)
        }
        .sheet(isPresented: $showingCaptureSheet) {
            CaptureSheet(person: person)
        }
        .task {
            #if DEBUG
            if DemoData.shouldSimulateOutreach && undoableInteraction == nil {
                let interaction = Interaction(type: .call, source: .outreach)
                modelContext.insert(interaction)
                interaction.person = person
                showUndo(for: interaction)
            }
            if DemoData.shouldShowCaptureSheet { showingCaptureSheet = true }
            if DemoData.shouldShowLogSheet { showingLogSheet = true }
            #endif
        }
        .safeAreaInset(edge: .bottom) {
            if let interaction = undoableInteraction {
                undoBanner(for: interaction)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                AvatarView(person: person, size: 60)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(person.healthState.color)
                            .frame(width: 9, height: 9)
                        Text(person.healthState.label)
                            .font(.subheadline.weight(.medium))
                    }
                    Text(lastTalkedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let birthdayText {
                        Text(birthdayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if person.contactLinkBroken {
                Label("This person's contact card was deleted from iOS Contacts. Ember kept its copy.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var outreachSection: some View {
        Section {
            HStack(spacing: 10) {
                outreachButton(.call, enabled: phoneDigits != nil)
                outreachButton(.facetime, enabled: phoneDigits != nil || person.email != nil)
                outreachButton(.message, enabled: phoneDigits != nil)
                outreachButton(.email, enabled: person.email != nil)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } footer: {
            Text("Reaching out from here logs the interaction automatically.")
        }
    }

    private var seedSection: some View {
        Section("When did you last talk?") {
            ForEach(SeedOption.allCases) { option in
                Button(option.label) {
                    person.estimatedLastContact = option.date
                }
            }
        }
    }

    private var contactSection: some View {
        Section {
            if person.phoneNumbers.count > 1 {
                Picker("Phone", selection: $person.phoneNumber) {
                    ForEach(person.phoneNumbers, id: \.self) { number in
                        Text(number).tag(Optional(number))
                    }
                }
                .tint(Color.accentColor)
            } else if let phone = person.phoneNumber {
                LabeledContent("Phone", value: phone)
            }
            if person.emails.count > 1 {
                Picker("Email", selection: $person.email) {
                    ForEach(person.emails, id: \.self) { email in
                        Text(email).tag(Optional(email))
                    }
                }
                .tint(Color.accentColor)
            } else if let email = person.email {
                LabeledContent("Email", value: email)
            }
        } header: {
            Text("Contact")
        } footer: {
            if person.phoneNumbers.count > 1 || person.emails.count > 1 {
                Text("The selected number and email are what the buttons above use.")
            }
        }
    }

    private var settingsSection: some View {
        Section {
            Picker("Cadence", selection: $person.cadence) {
                ForEach(Cadence.allCases) { cadence in
                    Text(cadence.label).tag(cadence)
                }
            }
            .tint(Color.accentColor)
            Toggle("Resting", isOn: $person.isPaused)
        } footer: {
            Text("Resting people sit out of health tracking without losing their history. For travel, rough patches, or just needing space.")
        }
    }

    private var recallSection: some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble")
                    .foregroundStyle(.secondary)
                TextField("Next time, ask about…", text: askAboutBinding)
                if person.askAboutNext != nil {
                    Button {
                        withAnimation { person.askAboutNext = nil }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Asked, clear it")
                }
            }
            TextField(
                "What's going on in their life…",
                text: $person.notes,
                axis: .vertical
            )
            .lineLimit(2...8)
            HStack(spacing: 8) {
                Image(systemName: "heart")
                    .foregroundStyle(.secondary)
                TextField("Things they love…", text: $person.loves)
            }
        } header: {
            Text("Before you reach out")
        } footer: {
            if let littleThings {
                Text(littleThings)
            }
        }
    }

    private var littleThings: String? {
        var parts: [String] = []
        if let met = person.lastDate(of: .inPerson) {
            parts.append("Seen in person \(met.formatted(.relative(presentation: .named)))")
        }
        if let gift = person.lastDate(of: .gift) {
            parts.append("last gift \(gift.formatted(.relative(presentation: .named)))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var askAboutBinding: Binding<String> {
        Binding(
            get: { person.askAboutNext ?? "" },
            set: { person.askAboutNext = $0.isEmpty ? nil : $0 }
        )
    }

    private var historySection: some View {
        Section("History") {
            Button("Log an Interaction", systemImage: "plus.circle.fill") {
                showingLogSheet = true
            }
            ForEach(person.sortedInteractions) { interaction in
                InteractionRow(interaction: interaction)
            }
            .onDelete { offsets in
                let sorted = person.sortedInteractions
                for index in offsets {
                    modelContext.delete(sorted[index])
                }
            }
        }
    }

    // MARK: - Outreach

    private func outreachButton(_ type: InteractionType, enabled: Bool) -> some View {
        Button {
            startOutreach(type)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                Text(type.label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .disabled(!enabled)
    }

    private var phoneDigits: String? {
        guard let phone = person.phoneNumber else { return nil }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : digits
    }

    private func outreachURL(for type: InteractionType) -> URL? {
        switch type {
        case .call:
            guard let digits = phoneDigits else { return nil }
            return URL(string: "tel:\(digits)")
        case .facetime:
            // FaceTime reaches people by number or by Apple ID email.
            guard let target = phoneDigits ?? person.email else { return nil }
            return URL(string: "facetime:\(target)")
        case .message:
            guard let digits = phoneDigits else { return nil }
            return URL(string: "sms:\(digits)")
        case .email:
            guard let email = person.email else { return nil }
            return URL(string: "mailto:\(email)")
        default:
            return nil
        }
    }

    private func startOutreach(_ type: InteractionType) {
        guard let url = outreachURL(for: type) else { return }
        openURL(url) { accepted in
            guard accepted else { return }
            let interaction = Interaction(type: type, source: .outreach)
            modelContext.insert(interaction)
            interaction.person = person
            Haptics.logged()
            showUndo(for: interaction)
        }
    }

    private func showUndo(for interaction: Interaction) {
        undoDismissTask?.cancel()
        undoableInteraction = interaction
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled {
                undoableInteraction = nil
            }
        }
    }

    private func undoBanner(for interaction: Interaction) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.bounce, value: undoableInteraction)
                Text("\(interaction.type.label) logged")
                    .font(.subheadline)
            }
            Spacer()
            Button("Add note") {
                undoDismissTask?.cancel()
                undoableInteraction = nil
                showingCaptureSheet = true
            }
            .font(.subheadline.weight(.semibold))
            Button("Undo") {
                modelContext.delete(interaction)
                undoDismissTask?.cancel()
                undoableInteraction = nil
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var lastTalkedText: String {
        guard let last = person.lastContactDate else { return "No history yet" }
        return "Last talked \(last.formatted(.relative(presentation: .named)))"
    }

    private var birthdayText: String? {
        guard let birthday = person.birthday else { return nil }
        let calendar = Calendar.current
        let dateText = birthday.formatted(.dateTime.month(.wide).day())

        let components = calendar.dateComponents([.month, .day], from: birthday)
        let today = calendar.dateComponents([.month, .day], from: .now)
        if today.month == components.month && today.day == components.day {
            return "Birthday \(dateText) · today 🎂"
        }
        guard let next = calendar.nextDate(
            after: calendar.startOfDay(for: .now),
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) else { return "Birthday \(dateText)" }

        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: next)
        ).day ?? 0

        let countdown: String
        switch days {
        case 0: countdown = "today 🎂"
        case 1: countdown = "tomorrow"
        case ..<45: countdown = "in \(days) days"
        default: countdown = "in \(Int((Double(days) / 30.4).rounded())) months"
        }
        return "Birthday \(dateText) · \(countdown)"
    }
}

private struct InteractionRow: View {
    let interaction: Interaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: interaction.type.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(interaction.type.label)
                    Spacer()
                    Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !interaction.note.isEmpty {
                    Text(interaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if interaction.source != .manual {
                    Text(interaction.source.label)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

private enum SeedOption: String, CaseIterable, Identifiable {
    case thisWeek
    case thisMonth
    case fewMonths
    case overAYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thisWeek: "This week"
        case .thisMonth: "This month"
        case .fewMonths: "A few months ago"
        case .overAYear: "Over a year ago"
        }
    }

    var date: Date {
        let daysAgo: Int
        switch self {
        case .thisWeek: daysAgo = 3
        case .thisMonth: daysAgo = 15
        case .fewMonths: daysAgo = 90
        case .overAYear: daysAgo = 400
        }
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
    }
}
