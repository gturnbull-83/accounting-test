//
//  AccountingViewModel.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class AccountingViewModel {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAccounts(ofType type: AccountType) -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.type == type },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchAllAccounts() -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchJournalEntries() -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func calculateAccountBalance(account: Account) -> Decimal {
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

    func totalForAccountType(_ type: AccountType) -> Decimal {
        let accounts = fetchAccounts(ofType: type)
        return accounts.reduce(Decimal(0)) { $0 + calculateAccountBalance(account: $1) }
    }

    func saveJournalEntry(date: Date, memo: String, lines: [(Account, Decimal, Bool)], company: Company?) -> Bool {
        let entry = JournalEntry(date: date, memo: memo)
        entry.company = company
        modelContext.insert(entry)

        for (account, amount, isDebit) in lines {
            let line = JournalEntryLine(
                account: account,
                debitAmount: isDebit ? amount : 0,
                creditAmount: isDebit ? 0 : amount
            )
            line.journalEntry = entry
            modelContext.insert(line)
        }

        do {
            try modelContext.save()
            return true
        } catch {
            print("Failed to save journal entry: \(error)")
            return false
        }
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    func netIncome() -> Decimal {
        let revenue = totalForAccountType(.revenue)
        let expenses = totalForAccountType(.expense)
        return revenue - expenses
    }
}
