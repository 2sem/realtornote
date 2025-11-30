import Foundation
import CoreData
import SwiftData
import StringLogger

@MainActor
class DataMigrationManager: ObservableObject {
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus: MigrationStatus = .idle
    @Published var currentStep: String = ""
    
    enum MigrationStatus {
        case idle
        case checking
        case migrating
        case completed
        case failed(Error)
    }
    
    private let coreDataController = RNModelController.shared
    
    var isMigrationCompleted: Bool {
        get { LSDefaults.dataMigrationCompleted }
        set { LSDefaults.dataMigrationCompleted = newValue }
    }
    
    func checkAndMigrateIfNeeded() async -> Bool {
        "[DataMigration] checkAndMigrateIfNeeded started".trace()
        
        if isMigrationCompleted {
            "[DataMigration] Migration already completed".trace()
            migrationStatus = .completed
            currentStep = "마이그레이션이 이미 완료되었습니다."
            return false
        }
        
        migrationStatus = .checking
        currentStep = "Core Data를 확인하는 중..."
        "[DataMigration] Checking for Core Data".trace()
        
        guard await hasCoreData() else {
            "[DataMigration] No Core Data found, migration not needed".trace()
            migrationStatus = .completed
            currentStep = "마이그레이션이 필요하지 않습니다."
            isMigrationCompleted = true
            return false
        }
        
        migrationStatus = .migrating
        currentStep = "마이그레이션을 시작합니다..."
        "[DataMigration] Core Data found, starting migration".trace()
        
        do {
            try await performMigration()
            "[DataMigration] Migration completed successfully".trace()
            migrationStatus = .completed
            currentStep = "마이그레이션이 완료되었습니다."
            isMigrationCompleted = true
            return true
        } catch {
            "[DataMigration] Migration failed: \(error.localizedDescription)".trace()
            migrationStatus = .failed(error)
            currentStep = "마이그레이션 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    private func hasCoreData() async -> Bool {
        "[DataMigration] Checking Core Data entities".trace()
        let context = coreDataController.context
        return await withCheckedContinuation { continuation in
            context.perform {
                let favoriteRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: RNModelController.EntityNames.RNFavoriteInfo)
                favoriteRequest.fetchLimit = 1
                
                let alarmRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: RNModelController.EntityNames.alarm)
                alarmRequest.fetchLimit = 1
                
                do {
                    let favoriteCount = try context.count(for: favoriteRequest)
                    let alarmCount = try context.count(for: alarmRequest)
                    let hasData = favoriteCount > 0 || alarmCount > 0
                    "[DataMigration] Core Data check - favorites: \(favoriteCount), alarms: \(alarmCount), hasData: \(hasData)".trace()
                    continuation.resume(returning: hasData)
                } catch {
                    "[DataMigration] Error checking Core Data: \(error)".trace()
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func performMigration() async throws {
        "[DataMigration] performMigration started".trace()
        
        guard let modelContainer = try? ModelContainer(for: Subject.self, Chapter.self, Part.self, Favorite.self, Alarm.self) else {
            "[DataMigration] Failed to create ModelContainer".trace()
            throw MigrationError.modelContainerCreationFailed
        }
        
        "[DataMigration] ModelContainer created successfully".trace()
        let modelContext = modelContainer.mainContext
        
        currentStep = "엑셀 데이터를 SwiftData로 동기화하는 중..."
        migrationProgress = 0.1
        
        let syncService = ExcelSyncService(context: modelContext)
        
        try await syncService.syncIfNeeded(force: true)
        
        currentStep = "즐겨찾기 데이터를 마이그레이션하는 중..."
        migrationProgress = 0.3
        "[DataMigration] Starting favorites migration".trace()
        
        try await migrateFavorites(with: modelContext)
        "[DataMigration] Favorites migration completed".trace()
        
        currentStep = "알람 데이터를 마이그레이션하는 중..."
        migrationProgress = 0.5
        "[DataMigration] Starting alarms migration".trace()
        
        try await migrateAlarms(with: modelContext)
        "[DataMigration] Alarms migration completed".trace()

        currentStep = "마이그레이션을 완료하는 중..."
        migrationProgress = 0.9
        "[DataMigration] Starting cleanup".trace()

        await cleanupCoreDataFiles()
        "[DataMigration] Cleanup completed".trace()
        
        migrationProgress = 1.0
    }
    
    private func migrateFavorites(with modelContext: ModelContext) async throws {
        "[DataMigration] Fetching Core Data favorites".trace()
        let context = coreDataController.context
        let coreDataFavorites = try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<RNFavoriteInfo> = NSFetchRequest(entityName: RNModelController.EntityNames.RNFavoriteInfo)
                
                do {
                    let favorites = try context.fetch(fetchRequest)
                    "[DataMigration] Fetched \(favorites.count) favorites from Core Data".trace()
                    continuation.resume(returning: favorites)
                } catch {
                    "[DataMigration] Error fetching favorites: \(error)".trace()
                    continuation.resume(throwing: error)
                }
            }
        }

        let maxProgress = 0.5
        let totalItems = coreDataFavorites.count
        "[DataMigration] Starting migration of \(totalItems) favorites".trace()

        for (i, favorite) in coreDataFavorites.enumerated() {
            if let partNo = favorite.part?.no {
                let partId = Int(partNo)
                
                let descriptor = FetchDescriptor<Part>(predicate: #Predicate { part in
                    part.id == partId
                })
                
                if let parts = try? modelContext.fetch(descriptor), let part = parts.first {
                    let swiftDataFavorite = Favorite(no: favorite.no, part: part)
                    modelContext.insert(swiftDataFavorite)
                } else {
                    "[DataMigration] Warning: Part not found for favorite with partId: \(partId)".trace()
                }
            }
            
            if (i + 1) % 10 == 0 || i == totalItems - 1 {
                let progress = 0.3 + (Double(i + 1) / Double(totalItems)) * 0.2
                await MainActor.run {
                    self.migrationProgress = min(progress, maxProgress)
                }
            }
        }
        
        try modelContext.save()
        "[DataMigration] Saved \(totalItems) favorites to SwiftData".trace()
    }
    
    private func migrateAlarms(with modelContext: ModelContext) async throws {
        "[DataMigration] Fetching Core Data alarms".trace()
        let context = coreDataController.context
        let coreDataAlarms = try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let fetchRequest: NSFetchRequest<RNAlarmModel> = NSFetchRequest(entityName: RNModelController.EntityNames.alarm)
                
                do {
                    let alarms = try context.fetch(fetchRequest)
                    "[DataMigration] Fetched \(alarms.count) alarms from Core Data".trace()
                    continuation.resume(returning: alarms)
                } catch {
                    "[DataMigration] Error fetching alarms: \(error)".trace()
                    continuation.resume(throwing: error)
                }
            }
        }

        let totalItems = coreDataAlarms.count
        "[DataMigration] Starting migration of \(totalItems) alarms".trace()

        for (i, alarm) in coreDataAlarms.enumerated() {
            var subject: Subject? = nil
            
            if let subjectNo = alarm.subject?.no {
                let subjectId = Int(subjectNo)
                
                let descriptor = FetchDescriptor<Subject>(predicate: #Predicate { subject in
                    subject.id == subjectId
                })
                
                if let subjects = try? modelContext.fetch(descriptor) {
                    subject = subjects.first
                } else {
                    "[DataMigration] Warning: Subject not found for alarm with subjectId: \(subjectId)".trace()
                }
            }
            
            let swiftDataAlarm = Alarm(
                id: alarm.id,
                enabled: alarm.enabled,
                time: alarm.time,
                title: alarm.title ?? "",
                weekdays: alarm.weekdays,
                subject: subject
            )
            modelContext.insert(swiftDataAlarm)
            
            if (i + 1) % 10 == 0 || i == totalItems - 1 {
                let progress = 0.5 + (Double(i + 1) / Double(totalItems)) * 0.4
                await MainActor.run {
                    self.migrationProgress = min(progress, 0.9)
                }
            }
        }
        
        try modelContext.save()
        "[DataMigration] Saved \(totalItems) alarms to SwiftData".trace()
    }
    
    private func cleanupCoreDataFiles() async {
        "[DataMigration] Starting Core Data files cleanup".trace()
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let docUrl = urls.last {
            let sqliteURL = docUrl.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite")
            let sqliteShmURL = docUrl.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite-shm")
            let sqliteWalURL = docUrl.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite-wal")
            
            try? FileManager.default.removeItem(at: sqliteURL)
            try? FileManager.default.removeItem(at: sqliteShmURL)
            try? FileManager.default.removeItem(at: sqliteWalURL)
            
            "[DataMigration] Core Data files cleanup completed".trace()
        } else {
            "[DataMigration] Warning: Could not get document directory for cleanup".trace()
        }
    }
}

enum MigrationError: LocalizedError {
    case modelContainerCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelContainerCreationFailed:
            return "SwiftData 모델 컨테이너 생성에 실패했습니다."
        }
    }
}
