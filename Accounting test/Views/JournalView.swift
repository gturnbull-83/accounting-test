//
//  JournalView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    private var companyEntries: [JournalEntry] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return entries.filter { $0.company?.id == companyID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if companyEntries.isEmpty {
                    ContentUnavailableView(
                        "No Journal Entries",
                        systemImage: "book.closed",
                        description: Text("Create a journal entry to see it here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(companyEntries) { entry in
                                JournalEntryCard(entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Journal")
        }
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Theme.formatCurrency(entry.displayAmount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            // Memo
            if !entry.memo.isEmpty {
                Text(entry.memo)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            // Line items table
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Account")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Debit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                    Text("Credit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()
                    .padding(.horizontal, 16)

                // Line items
                ForEach(entry.lineItems ?? []) { line in
                    HStack {
                        Text(line.account?.name ?? "Unknown")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(line.debitAmount > 0 ? Theme.formatCurrency(line.debitAmount) : "")
                            .font(.subheadline)
                            .monospacedDigit()
                            .frame(width: 80, alignment: .trailing)
                        Text(line.creditAmount > 0 ? Theme.formatCurrency(line.creditAmount) : "")
                            .font(.subheadline)
                            .monospacedDigit()
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Totals row
                HStack {
                    Text("Total")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(Theme.formatCurrency(entry.totalDebits))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(width: 80, alignment: .trailing)
                    Text(Theme.formatCurrency(entry.totalCredits))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .padding(.bottom, 8)
        }
        .cardStyle(borderColor: .indigo)
    }
}

#Preview {
    JournalView()
        .modelContainer(for: [Company.self, Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
