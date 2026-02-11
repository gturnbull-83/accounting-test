//
//  TransactionsListView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Account.name) private var allAccountsForFilter: [Account]

    @State private var selectedEntry: JournalEntry?
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    @State private var filterAccount: Account?

    private var viewModel: AccountingViewModel {
        AccountingViewModel(modelContext: modelContext)
    }

    private var companyEntries: [JournalEntry] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return entries.filter { $0.company?.id == companyID }
    }

    private var companyAccountsForFilter: [Account] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return allAccountsForFilter.filter { $0.company?.id == companyID }
    }

    private var hasActiveFilters: Bool {
        filterStartDate != nil || filterEndDate != nil || filterAccount != nil
    }

    private var filteredEntries: [JournalEntry] {
        var result = companyEntries

        if !searchText.isEmpty {
            result = result.filter { $0.memo.localizedCaseInsensitiveContains(searchText) }
        }

        if let start = filterStartDate {
            let startOfDay = Calendar.current.startOfDay(for: start)
            result = result.filter { $0.date >= startOfDay }
        }

        if let end = filterEndDate {
            let endOfDay = Calendar.current.startOfDay(for: end).addingTimeInterval(86400)
            result = result.filter { $0.date < endOfDay }
        }

        if let account = filterAccount {
            result = result.filter { entry in
                entry.lineItems?.contains { $0.account?.id == account.id } ?? false
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if hasActiveFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if let start = filterStartDate {
                                FilterChip(label: "From: \(formatChipDate(start))") {
                                    filterStartDate = nil
                                }
                            }
                            if let end = filterEndDate {
                                FilterChip(label: "To: \(formatChipDate(end))") {
                                    filterEndDate = nil
                                }
                            }
                            if let account = filterAccount {
                                FilterChip(label: account.name) {
                                    filterAccount = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                Group {
                    if companyEntries.isEmpty {
                        ContentUnavailableView(
                            "No Transactions",
                            systemImage: "doc.text",
                            description: Text("Create a journal entry to see it here.")
                        )
                    } else if filteredEntries.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search or filters.")
                        )
                    } else {
                        List {
                            ForEach(filteredEntries) { entry in
                                TransactionRow(entry: entry)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedEntry = entry
                                    }
                            }
                            .onDelete(perform: deleteEntries)
                        }
                        #if os(iOS)
                        .listStyle(.insetGrouped)
                        #endif
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search by memo")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                TransactionDetailView(entry: entry)
            }
            .sheet(isPresented: $showingFilters) {
                TransactionFilterView(
                    filterStartDate: $filterStartDate,
                    filterEndDate: $filterEndDate,
                    filterAccount: $filterAccount,
                    accounts: companyAccountsForFilter
                )
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteJournalEntry(filteredEntries[index])
        }
    }

    private func formatChipDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.accent.opacity(0.12), in: Capsule())
        .foregroundStyle(Theme.accent)
    }
}

struct TransactionFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filterStartDate: Date?
    @Binding var filterEndDate: Date?
    @Binding var filterAccount: Account?
    let accounts: [Account]

    @State private var hasStartDate = false
    @State private var hasEndDate = false
    @State private var localStartDate = Date()
    @State private var localEndDate = Date()
    @State private var selectedAccountID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Start Date", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("From", selection: $localStartDate, displayedComponents: .date)
                    }
                    Toggle("End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("To", selection: $localEndDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Date Range")
                }

                Section {
                    Picker("Account", selection: $selectedAccountID) {
                        Text("All Accounts").tag(nil as UUID?)
                        ForEach(accounts) { account in
                            Text(account.name).tag(account.id as UUID?)
                        }
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    Button("Clear All Filters", role: .destructive) {
                        hasStartDate = false
                        hasEndDate = false
                        selectedAccountID = nil
                    }
                }
            }
            .navigationTitle("Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                    }
                }
            }
            .onAppear {
                hasStartDate = filterStartDate != nil
                hasEndDate = filterEndDate != nil
                if let start = filterStartDate { localStartDate = start }
                if let end = filterEndDate { localEndDate = end }
                selectedAccountID = filterAccount?.id
            }
        }
    }

    private func applyFilters() {
        filterStartDate = hasStartDate ? localStartDate : nil
        filterEndDate = hasEndDate ? localEndDate : nil
        filterAccount = accounts.first { $0.id == selectedAccountID }
        dismiss()
    }
}

struct TransactionRow: View {
    let entry: JournalEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: entry.date)
    }

    private var isBalanced: Bool {
        entry.totalDebits == entry.totalCredits
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isBalanced ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.memo)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(Theme.formatCurrency(entry.displayAmount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: entry.date)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Date", value: formattedDate)
                    LabeledContent("Memo", value: entry.memo)
                } header: {
                    Text("Entry Details")
                }

                Section {
                    ForEach(entry.lineItems ?? []) { line in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.account?.name ?? "Unknown Account")
                                    .font(.subheadline)
                                Text(line.isDebit ? "Debit" : "Credit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Theme.formatCurrency(line.amount))
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Line Items")
                }

                Section {
                    HStack {
                        Text("Total Debits")
                        Spacer()
                        Text(Theme.formatCurrency(entry.totalDebits))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Total Credits")
                        Spacer()
                        Text(Theme.formatCurrency(entry.totalCredits))
                            .monospacedDigit()
                    }
                } header: {
                    Text("Totals")
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Transaction Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionsListView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
