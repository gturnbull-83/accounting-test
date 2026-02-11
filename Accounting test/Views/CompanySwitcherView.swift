//
//  CompanySwitcherView.swift
//  Accounting test
//
//  Created by gary turnbull on 2/9/26.
//

import SwiftUI
import SwiftData

struct CompanySwitcherView: View {
    @Environment(CompanyManager.self) private var companyManager: CompanyManager?

    @State private var showingAddAlert = false
    @State private var newCompanyName = ""

    private var companies: [Company] {
        companyManager?.fetchAllCompanies() ?? []
    }

    var body: some View {
        HStack {
            Menu {
                ForEach(companies) { company in
                    Button {
                        companyManager?.switchTo(company)
                    } label: {
                        HStack {
                            Text(company.name)
                            if company.id == companyManager?.activeCompany?.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    newCompanyName = ""
                    showingAddAlert = true
                } label: {
                    Label("Add Company", systemImage: "plus")
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "building.2")
                        .foregroundStyle(Theme.accent)
                    Text(companyManager?.activeCompany?.name ?? "No Company")
                        .fontWeight(.bold)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 19.2))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .alert("New Company", isPresented: $showingAddAlert) {
            TextField("Company Name", text: $newCompanyName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                let trimmed = newCompanyName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                if let manager = companyManager {
                    let company = manager.createCompany(name: trimmed)
                    manager.switchTo(company)
                }
            }
        } message: {
            Text("Enter a name for the new company.")
        }
    }
}
