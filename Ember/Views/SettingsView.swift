import LocalAuthentication
import SwiftUI

/// Pushed (not presented as a sheet) so appearance changes recolor it
/// live — sheets sit in their own presentation layer and don't follow
/// preferredColorScheme until re-presented.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage(DigestManager.enabledKey) private var digestEnabled = false
    @AppStorage(DigestManager.hourKey) private var digestHour = 9
    @AppStorage(DigestManager.minuteKey) private var digestMinute = 0

    @State private var lockError: String?
    @State private var digestError: String?
    @State private var purchaseInProgress = false
    @State private var purchaseSuccess = false

    private var digestTime: Binding<Date> {
        Binding {
            Calendar.current.date(
                bySettingHour: digestHour, minute: digestMinute, second: 0, of: .now
            ) ?? .now
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            digestHour = components.hour ?? 9
            digestMinute = components.minute ?? 0
            DigestManager.shared.reschedule(container: modelContext.container)
        }
    }

    var body: some View {
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
                Toggle("Daily digest", isOn: $digestEnabled)
                    .onChange(of: digestEnabled) { _, enabled in
                        if enabled {
                            enableDigest()
                        } else {
                            digestError = nil
                            DigestManager.shared.reschedule(container: modelContext.container)
                        }
                    }
                if digestEnabled {
                    DatePicker(
                        "Time",
                        selection: digestTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                if let digestError {
                    Text(digestError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("One gentle nudge a day, and only on days someone's drifting or a birthday is near. When everyone's in touch, Ember stays quiet.")
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
                Link(destination: URL(string: "https://ryantdo.com/ember/privacy.html")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "mailto:help@ryantdo.com?subject=Ember%20Feedback")!) {
                    HStack {
                        Text("Send Feedback")
                        Spacer()
                        Image(systemName: "envelope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button {
                    purchaseCoffee()
                } label: {
                    HStack {
                        Text("Buy Me Coffee")
                        Spacer()
                        Image(systemName: purchaseSuccess ? "checkmark.circle.fill" : "heart.fill")
                            .font(.caption)
                            .foregroundStyle(purchaseSuccess ? .green : .accentColor)
                    }
                }
                .disabled(purchaseInProgress)
                LabeledContent("Version", value: appVersion)
            } header: {
                Text("About")
            } footer: {
                Text("Made by Ryan Do, to keep the people you love close.")
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func enableDigest() {
        Task {
            let granted = await DigestManager.shared.requestPermission()
            if granted {
                digestError = nil
                DigestManager.shared.reschedule(container: modelContext.container)
            } else {
                digestEnabled = false
                digestError = "Notifications are off for Ember. Allow them in iOS Settings to get the digest."
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

    private func purchaseCoffee() {
        purchaseInProgress = true
        Task {
            let success = await TipJarManager.shared.purchase()
            purchaseInProgress = false
            if success {
                purchaseSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    purchaseSuccess = false
                }
            }
        }
    }
}
