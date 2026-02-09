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
    @State private var selectedTab: AppTab = .balanceSheet

    var body: some View {
        VStack(spacing: 0) {
            CompanySwitcherView()

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
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
