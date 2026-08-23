import SwiftData
import SwiftUI

@main
struct ShareNPayApp: App {
    let container: ModelContainer

    init() {
        let schema = SchemaV1.schema
        let configuration = ModelConfiguration("ShareNPay", schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ShareNPay could not open its local store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
