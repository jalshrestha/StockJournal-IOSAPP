import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var accentColor: AccentColorOption = .blue
    
    enum AccentColorOption: String, CaseIterable {
        case blue = "Blue"
        case green = "Green"
        case orange = "Orange"
        case purple = "Purple"
        case red = "Red"
        case pink = "Pink"
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            case .red: return .red
            case .pink: return .pink
            }
        }
    }
    
    init() {
        loadSettings()
    }
    
    // MARK: - Colors
    
    var primaryColor: Color {
        accentColor.color
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(UIColor.systemBackground)
    }
    
    var secondaryBackgroundColor: Color {
        isDarkMode ? Color(red: 0.16, green: 0.16, blue: 0.18) : Color(UIColor.systemGray6)
    }
    
    var cardBackgroundColor: Color {
        isDarkMode ? Color(red: 0.19, green: 0.19, blue: 0.21) : Color.white
    }
    
    var textPrimaryColor: Color {
        isDarkMode ? Color(red: 0.98, green: 0.98, blue: 0.98) : Color.black
    }
    
    var textSecondaryColor: Color {
        isDarkMode ? Color(red: 0.68, green: 0.68, blue: 0.70) : Color(UIColor.systemGray)
    }
    
    var positiveColor: Color {
        isDarkMode ? Color(red: 0.20, green: 0.78, blue: 0.35) : Color.green
    }
    
    var negativeColor: Color {
        isDarkMode ? Color(red: 1.0, green: 0.27, blue: 0.23) : Color.red
    }
    
    var neutralColor: Color {
        isDarkMode ? Color(red: 0.56, green: 0.56, blue: 0.58) : Color.gray
    }
    
    // MARK: - Fonts
    
    var headlineFont: Font {
        .headline.weight(.semibold)
    }
    
    var bodyFont: Font {
        .body
    }
    
    var captionFont: Font {
        .caption
    }
    
    var titleFont: Font {
        .title.weight(.bold)
    }
    
    // MARK: - Spacing
    
    let smallSpacing: CGFloat = 8
    let mediumSpacing: CGFloat = 16
    let largeSpacing: CGFloat = 24
    
    // MARK: - Corner Radius
    
    let cardCornerRadius: CGFloat = 12
    let buttonCornerRadius: CGFloat = 8
    
    // MARK: - Methods
    
    func colorForPerformance(_ value: Double) -> Color {
        if value > 0 {
            return positiveColor
        } else if value < 0 {
            return negativeColor
        } else {
            return neutralColor
        }
    }
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }
    
    func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveSettings()
    }
    
    func setAccentColor(_ color: AccentColorOption) {
        accentColor = color
        saveSettings()
    }
    
    private func loadSettings() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        if let colorString = UserDefaults.standard.string(forKey: "accentColor"),
           let color = AccentColorOption(rawValue: colorString) {
            accentColor = color
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor")
    }
}

// MARK: - View Modifiers

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }
    
    func themedButton(style: ThemedButtonStyle.ButtonStyle = .primary) -> some View {
        modifier(ThemedButtonModifier(style: style))
    }
}

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(themeManager.cardCornerRadius)
            .shadow(color: Color.black.opacity(themeManager.isDarkMode ? 0.3 : 0.1), radius: themeManager.isDarkMode ? 8 : 2, x: 0, y: themeManager.isDarkMode ? 4 : 1)
    }
}

struct ThemedButtonModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let style: ThemedButtonStyle.ButtonStyle
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColorForStyle())
            .foregroundColor(foregroundColorForStyle())
            .cornerRadius(themeManager.buttonCornerRadius)
    }
    
    private func backgroundColorForStyle() -> Color {
        switch style {
        case .primary:
            return themeManager.primaryColor
        case .secondary:
            return themeManager.secondaryBackgroundColor
        case .destructive:
            return themeManager.negativeColor
        }
    }
    
    private func foregroundColorForStyle() -> Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return themeManager.primaryColor
        }
    }
}

struct ThemedButtonStyle {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
} 