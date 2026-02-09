//
//  JournalEntryView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/7/26.
//

import SwiftUI
import SwiftData

struct JournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.name) private var accounts: [Account]

    var onSave: (() -> Void)?

    @State private var date = Date()
    @State private var memo = ""
    @State private var lineItems: [LineItemEntry] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var viewModel: AccountingViewModel {
        AccountingViewModel(modelContext: modelContext)
    }

    private var totalDebits: Decimal {
        lineItems.filter { $0.isDebit }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var totalCredits: Decimal {
        lineItems.filter { !$0.isDebit }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var isBalanced: Bool {
        totalDebits == totalCredits && totalDebits > 0
    }

    private var difference: Decimal {
        totalDebits - totalCredits
    }

    private var canSave: Bool {
        isBalanced && !memo.isEmpty && lineItems.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Memo", text: $memo, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Entry Details")
                }

                Section {
                    ForEach($lineItems) { $item in
                        LineItemRow(
                            item: $item,
                            accounts: accounts,
                            onDelete: {
                                if let index = lineItems.firstIndex(where: { $0.id == item.id }) {
                                    lineItems.remove(at: index)
                                }
                            }
                        )
                    }

                    Button {
                        lineItems.append(LineItemEntry())
                    } label: {
                        Label("Add Line Item", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Line Items")
                }

                Section {
                    HStack {
                        Text("Total Debits")
                        Spacer()
                        Text(formatCurrency(totalDebits))
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Total Credits")
                        Spacer()
                        Text(formatCurrency(totalCredits))
                            .monospacedDigit()
                    }

                    if !isBalanced && (totalDebits > 0 || totalCredits > 0) {
                        HStack {
                            Text("Difference")
                                .foregroundStyle(.red)
                            Spacer()
                            Text(formatCurrency(abs(difference)))
                                .monospacedDigit()
                                .foregroundStyle(.red)
                        }
                    }

                    if isBalanced {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Entry is balanced")
                                .foregroundStyle(.green)
                        }
                    }
                } header: {
                    Text("Balance Check")
                }

                Section {
                    Button {
                        saveEntry()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Journal Entry")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!canSave)

                    if !canSave {
                        VStack(alignment: .leading, spacing: 4) {
                            if memo.isEmpty {
                                Label("Enter a memo", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if lineItems.count < 2 {
                                Label("Add at least 2 line items", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            if !isBalanced && totalDebits > 0 {
                                Label("Debits must equal credits", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("New Entry")
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    private func saveEntry() {
        guard isBalanced else {
            alertMessage = "Debits must equal credits before saving."
            showingAlert = true
            return
        }

        guard !memo.isEmpty else {
            alertMessage = "Please enter a memo for this entry."
            showingAlert = true
            return
        }

        let validLines = lineItems.compactMap { item -> (Account, Decimal, Bool)? in
            guard let account = item.selectedAccount, item.amount > 0 else { return nil }
            return (account, item.amount, item.isDebit)
        }

        guard validLines.count >= 2 else {
            alertMessage = "Please add at least two line items with amounts."
            showingAlert = true
            return
        }

        let success = viewModel.saveJournalEntry(date: date, memo: memo, lines: validLines)

        if success {
            resetForm()
            onSave?()
        } else {
            alertMessage = "Failed to save journal entry. Please try again."
            showingAlert = true
        }
    }

    private func resetForm() {
        date = Date()
        memo = ""
        lineItems = []
    }
}

struct LineItemEntry: Identifiable {
    let id = UUID()
    var selectedAccount: Account?
    var amount: Decimal = 0
    var isDebit: Bool = true
    var amountString: String = ""
}

struct LineItemRow: View {
    @Binding var item: LineItemEntry
    let accounts: [Account]
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Account", selection: $item.selectedAccount) {
                    Text("Select Account").tag(nil as Account?)
                    ForEach(accounts) { account in
                        Text(account.name).tag(account as Account?)
                    }
                }
                .labelsHidden()

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Picker("Type", selection: $item.isDebit) {
                    Text("Debit").tag(true)
                    Text("Credit").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)

                Spacer()

                TextField("Amount", text: $item.amountString)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: item.amountString) { _, newValue in
                        if let decimal = Decimal(string: newValue) {
                            item.amount = decimal
                        } else if newValue.isEmpty {
                            item.amount = 0
                        }
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalEntryView(onSave: nil)
        .modelContainer(for: [Account.self, JournalEntry.self, JournalEntryLine.self], inMemory: true)
}
