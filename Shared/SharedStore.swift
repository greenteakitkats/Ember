import Foundation
import SwiftData

/// One SwiftData store shared between the app and the widget via the
/// app group container. Falls back to the default local store when the
/// group isn't available (e.g. unsigned simulator builds), so the app
/// keeps working even if provisioning hiccups.
enum SharedStore {
    static let appGroupID = "group.ryantdo.Weave"

    static func modelContainer() throws -> ModelContainer {
        let schema = Schema([Person.self, Interaction.self])
        let configuration: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            configuration = ModelConfiguration(
                schema: schema,
                url: groupURL.appendingPathComponent("Weave.store")
            )
        } else {
            configuration = ModelConfiguration(schema: schema)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
