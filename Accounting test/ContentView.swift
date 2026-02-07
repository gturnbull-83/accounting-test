//
//  ContentView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
