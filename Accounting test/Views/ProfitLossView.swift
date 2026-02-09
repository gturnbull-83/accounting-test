//
//  ProfitLossView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

enum PeriodPreset: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case thisQuarter = "This Quarter"
    case thisYear = "This Year"
    case lastMonth = "Last Month"
    case lastQuarter = "Last Quarter"
    case lastYear = "Last Year"
    case custom = "Custom"

    var id: String { rawValue }

    func dateRange(using calendar: Calendar = .current) -> (start: Date, end: Date)? {
        let now = Date()
        switch self {
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)
        case .thisQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStart = ((month - 1) / 3) * 3 + 1
            var comps = calendar.dateComponents([.year], from: now)
            comps.month = quarterStart
            comps.day = 1
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start)!
            return (start, end)
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start)!
            return (start, end)
        case .lastMonth:
            let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)
        case .lastQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStart = ((month - 1) / 3) * 3 + 1
            var comps = calendar.dateComponents([.year], from: now)
            comps.month = quarterStart
            comps.day = 1
            let thisQuarterStart = calendar.date(from: comps)!
            let start = calendar.date(byAdding: .month, value: -3, to: thisQuarterStart)!
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start)!
            return (start, end)
        case .lastYear:
            var comps = calendar.dateComponents([.year], from: now)
            comps.year! -= 1
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start)!
            return (start, end)
        case .custom:
            return nil
        }
    }
}

struct ProfitLossView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]
    @State private var selectedPreset: PeriodPreset = .thisMonth
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()

    private var companyAccounts: [Account] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return allAccounts.filter { $0.company?.id == companyID }
    }

    private var revenueAccounts: [Account] {
        companyAccounts.filter { $0.type == .revenue }
    }

    private var expenseAccounts: [Account] {
        companyAccounts.filter { $0.type == .expense }
    }

    private func totalFor(_ accounts: [Account]) -> Decimal {
        accounts.reduce(Decimal(0)) { $0 + calculateBalance(for: $1) }
    }

    private func calculateBalance(for account: Account) -> Decimal {
        guard let lineItems = account.lineItems else { return 0 }
        let rangeStart = Calendar.current.startOfDay(for: startDate)
        let rangeEnd = Calendar.current.startOfDay(for: endDate).addingTimeInterval(86400)
        var balance: Decimal = 0
        for line in lineItems {
            guard let entryDate = line.journalEntry?.date,
                  entryDate >= rangeStart,
                  entryDate < rangeEnd else { continue }
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
        totalFor(revenueAccounts) - totalFor(expenseAccounts)
    }

    private var dateRangeSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    private func applyPreset(_ preset: PeriodPreset) {
        if let range = preset.dateRange() {
            startDate = range.start
            endDate = range.end
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Period", selection: $selectedPreset) {
                        ForEach(PeriodPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }

                    if selectedPreset == .custom {
                        DatePicker(
                            "Start",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        DatePicker(
                            "End",
                            selection: $endDate,
                            displayedComponents: .date
                        )
                    }
                }

                Section {
                    ForEach(revenueAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    TotalRow(
                        label: "Total Revenue",
                        amount: totalFor(revenueAccounts)
                    )
                } header: {
                    SectionHeader(title: "Revenue")
                }

                Section {
                    ForEach(expenseAccounts) { account in
                        AccountRow(
                            name: account.name,
                            balance: calculateBalance(for: account)
                        )
                    }
                    TotalRow(
                        label: "Total Expenses",
                        amount: totalFor(expenseAccounts)
                    )
                } header: {
                    SectionHeader(title: "Expenses")
                }

                Section {
                    NetIncomeRow(amount: netIncome)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("Profit & Loss")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Profit & Loss")
                            .font(.headline)
                        Text(dateRangeSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                applyPreset(selectedPreset)
            }
            .onChange(of: selectedPreset) { _, newValue in
                applyPreset(newValue)
            }
        }
    }
}

struct NetIncomeRow: View {
    let amount: Decimal

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    private var isPositive: Bool {
        amount >= 0
    }

    var body: some View {
        HStack {
            Text("Net Income")
                .fontWeight(.bold)
            Spacer()
            Text(formattedAmount)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(isPositive ? Color.green : Color.red)
        }
    }
}

#Preview {
    ProfitLossView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
