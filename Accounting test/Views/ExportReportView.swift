//
//  ExportReportView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/10/26.
//

import SwiftUI
import SwiftData

enum ReportType: String, CaseIterable, Identifiable {
    case balanceSheet = "Balance Sheet"
    case profitAndLoss = "Profit & Loss"
    case trialBalance = "Trial Balance"

    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case csv = "CSV"

    var id: String { rawValue }
}

struct ExportReportView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]

    @State private var reportType: ReportType = .balanceSheet
    @State private var exportFormat: ExportFormat = .pdf
    @State private var asOfDate: Date = Date()
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var generatedFileURL: URL?
    @State private var isGenerating = false

    var preselectedReportType: ReportType?

    private var companyAccounts: [Account] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return allAccounts.filter { $0.company?.id == companyID }
    }

    private var companyName: String {
        companyManager?.activeCompany?.name ?? "Report"
    }

    var body: some View {
        NavigationStack {
            Form {
                if preselectedReportType == nil {
                    Section {
                        Picker("Report", selection: $reportType) {
                            ForEach(ReportType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    } header: {
                        Text("Report Type")
                    }
                }

                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Export Format")
                }

                Section {
                    if activeReportType == .profitAndLoss {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    } else {
                        DatePicker("As of Date", selection: $asOfDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Date")
                }

                Section {
                    if let url = generatedFileURL {
                        ShareLink(item: url) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button {
                        generateReport()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text("Generate Report")
                        }
                    }
                    .disabled(isGenerating)
                }
            }
            .navigationTitle("Export Reports")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let preset = preselectedReportType {
                    reportType = preset
                }
                let calendar = Calendar.current
                startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
                endDate = endOfMonth
            }
        }
    }

    private var activeReportType: ReportType {
        preselectedReportType ?? reportType
    }

    private func calculateBalance(for account: Account, asOf date: Date) -> Decimal {
        guard let lineItems = account.lineItems else { return 0 }
        let cutoff = Calendar.current.startOfDay(for: date).addingTimeInterval(86400)
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

    private func calculateBalance(for account: Account, from start: Date, to end: Date) -> Decimal {
        guard let lineItems = account.lineItems else { return 0 }
        let rangeStart = Calendar.current.startOfDay(for: start)
        let rangeEnd = Calendar.current.startOfDay(for: end).addingTimeInterval(86400)
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

    private func generateReport() {
        isGenerating = true
        generatedFileURL = nil

        let report: ReportData

        switch activeReportType {
        case .balanceSheet:
            report = buildBalanceSheetReport()
        case .profitAndLoss:
            report = buildProfitAndLossReport()
        case .trialBalance:
            report = buildTrialBalanceReport()
        }

        let fileData: Data
        let fileExtension: String

        switch exportFormat {
        case .csv:
            fileData = ReportGenerator.generateCSV(from: report).data(using: .utf8) ?? Data()
            fileExtension = "csv"
        case .pdf:
            fileData = ReportGenerator.generatePDF(from: report)
            fileExtension = "pdf"
        }

        let fileName = "\(companyName) - \(activeReportType.rawValue).\(fileExtension)"
            .replacingOccurrences(of: "/", with: "-")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try fileData.write(to: tempURL)
            generatedFileURL = tempURL
        } catch {
            // File write failed
        }

        isGenerating = false
    }

    private func buildBalanceSheetReport() -> ReportData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let assets = companyAccounts.filter { $0.type == .asset }
        let liabilities = companyAccounts.filter { $0.type == .liability }
        let equity = companyAccounts.filter { $0.type == .equity }
        let revenue = companyAccounts.filter { $0.type == .revenue }
        let expenses = companyAccounts.filter { $0.type == .expense }

        func totalFor(_ accounts: [Account]) -> Decimal {
            accounts.reduce(Decimal(0)) { $0 + calculateBalance(for: $1, asOf: asOfDate) }
        }

        let netIncome = totalFor(revenue) - totalFor(expenses)

        let assetRows = assets.map { ReportRow(label: $0.name, values: [calculateBalance(for: $0, asOf: asOfDate)]) }
            + [ReportRow(label: "Total Assets", values: [totalFor(assets)], isBold: true)]

        let liabilityRows = liabilities.map { ReportRow(label: $0.name, values: [calculateBalance(for: $0, asOf: asOfDate)]) }
            + [ReportRow(label: "Total Liabilities", values: [totalFor(liabilities)], isBold: true)]

        let equityRows = equity.map { ReportRow(label: $0.name, values: [calculateBalance(for: $0, asOf: asOfDate)]) }
            + [ReportRow(label: "Net Income", values: [netIncome])]
            + [ReportRow(label: "Total Equity", values: [totalFor(equity) + netIncome], isBold: true)]

        let totalLiabEquity = totalFor(liabilities) + totalFor(equity) + netIncome
        let totalSection = ReportSection(
            title: "",
            rows: [ReportRow(label: "Total Liabilities & Equity", values: [totalLiabEquity], isBold: true)]
        )

        return ReportData(
            title: "Balance Sheet",
            subtitle: "As of \(dateFormatter.string(from: asOfDate)) — \(companyName)",
            columnHeaders: ["Amount"],
            sections: [
                ReportSection(title: "Assets", rows: assetRows),
                ReportSection(title: "Liabilities", rows: liabilityRows),
                ReportSection(title: "Equity", rows: equityRows),
                totalSection
            ]
        )
    }

    private func buildProfitAndLossReport() -> ReportData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let revenue = companyAccounts.filter { $0.type == .revenue }
        let expenses = companyAccounts.filter { $0.type == .expense }

        func totalFor(_ accounts: [Account]) -> Decimal {
            accounts.reduce(Decimal(0)) { $0 + calculateBalance(for: $1, from: startDate, to: endDate) }
        }

        let netIncome = totalFor(revenue) - totalFor(expenses)

        let revenueRows = revenue.map { ReportRow(label: $0.name, values: [calculateBalance(for: $0, from: startDate, to: endDate)]) }
            + [ReportRow(label: "Total Revenue", values: [totalFor(revenue)], isBold: true)]

        let expenseRows = expenses.map { ReportRow(label: $0.name, values: [calculateBalance(for: $0, from: startDate, to: endDate)]) }
            + [ReportRow(label: "Total Expenses", values: [totalFor(expenses)], isBold: true)]

        let netIncomeSection = ReportSection(
            title: "",
            rows: [ReportRow(label: "Net Income", values: [netIncome], isBold: true)]
        )

        return ReportData(
            title: "Profit & Loss",
            subtitle: "\(dateFormatter.string(from: startDate)) – \(dateFormatter.string(from: endDate)) — \(companyName)",
            columnHeaders: ["Amount"],
            sections: [
                ReportSection(title: "Revenue", rows: revenueRows),
                ReportSection(title: "Expenses", rows: expenseRows),
                netIncomeSection
            ]
        )
    }

    private func buildTrialBalanceReport() -> ReportData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        var rows: [ReportRow] = []
        var totalDebits: Decimal = 0
        var totalCredits: Decimal = 0

        for account in companyAccounts {
            let balance = calculateBalance(for: account, asOf: asOfDate)
            guard balance != 0 else { continue }

            let isDebit: Bool
            switch account.type.normalBalance {
            case .debit:
                isDebit = balance >= 0
            case .credit:
                isDebit = balance < 0
            }

            let absBalance = abs(balance)
            let debitValue: Decimal = isDebit ? absBalance : 0
            let creditValue: Decimal = isDebit ? 0 : absBalance

            rows.append(ReportRow(label: account.name, values: [debitValue, creditValue]))

            totalDebits += debitValue
            totalCredits += creditValue
        }

        rows.append(ReportRow(label: "Totals", values: [totalDebits, totalCredits], isBold: true))

        return ReportData(
            title: "Trial Balance",
            subtitle: "As of \(dateFormatter.string(from: asOfDate)) — \(companyName)",
            columnHeaders: ["Debit", "Credit"],
            sections: [
                ReportSection(title: "Accounts", rows: rows)
            ]
        )
    }
}

#Preview {
    ExportReportView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
