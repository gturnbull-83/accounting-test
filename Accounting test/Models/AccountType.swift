//
//  AccountType.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import Foundation

enum AccountType: String, Codable, CaseIterable {
    case asset
    case liability
    case equity
    case revenue
    case expense

    var displayName: String {
        switch self {
        case .asset: return "Assets"
        case .liability: return "Liabilities"
        case .equity: return "Equity"
        case .revenue: return "Revenue"
        case .expense: return "Expenses"
        }
    }

    var normalBalance: NormalBalance {
        switch self {
        case .asset, .expense:
            return .debit
        case .liability, .equity, .revenue:
            return .credit
        }
    }
}

enum NormalBalance {
    case debit
    case credit
}
