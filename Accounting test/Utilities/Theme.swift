//
//  Theme.swift
//  Accounting test
//
//  Created by gary turnbull on 2/11/26.
//

import SwiftUI

enum Theme {
    // MARK: - Accent Color

    static let accent = Color(red: 0.325, green: 0.624, blue: 0.776) // #539FC6

    // MARK: - Account Type Colors

    static func color(for type: AccountType) -> Color {
        switch type {
        case .asset:     return Color(red: 0.18, green: 0.60, blue: 0.58)  // Teal
        case .liability: return Color(red: 0.80, green: 0.58, blue: 0.20)  // Amber
        case .equity:    return Color(red: 0.42, green: 0.47, blue: 0.53)  // Slate
        case .revenue:   return Color(red: 0.22, green: 0.63, blue: 0.42)  // Green
        case .expense:   return Color(red: 0.82, green: 0.35, blue: 0.38)  // Rose
        }
    }

    // MARK: - Currency Formatting

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    static func formatCurrency(_ value: Decimal) -> String {
        currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var borderColor: Color? = nil

    private var cardBackground: Color {
        #if os(iOS) || os(visionOS)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(.controlBackgroundColor)
        #endif
    }

    func body(content: Content) -> some View {
        content
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .leading) {
                if let borderColor {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(borderColor)
                        .frame(width: 4)
                }
            }
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(borderColor: Color? = nil) -> some View {
        modifier(CardStyle(borderColor: borderColor))
    }
}
