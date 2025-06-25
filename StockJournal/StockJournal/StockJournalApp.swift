//
//  StockJournalApp.swift
//  StockJournal
//
//  Created by Jal Shrestha on 6/24/25.
//

import SwiftUI
import CoreData

@main
struct StockJournalApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .environmentObject(portfolioViewModel)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    portfolioViewModel.setContext(persistenceController.container.viewContext)
                }
        }
    }
}
