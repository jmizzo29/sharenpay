import SwiftData
import SwiftUI

@main
struct ZeroedApp: App {
    let container: ModelContainer
    @State private var session = SessionStore()

    init() {
        let schema = SchemaV1.schema
        let configuration = ModelConfiguration("Zeroed", schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Zeroed could not open its local cache: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .onOpenURL { url in
                    _ = session.handleOpenURL(url)
                }
        }
        .modelContainer(container)
    }
}
