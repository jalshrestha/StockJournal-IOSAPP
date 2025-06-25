//
//  Persistence.swift
//  StockJournal
//
//  Created by Jal Shrestha on 6/24/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let samplePosition = Position(context: viewContext)
        samplePosition.id = UUID()
        samplePosition.stockSymbol = "AAPL"
        samplePosition.stockName = "Apple Inc."
        samplePosition.quantity = 100
        samplePosition.buyPrice = 150.0
        samplePosition.currentPrice = 155.0
        samplePosition.stopLoss = 140.0
        samplePosition.priceTarget = 170.0
        samplePosition.thesis = "Long-term growth potential with iPhone and services revenue"
        samplePosition.dateAdded = Date()
        samplePosition.isActive = true
        samplePosition.sector = "Technology"

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StockJournal")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
