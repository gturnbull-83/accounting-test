//
//  AddAccountView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/9/26.
//

import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var accountName = ""
    @State private var accountType: AccountType = .asset

    private var canSave: Bool {
        !accountName.trimmingCharacters(in: .whitespaces).isEmpty
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
                            HStack {
                                Circle()
                                    .fill(Theme.color(for: type))
                                    .frame(width: 8, height: 8)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text("Type")
                }
            }
            .navigationTitle("Add Account")
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
                        saveAccount()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveAccount() {
        let trimmedName = accountName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let account = Account(name: trimmedName, type: accountType, sortOrder: 999)
        account.company = companyManager?.activeCompany
        modelContext.insert(account)
        try? modelContext.save()
        dismiss()
    }
}
