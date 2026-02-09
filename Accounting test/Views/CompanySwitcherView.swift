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
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                    Text(companyManager?.activeCompany?.name ?? "No Company")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
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
