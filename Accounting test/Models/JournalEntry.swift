//
//  JournalEntry.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var memo: String

    var company: Company?

    @Relationship(deleteRule: .cascade)
    var lineItems: [JournalEntryLine]?

    init(date: Date = Date(), memo: String = "") {
        self.id = UUID()
        self.date = date
        self.memo = memo
    }

    var totalDebits: Decimal {
        lineItems?.reduce(Decimal(0)) { $0 + $1.debitAmount } ?? 0
    }

    var totalCredits: Decimal {
        lineItems?.reduce(Decimal(0)) { $0 + $1.creditAmount } ?? 0
    }

    var isBalanced: Bool {
        totalDebits == totalCredits && totalDebits > 0
    }

    var displayAmount: Decimal {
        totalDebits
    }
}

@Model
final class JournalEntryLine {
    var id: UUID
    var debitAmount: Decimal
    var creditAmount: Decimal

    var account: Account?
    var journalEntry: JournalEntry?

    init(account: Account? = nil, debitAmount: Decimal = 0, creditAmount: Decimal = 0) {
        self.id = UUID()
        self.account = account
        self.debitAmount = debitAmount
        self.creditAmount = creditAmount
    }

    var amount: Decimal {
        debitAmount > 0 ? debitAmount : creditAmount
    }

    var isDebit: Bool {
        debitAmount > 0
    }
}
