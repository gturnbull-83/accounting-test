//
//  SeedData.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import Foundation
import SwiftData

struct SeedData {
    static func seedAccountsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Account>()
        let existingAccounts = (try? context.fetch(descriptor)) ?? []

        guard existingAccounts.isEmpty else { return }

        let accounts: [(String, AccountType, Int)] = [
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

        for (name, type, sortOrder) in accounts {
            let account = Account(name: name, type: type, sortOrder: sortOrder)
            context.insert(account)
        }

        try? context.save()
    }
}
