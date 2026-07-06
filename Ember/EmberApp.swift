import LocalAuthentication
import SwiftData
import SwiftUI

@main
struct EmberApp: App {
    private let container: ModelContainer

    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked: Bool

    init() {
        do {
            container = try SharedStore.modelContainer()
        } catch {
            fatalError("Could not create the Ember data store: \(error)")
        }
        _isUnlocked = State(initialValue: !UserDefaults.standard.bool(forKey: "appLockEnabled"))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if appLockEnabled && !isUnlocked {
                    LockView {
                        await unlock()
                    }
                }
            }
            .fontDesign(.rounded)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceModeRaw)?.colorScheme)
            .onChange(of: scenePhase) { _, phase in
                guard appLockEnabled else { return }
                if phase == .background {
                    isUnlocked = false
                } else if phase == .active && !isUnlocked {
                    Task { await unlock() }
                }
            }
            .task {
                if appLockEnabled && !isUnlocked {
                    await unlock()
                }
            }
        }
        .modelContainer(container)
    }

    private func unlock() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Lock is enabled but the device can't authenticate (e.g.
            // passcode removed) — don't brick the user's own data.
            isUnlocked = true
            return
        }
        let unlocked = (try? await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Ember keeps your people and notes private."
        )) ?? false
        if unlocked {
            isUnlocked = true
        }
    }
}

private struct LockView: View {
    var onUnlock: () async -> Void

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.accentColor)
                Text("Ember is locked")
                    .font(.title3)
                    .fontDesign(.serif)
                Button("Unlock") {
                    Task { await onUnlock() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
