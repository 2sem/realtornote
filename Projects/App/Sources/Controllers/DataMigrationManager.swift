import Foundation
import CoreData
import SwiftData

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
    private let migrationCompletedKey = "DataMigrationCompleted"
    
    var isMigrationCompleted: Bool {
        get { LSDefaults.dataMigrationCompleted }
        set { LSDefaults.dataMigrationCompleted = newValue }
    }
    
    func checkAndMigrateIfNeeded() async -> Bool {
        if isMigrationCompleted {
            migrationStatus = .completed
            currentStep = "마이그레이션이 이미 완료되었습니다."
            return false
        }
        
        migrationStatus = .checking
        currentStep = "Core Data를 확인하는 중..."
        
        guard await hasCoreData() else {
            migrationStatus = .completed
            currentStep = "마이그레이션이 필요하지 않습니다."
            isMigrationCompleted = true
            return false
        }
        
        migrationStatus = .migrating
        currentStep = "마이그레이션을 시작합니다..."
        
        do {
            try await performMigration()
            migrationStatus = .completed
            currentStep = "마이그레이션이 완료되었습니다."
            isMigrationCompleted = true
            return true
        } catch {
            migrationStatus = .failed(error)
            currentStep = "마이그레이션 실패: \(error.localizedDescription)"
            return false
        }
    }
    
    private func hasCoreData() async -> Bool {
        return await withCheckedContinuation { continuation in
            coreDataController.context.perform {
                let favoriteRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: RNModelController.EntityNames.RNFavoriteInfo)
                favoriteRequest.fetchLimit = 1
                
                let alarmRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: RNModelController.EntityNames.alarm)
                alarmRequest.fetchLimit = 1
                
                do {
                    let favoriteCount = try self.coreDataController.context.count(for: favoriteRequest)
                    let alarmCount = try self.coreDataController.context.count(for: alarmRequest)
                    continuation.resume(returning: favoriteCount > 0 || alarmCount > 0)
                } catch {
                    print("Core Data 확인 중 오류: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func performMigration() async throws {
        currentStep = "즐겨찾기 데이터를 마이그레이션하는 중..."
        migrationProgress = 0.2
        
        let favorites = try await fetchCoreDataFavorites()
        
        currentStep = "알람 데이터를 마이그레이션하는 중..."
        migrationProgress = 0.4
        
        let alarms = try await fetchCoreDataAlarms()
        
        currentStep = "SwiftData로 변환하는 중..."
        migrationProgress = 0.6
        
        try await convertAndSaveToSwiftData(favorites: favorites, alarms: alarms)
        
        migrationProgress = 1.0
    }
    
    private func fetchCoreDataFavorites() async throws -> [RNFavoriteInfo] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataController.context.perform {
                let fetchRequest: NSFetchRequest<RNFavoriteInfo> = NSFetchRequest(entityName: RNModelController.EntityNames.RNFavoriteInfo)
                
                do {
                    let favorites = try self.coreDataController.context.fetch(fetchRequest)
                    continuation.resume(returning: favorites)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchCoreDataAlarms() async throws -> [RNAlarmModel] {
        return try await withCheckedThrowingContinuation { continuation in
            coreDataController.context.perform {
                let fetchRequest: NSFetchRequest<RNAlarmModel> = NSFetchRequest(entityName: RNModelController.EntityNames.alarm)
                
                do {
                    let alarms = try self.coreDataController.context.fetch(fetchRequest)
                    continuation.resume(returning: alarms)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func convertAndSaveToSwiftData(favorites: [RNFavoriteInfo], alarms: [RNAlarmModel]) async throws {
        await MainActor.run {
            currentStep = "데이터를 변환하는 중..."
            migrationProgress = 0.7
        }
        
        guard let modelContainer = try? ModelContainer(for: Favorite.self, Alarm.self) else {
            throw MigrationError.modelContainerCreationFailed
        }
        
        let context = modelContainer.mainContext
        let totalItems = favorites.count + alarms.count
        var processedItems = 0
        
        for favorite in favorites {
            let swiftDataFavorite = Favorite(from: favorite)
            context.insert(swiftDataFavorite)
            
            processedItems += 1
            let progress = 0.7 + (Double(processedItems) / Double(totalItems) * 0.2)
            await MainActor.run {
                migrationProgress = min(progress, 0.9)
            }
            
            if processedItems % 10 == 0 {
                try? context.save()
            }
        }
        
        for alarm in alarms {
            let swiftDataAlarm = Alarm(from: alarm)
            context.insert(swiftDataAlarm)
            
            processedItems += 1
            let progress = 0.7 + (Double(processedItems) / Double(totalItems) * 0.2)
            await MainActor.run {
                migrationProgress = min(progress, 0.9)
            }
            
            if processedItems % 10 == 0 {
                try? context.save()
            }
        }
        
        try context.save()
        
        await MainActor.run {
            currentStep = "마이그레이션을 완료하는 중..."
            migrationProgress = 0.95
        }
        
        await cleanupCoreDataFiles()
        
        await MainActor.run {
            migrationProgress = 1.0
        }
    }
    
    private func cleanupCoreDataFiles() async {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let docUrl = urls.last {
            let sqliteURL = docUrl.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite")
            let sqliteShmURL = docUrl.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite-shm")
            let sqliteWalURL = docUrl.appendingPathComponent(RNModelController.FileName).appendingPathExtension("sqlite-wal")
            
            try? FileManager.default.removeItem(at: sqliteURL)
            try? FileManager.default.removeItem(at: sqliteShmURL)
            try? FileManager.default.removeItem(at: sqliteWalURL)
            
            print("Core Data 파일 정리 완료")
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
