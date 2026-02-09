//
//  ContentView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?

    var body: some View {
        if companyManager?.activeCompany != nil {
            MainTabView()
        } else {
            ProgressView("Loading...")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
