//
//  EditAccountView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/10/26.
//

import SwiftUI
import SwiftData

struct EditAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var accountName: String
    @State private var accountType: AccountType

    private var hasTransactions: Bool {
        !(account.lineItems ?? []).isEmpty
    }

    private var canSave: Bool {
        !accountName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(account: Account) {
        self.account = account
        _accountName = State(initialValue: account.name)
        _accountType = State(initialValue: account.type)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account Name", text: $accountName)
                } header: {
                    Text("Name")
                }

                Section {
                    Picker("Account Type", selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .disabled(hasTransactions)

                    if hasTransactions {
                        Text("Account type cannot be changed because this account has transactions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Type")
                }
            }
            .navigationTitle("Edit Account")
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
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveChanges() {
        let trimmedName = accountName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        account.name = trimmedName
        account.type = accountType
        try? modelContext.save()
        dismiss()
    }
}
