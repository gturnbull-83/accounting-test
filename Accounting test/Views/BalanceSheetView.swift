//
//  BalanceSheetView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct BalanceSheetView: View {
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]
    @State private var asOfDate: Date = Date()

    private var assetAccounts: [Account] {
        allAccounts.filter { $0.type == .asset }
    }

    private var liabilityAccounts: [Account] {
        allAccounts.filter { $0.type == .liability }
    }

    private var equityAccounts: [Account] {
        allAccounts.filter { $0.type == .equity }
    }

    private func totalFor(_ accounts: [Account]) -> Decimal {
        accounts.reduce(Decimal(0)) { $0 + calculateBalance(for: $1) }
    }

    private func calculateBalance(for account: Account) -> Decimal {
        guard let lineItems = account.lineItems else { return 0 }
        let cutoff = Calendar.current.startOfDay(for: asOfDate).addingTimeInterval(86400)
        var balance: Decimal = 0
        for line in lineItems {
            guard let entryDate = line.journalEntry?.date, entryDate < cutoff else { continue }
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
        let revenueAccounts = allAccounts.filter { $0.type == .revenue }
        let expenseAccounts = allAccounts.filter { $0.type == .expense }
        return totalFor(revenueAccounts) - totalFor(expenseAccounts)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker(
                        "As of",
                        selection: $asOfDate,
                        displayedComponents: .date
                    )
                }

                Section {
                    ForEach(assetAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    TotalRow(
                        label: "Total Assets",
                        amount: totalFor(assetAccounts)
                    )
                } header: {
                    SectionHeader(title: "Assets")
                }

                Section {
                    ForEach(liabilityAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    TotalRow(
                        label: "Total Liabilities",
                        amount: totalFor(liabilityAccounts)
                    )
                } header: {
                    SectionHeader(title: "Liabilities")
                }

                Section {
                    ForEach(equityAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    AccountRow(
                        name: "Net Income",
                        balance: netIncome
                    )
                    TotalRow(
                        label: "Total Equity",
                        amount: totalFor(equityAccounts) + netIncome
                    )
                } header: {
                    SectionHeader(title: "Equity")
                }

                Section {
                    TotalRow(
                        label: "Total Liabilities & Equity",
                        amount: totalFor(liabilityAccounts) +
                                totalFor(equityAccounts) +
                                netIncome
                    )
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("Balance Sheet")
        }
    }
}

struct AccountRow: View {
    let name: String
    let balance: Decimal

    private var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: balance as NSDecimalNumber) ?? "$0.00"
    }

    var body: some View {
        HStack {
            Text(name)
                .foregroundStyle(.primary)
            Spacer()
            Text(formattedBalance)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

struct TotalRow: View {
    let label: String
    let amount: Decimal

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(formattedAmount)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    BalanceSheetView()
        .modelContainer(for: [Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
