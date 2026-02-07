//
//  TransactionsListView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var selectedEntry: JournalEntry?

    private var viewModel: AccountingViewModel {
        AccountingViewModel(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "doc.text",
                        description: Text("Create a journal entry to see it here.")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
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
            .navigationTitle("Transactions")
            .sheet(item: $selectedEntry) { entry in
                TransactionDetailView(entry: entry)
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteJournalEntry(entries[index])
        }
    }
}

struct TransactionRow: View {
    let entry: JournalEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: entry.date)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: entry.displayAmount as NSDecimalNumber) ?? "$0.00"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.memo)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
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
                            Text(formatCurrency(line.amount))
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
                        Text(formatCurrency(entry.totalDebits))
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Total Credits")
                        Spacer()
                        Text(formatCurrency(entry.totalCredits))
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
        .modelContainer(for: [Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
