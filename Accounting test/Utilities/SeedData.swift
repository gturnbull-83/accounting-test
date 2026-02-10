//
//  SeedData.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import Foundation
import SwiftData

struct SeedData {
    static let defaultAccounts: [(String, AccountType, Int)] = [
        // Assets
        ("Cash", .asset, 1),
        ("Checking", .asset, 2),
        ("Savings", .asset, 3),
        ("Accounts Receivable", .asset, 4),
        ("Equipment", .asset, 5),

        // Liabilities
        ("Credit Cards Payable", .liability, 1),
        ("Loan Payable", .liability, 2),
        ("Sales Tax Payable", .liability, 3),

        // Equity
        ("Owner's Equity", .equity, 1),
        ("Retained Earnings", .equity, 2),

        // Revenue
        ("Sales Income", .revenue, 1),
        ("Affiliate Income", .revenue, 2),
        ("Advertising Income", .revenue, 3),

        // Expenses
        ("Materials", .expense, 1),
        ("Subcontractors", .expense, 2),
        ("Advertising/Marketing", .expense, 3),
        ("Software/Subscriptions", .expense, 4),
        ("Insurance", .expense, 5),
        ("Office Supplies", .expense, 6),
        ("Travel", .expense, 7),
        ("Meals", .expense, 8),
        ("Professional Fees", .expense, 9),
        ("Repairs & Maintenance", .expense, 10)
    ]

    static func seedAccounts(for company: Company, context: ModelContext) {
        for (name, type, sortOrder) in defaultAccounts {
            let account = Account(name: name, type: type, sortOrder: sortOrder)
            account.company = company
            context.insert(account)
        }
        try? context.save()
    }

    private static let hasSeededKey = "hasSeededDefaultData"

    static func ensureDefaultCompanyExists(context: ModelContext) -> Company? {
        let descriptor = FetchDescriptor<Company>()
        let existingCompanies = (try? context.fetch(descriptor)) ?? []

        if let first = existingCompanies.first {
            return first
        }

        // Already seeded on this device — data hasn't synced from CloudKit yet
        if UserDefaults.standard.bool(forKey: hasSeededKey) {
            return nil
        }

        let company = Company(name: "My Company")
        context.insert(company)

        // Check if there are existing accounts (pre-migration data)
        let accountDescriptor = FetchDescriptor<Account>()
        let existingAccounts = (try? context.fetch(accountDescriptor)) ?? []

        if existingAccounts.isEmpty {
            // Fresh install — seed default accounts
            seedAccounts(for: company, context: context)
        } else {
            // Existing data — migrate orphaned records
            migrateOrphanedData(context: context, to: company)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: hasSeededKey)
        return company
    }

    static func migrateOrphanedData(context: ModelContext, to company: Company) {
        let accountDescriptor = FetchDescriptor<Account>()
        let accounts = (try? context.fetch(accountDescriptor)) ?? []
        for account in accounts where account.company == nil {
            account.company = company
        }

        let entryDescriptor = FetchDescriptor<JournalEntry>()
        let entries = (try? context.fetch(entryDescriptor)) ?? []
        for entry in entries where entry.company == nil {
            entry.company = company
        }

        try? context.save()
    }
}
