//
//  Company.swift
//  Accounting test
//
//  Created by gary turnbull on 2/9/26.
//

import Foundation
import SwiftData

@Model
final class Company {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Account.company)
    var accounts: [Account]?

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.company)
    var journalEntries: [JournalEntry]?

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
