//
//  Account.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Decimal
    var sortOrder: Int

    var company: Company?

    @Relationship(inverse: \JournalEntryLine.account)
    var lineItems: [JournalEntryLine]?

    init(name: String, type: AccountType, balance: Decimal = 0, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.balance = balance
        self.sortOrder = sortOrder
    }
}
