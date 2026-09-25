import Foundation
import SwiftData

enum StageJSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let prettyEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

@Model
final class WorkspaceRecord {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var snapshotJSON: Data

    init(id: UUID, name: String, createdAt: Date, updatedAt: Date, snapshotJSON: Data) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.snapshotJSON = snapshotJSON
    }
}

@MainActor
@Observable
final class StageStore {
    private(set) var workspaces: [Workspace] = []
    private(set) var loadError: String?
    var pendingCapture = false
    var pendingRestoreID: UUID?
    private let container: ModelContainer
    private let context: ModelContext

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Stage", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
            let storeURL = support.appendingPathComponent("workspaces.store")
            let configuration = ModelConfiguration("Stage", url: storeURL)
            container = try ModelContainer(for: WorkspaceRecord.self, configurations: configuration)
            loadError = nil
        } catch {
            container = try! ModelContainer(
                for: WorkspaceRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            loadError = "Workspaces could not be saved to disk, so they will last until you quit Stage."
        }
        context = container.mainContext
        load()
    }

    func load() {
        let descriptor = FetchDescriptor<WorkspaceRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let records = (try? context.fetch(descriptor)) ?? []
        workspaces = records.compactMap { try? StageJSON.decoder.decode(Workspace.self, from: $0.snapshotJSON) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ workspace: Workspace) {
        var snapshot = workspace
        snapshot.updatedAt = Date()
        guard let data = try? StageJSON.encoder.encode(snapshot) else { return }
        if let existing = record(id: snapshot.id) {
            existing.name = snapshot.name
            existing.updatedAt = snapshot.updatedAt
            existing.snapshotJSON = data
        } else {
            context.insert(WorkspaceRecord(
                id: snapshot.id,
                name: snapshot.name,
                createdAt: snapshot.createdAt,
                updatedAt: snapshot.updatedAt,
                snapshotJSON: data
            ))
        }
        try? context.save()
        if let index = workspaces.firstIndex(where: { $0.id == snapshot.id }) {
            workspaces[index] = snapshot
        } else {
            workspaces.insert(snapshot, at: 0)
        }
    }

    func rename(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var workspace = workspaces.first(where: { $0.id == id }) else { return }
        workspace.name = trimmed
        save(workspace)
    }

    func markRestored(id: UUID) {
        guard var workspace = workspaces.first(where: { $0.id == id }) else { return }
        workspace.lastRestoredAt = Date()
        save(workspace)
    }

    func delete(id: UUID) {
        if let existing = record(id: id) {
            context.delete(existing)
            try? context.save()
        }
        workspaces.removeAll { $0.id == id }
    }

    func requestCapture() {
        pendingCapture = true
    }

    func requestRestore(id: UUID) {
        pendingRestoreID = id
    }

    private func record(id: UUID) -> WorkspaceRecord? {
        let target = id
        let descriptor = FetchDescriptor<WorkspaceRecord>(predicate: #Predicate { $0.id == target })
        return try? context.fetch(descriptor).first
    }
}
