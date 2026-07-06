import SwiftData
import SwiftUI

struct LogInteractionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let person: Person

    @State private var type: InteractionType = .inPerson
    @State private var date: Date = .now
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(InteractionType.allCases) { type in
                            Label(type.label, systemImage: type.icon).tag(type)
                        }
                    }
                    DatePicker(
                        "When",
                        selection: $date,
                        in: ...Date.now,
                        displayedComponents: [.date]
                    )
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Log Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let interaction = Interaction(
                            date: date,
                            type: type,
                            source: .manual,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(interaction)
                        interaction.person = person
                        Haptics.logged()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
