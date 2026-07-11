import CoreData

struct PersistenceController {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NutritionTracker")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        }

        // 覆盖安装新版 IPA 时允许 Core Data 自动加入新实体并保留旧记录。
        for description in container.persistentStoreDescriptions {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        var loadingError: Error?
        container.loadPersistentStores { _, error in
            loadingError = error
        }
        precondition(
            loadingError == nil,
            "无法加载本地数据库：\(loadingError?.localizedDescription ?? "未知错误")"
        )

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
