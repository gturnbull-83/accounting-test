//
//  ProfitLossView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct ProfitLossView: View {
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]

    private var revenueAccounts: [Account] {
        allAccounts.filter { $0.type == .revenue }
    }

    private var expenseAccounts: [Account] {
        allAccounts.filter { $0.type == .expense }
    }

    private func totalFor(_ accounts: [Account]) -> Decimal {
        accounts.reduce(Decimal(0)) { $0 + calculateBalance(for: $1) }
    }

    private func calculateBalance(for account: Account) -> Decimal {
        guard let lineItems = account.lineItems else { return 0 }
        var balance: Decimal = 0
        for line in lineItems {
            switch account.type.normalBalance {
            case .debit:
                balance += line.debitAmount - line.creditAmount
            case .credit:
                balance += line.creditAmount - line.debitAmount
            }
        }
        return balance
    }

    private var netIncome: Decimal {
        totalFor(revenueAccounts) - totalFor(expenseAccounts)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(revenueAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    TotalRow(
                        label: "Total Revenue",
                        amount: totalFor(revenueAccounts)
                    )
                } header: {
                    SectionHeader(title: "Revenue")
                }

                Section {
                    ForEach(expenseAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    TotalRow(
                        label: "Total Expenses",
                        amount: totalFor(expenseAccounts)
                    )
                } header: {
                    SectionHeader(title: "Expenses")
                }

                Section {
                    NetIncomeRow(amount: netIncome)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("Profit & Loss")
        }
    }
}

struct NetIncomeRow: View {
    let amount: Decimal

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    private var isPositive: Bool {
        amount >= 0
    }

    var body: some View {
        HStack {
            Text("Net Income")
                .fontWeight(.bold)
            Spacer()
            Text(formattedAmount)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(isPositive ? Color.green : Color.red)
        }
    }
}

#Preview {
    ProfitLossView()
        .modelContainer(for: [Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
