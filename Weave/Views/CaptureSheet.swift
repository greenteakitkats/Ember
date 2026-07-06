import SwiftData
import SwiftUI

/// The 30-second habit: right after an interaction, capture what's going
/// on in their life while it's fresh. Edits bind straight to the person,
/// so there's nothing to lose by dismissing.
struct CaptureSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var person: Person

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "What's going on in their life…",
                        text: $person.notes,
                        axis: .vertical
                    )
                    .lineLimit(4...10)
                } header: {
                    Text("What's new with \(firstName)?")
                } footer: {
                    Text("You'll see this at the top of their card next time, before you reach out.")
                }
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.bubble")
                            .foregroundStyle(.secondary)
                        TextField("Next time, ask about…", text: askAboutBinding)
                    }
                }
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var firstName: String {
        person.name.split(separator: " ").first.map(String.init) ?? person.name
    }

    private var askAboutBinding: Binding<String> {
        Binding(
            get: { person.askAboutNext ?? "" },
            set: { person.askAboutNext = $0.isEmpty ? nil : $0 }
        )
    }
}
