//
//  TrialBalanceView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/10/26.
//

import SwiftUI
import SwiftData

struct TrialBalanceView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]
    @State private var asOfDate: Date = Date()

    private var companyAccounts: [Account] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return allAccounts.filter { $0.company?.id == companyID }
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

    private var accountsWithBalances: [(Account, Decimal)] {
        companyAccounts.compactMap { account in
            let balance = calculateBalance(for: account)
            guard balance != 0 else { return nil }
            return (account, balance)
        }
    }

    private var totalDebits: Decimal {
        accountsWithBalances.reduce(Decimal(0)) { total, pair in
            let (account, balance) = pair
            if isDebitBalance(account: account, balance: balance) {
                return total + abs(balance)
            }
            return total
        }
    }

    private var totalCredits: Decimal {
        accountsWithBalances.reduce(Decimal(0)) { total, pair in
            let (account, balance) = pair
            if !isDebitBalance(account: account, balance: balance) {
                return total + abs(balance)
            }
            return total
        }
    }

    private var isBalanced: Bool {
        totalDebits == totalCredits
    }

    private func isDebitBalance(account: Account, balance: Decimal) -> Bool {
        switch account.type.normalBalance {
        case .debit:
            return balance >= 0
        case .credit:
            return balance < 0
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
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
                    // Header row
                    HStack {
                        Text("Account")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        Text("Debit")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .frame(width: 90, alignment: .trailing)
                        Text("Credit")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .frame(width: 90, alignment: .trailing)
                    }

                    ForEach(accountsWithBalances, id: \.0.id) { account, balance in
                        HStack {
                            Text(account.name)
                            Spacer()
                            if isDebitBalance(account: account, balance: balance) {
                                Text(formatCurrency(abs(balance)))
                                    .monospacedDigit()
                                    .frame(width: 90, alignment: .trailing)
                                Text("")
                                    .frame(width: 90, alignment: .trailing)
                            } else {
                                Text("")
                                    .frame(width: 90, alignment: .trailing)
                                Text(formatCurrency(abs(balance)))
                                    .monospacedDigit()
                                    .frame(width: 90, alignment: .trailing)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Totals")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatCurrency(totalDebits))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .frame(width: 90, alignment: .trailing)
                        Text(formatCurrency(totalCredits))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .frame(width: 90, alignment: .trailing)
                    }

                    HStack {
                        Spacer()
                        if isBalanced {
                            Label("Balanced", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        } else {
                            Label("Out of Balance", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        Spacer()
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Trial Balance")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TrialBalanceView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
