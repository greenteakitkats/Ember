import SwiftUI
import SwiftData

@main
struct WeaveApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try SharedStore.modelContainer()
        } catch {
            fatalError("Could not create the Weave data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fontDesign(.rounded)
        }
        .modelContainer(container)
    }
}
