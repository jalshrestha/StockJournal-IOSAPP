//
//  ContentView.swift
//  StockJournal
//
//  Created by Jal Shrestha on 6/24/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            PortfolioView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Portfolio")
                }
            
            PositionsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Positions")
                }
            
            AddPositionView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(themeManager.primaryColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(PortfolioViewModel())
}
