import LocalAuthentication
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage("appLockEnabled") private var appLockEnabled = false

    @State private var lockError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearanceModeRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Theme.card)

                Section {
                    Toggle("Require Face ID", isOn: $appLockEnabled)
                        .onChange(of: appLockEnabled) { _, enabled in
                            if enabled { verifyLockAvailable() }
                        }
                    if let lockError {
                        Text(lockError)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Your people, notes, and history never leave this device. Face ID adds a lock on top.")
                }
                .listRowBackground(Theme.card)

                Section {
                    LabeledContent("Version", value: appVersion)
                } footer: {
                    Text("Made to keep the people you love close.")
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// Confirm the device can actually authenticate before promising a
    /// lock; otherwise flip the toggle back with an explanation.
    private func verifyLockAvailable() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            lockError = nil
        } else {
            appLockEnabled = false
            lockError = "Face ID or a passcode isn't set up on this device, so the lock can't be enabled."
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
