import Foundation
import SwiftData

/// Version 1 of Reassured's database. When a model changes in a future release, add
/// ReassuredSchemaV2 (with copies of the changed models) and a migration stage below,
/// so audits people already have keep loading after the update.
enum ReassuredSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Audit.self, ControlResult.self, Evidence.self, Finding.self,
         RemediationTask.self, LockerItem.self, Client.self]
    }
}

enum ReassuredMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ReassuredSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

enum ReassuredStore {
    /// Opens the database. `inMemory` is for demo data and tests, and never touches saved audits.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: ReassuredSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, migrationPlan: ReassuredMigrationPlan.self,
                                  configurations: configuration)
    }
}
