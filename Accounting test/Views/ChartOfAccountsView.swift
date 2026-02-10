//
//  ChartOfAccountsView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/10/26.
//

import SwiftUI
import SwiftData

struct ChartOfAccountsView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.sortOrder) private var allAccounts: [Account]

    @State private var showingAddAccount = false
    @State private var editingAccount: Account?
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: Account?

    private var companyAccounts: [Account] {
        guard let companyID = companyManager?.activeCompany?.id else { return [] }
        return allAccounts.filter { $0.company?.id == companyID }
    }

    private var groupedAccounts: [(AccountType, [Account])] {
        let grouped = Dictionary(grouping: companyAccounts) { $0.type }
        return AccountType.allCases.compactMap { type in
            guard let accounts = grouped[type], !accounts.isEmpty else { return nil }
            return (type, accounts)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedAccounts, id: \.0) { type, accounts in
                    Section {
                        ForEach(accounts) { account in
                            HStack {
                                Text(account.name)
                                if !(account.lineItems ?? []).isEmpty {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingAccount = account
                            }
                        }
                        .onDelete { offsets in
                            deleteAccounts(offsets: offsets, from: accounts)
                        }
                        .onMove { source, destination in
                            moveAccounts(source: source, destination: destination, in: accounts, ofType: type)
                        }
                    } header: {
                        SectionHeader(title: type.displayName)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .navigationTitle("Chart of Accounts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        #if os(iOS) || os(visionOS)
                        EditButton()
                        #endif
                        Button {
                            showingAddAccount = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .sheet(item: $editingAccount) { account in
                EditAccountView(account: account)
            }
            .alert("Cannot Delete", isPresented: $showingDeleteAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This account has transactions and cannot be deleted.")
            }
        }
    }

    private func deleteAccounts(offsets: IndexSet, from accounts: [Account]) {
        for index in offsets {
            let account = accounts[index]
            if !(account.lineItems ?? []).isEmpty {
                accountToDelete = account
                showingDeleteAlert = true
            } else {
                modelContext.delete(account)
                try? modelContext.save()
            }
        }
    }

    private func moveAccounts(source: IndexSet, destination: Int, in accounts: [Account], ofType type: AccountType) {
        var mutableAccounts = accounts
        mutableAccounts.move(fromOffsets: source, toOffset: destination)
        for (index, account) in mutableAccounts.enumerated() {
            account.sortOrder = index
        }
        try? modelContext.save()
    }
}
