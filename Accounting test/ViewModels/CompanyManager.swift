//
//  CompanyManager.swift
//  Accounting test
//
//  Created by gary turnbull on 2/9/26.
//

import Foundation
import SwiftData

@Observable
final class CompanyManager {
    var activeCompany: Company?

    private var modelContext: ModelContext

    private static let activeCompanyIDKey = "activeCompanyID"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func bootstrap() {
        let defaultCompany = SeedData.ensureDefaultCompanyExists(context: modelContext)

        if let savedID = UserDefaults.standard.string(forKey: Self.activeCompanyIDKey),
           let uuid = UUID(uuidString: savedID) {
            let descriptor = FetchDescriptor<Company>()
            let companies = (try? modelContext.fetch(descriptor)) ?? []
            activeCompany = companies.first(where: { $0.id == uuid }) ?? defaultCompany
        } else {
            activeCompany = defaultCompany
        }

        persistActiveCompanyID()
    }

    func createCompany(name: String) -> Company {
        let company = Company(name: name)
        modelContext.insert(company)
        SeedData.seedAccounts(for: company, context: modelContext)
        try? modelContext.save()
        return company
    }

    func switchTo(_ company: Company) {
        activeCompany = company
        persistActiveCompanyID()
    }

    func fetchAllCompanies() -> [Company] {
        let descriptor = FetchDescriptor<Company>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func persistActiveCompanyID() {
        if let id = activeCompany?.id.uuidString {
            UserDefaults.standard.set(id, forKey: Self.activeCompanyIDKey)
        }
    }
}
