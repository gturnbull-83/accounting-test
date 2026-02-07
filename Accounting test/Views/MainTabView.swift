//
//  MainTabView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case balanceSheet
    case profitLoss
    case journal
    case newEntry
    case transactions
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .balanceSheet

    var body: some View {
        TabView(selection: $selectedTab) {
            BalanceSheetView()
                .tabItem {
                    Label("Balance Sheet", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(AppTab.balanceSheet)

            ProfitLossView()
                .tabItem {
                    Label("Profit & Loss", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.profitLoss)

            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
                .tag(AppTab.journal)

            JournalEntryView(onSave: {
                selectedTab = .transactions
            })
                .tabItem {
                    Label("New Entry", systemImage: "plus.circle")
                }
                .tag(AppTab.newEntry)

            TransactionsListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.transactions)
        }
        .onAppear {
            SeedData.seedAccountsIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
