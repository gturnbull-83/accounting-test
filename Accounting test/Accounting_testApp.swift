//
//  Accounting_testApp.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

@main
struct Accounting_testApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Company.self,
            Account.self,
            JournalEntry.self,
            JournalEntryLine.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var companyManager: CompanyManager?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if companyManager == nil {
                        let manager = CompanyManager(modelContext: sharedModelContainer.mainContext)
                        manager.bootstrap()
                        companyManager = manager
                    }
                }
                .environment(companyManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
