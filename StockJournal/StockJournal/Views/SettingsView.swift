import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(themeManager.primaryColor)
                        
                        Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                    }
                    
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(themeManager.primaryColor)
                        
                        Text("Accent Color")
                        
                        Spacer()
                        
                        Menu {
                            ForEach(ThemeManager.AccentColorOption.allCases, id: \.self) { color in
                                Button(color.rawValue) {
                                    themeManager.setAccentColor(color)
                                }
                            }
                        } label: {
                            Circle()
                                .fill(themeManager.primaryColor)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                
                Section("Data") {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(themeManager.primaryColor)
                        
                        Button("Export Portfolio Data") {
                            exportData()
                        }
                        .foregroundColor(themeManager.textPrimaryColor)
                    }
                    
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeManager.primaryColor)
                        
                        Button("Refresh Prices") {
                            portfolioViewModel.refreshPrices()
                        }
                        .foregroundColor(themeManager.textPrimaryColor)
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(themeManager.primaryColor)
                        
                        Text("Version")
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                    
                    HStack {
                        Image(systemName: "chart.pie")
                            .foregroundColor(themeManager.primaryColor)
                        
                        Text("Stock Journal")
                        
                        Spacer()
                        
                        Text("Portfolio Tracker")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func exportData() {
        let csvData = portfolioViewModel.exportData()
        
        // In a real app, you would present a share sheet here
        // For now, we'll just print to console
        print("CSV Data:")
        print(csvData)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(PortfolioViewModel())
} 