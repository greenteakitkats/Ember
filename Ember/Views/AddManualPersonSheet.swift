import SwiftData
import SwiftUI

/// For people who aren't in the address book (or shouldn't be).
struct AddManualPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var cadence: Cadence = .monthly

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Phone (optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Picker("Cadence", selection: $cadence) {
                        ForEach(Cadence.allCases) { cadence in
                            Text(cadence.label).tag(cadence)
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let person = Person(name: trimmedName)
                        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
                        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                        person.phoneNumber = trimmedPhone.isEmpty ? nil : trimmedPhone
                        person.email = trimmedEmail.isEmpty ? nil : trimmedEmail
                        person.cadence = cadence
                        modelContext.insert(person)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
