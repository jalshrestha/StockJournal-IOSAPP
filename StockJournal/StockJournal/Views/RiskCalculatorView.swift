import SwiftUI

struct RiskCalculatorView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    let buyPrice: Double
    let stopLoss: Double
    let onCalculation: (RiskCalculation) -> Void
    
    @State private var portfolioSize = ""
    @State private var riskPercentage = "2"
    @State private var calculation: RiskCalculation?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Input Section
                    inputSection
                    
                    // Calculation Results
                    if let calc = calculation {
                        resultsSection(calc)
                    }
                    
                    // Risk Guidelines
                    guidelinesSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Risk Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let calc = calculation {
                            onCalculation(calc)
                        }
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .onAppear {
            calculateRisk()
        }
        .onChange(of: portfolioSize) { _, _ in calculateRisk() }
        .onChange(of: riskPercentage) { _, _ in calculateRisk() }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkerboard")
                .font(.system(size: 40))
                .foregroundColor(themeManager.primaryColor)
            
            Text("Position Size Calculator")
                .font(.title2.weight(.semibold))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Calculate optimal position size based on your risk tolerance")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Parameters")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            VStack(spacing: 16) {
                // Current Position Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Position")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Buy Price")
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondaryColor)
                            Text(String(format: "$%.2f", buyPrice))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(themeManager.textPrimaryColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Stop Loss")
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondaryColor)
                            Text(String(format: "$%.2f", stopLoss))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(themeManager.negativeColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Risk Per Share")
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondaryColor)
                            Text(String(format: "$%.2f", abs(buyPrice - stopLoss)))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(themeManager.neutralColor)
                        }
                    }
                    .padding(16)
                    .background(themeManager.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                
                // Portfolio Size Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Portfolio Value")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    TextField("Enter your total portfolio value", text: $portfolioSize)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(themeManager.secondaryBackgroundColor)
                        .cornerRadius(8)
                }
                
                // Risk Percentage Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Risk Per Trade (%)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    HStack {
                        TextField("2", text: $riskPercentage)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(themeManager.secondaryBackgroundColor)
                            .cornerRadius(8)
                        
                        Text("%")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                    
                    // Quick risk percentage buttons
                    HStack(spacing: 8) {
                        ForEach(["1", "2", "3", "5"], id: \.self) { percentage in
                            Button(percentage + "%") {
                                riskPercentage = percentage
                            }
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(riskPercentage == percentage ? themeManager.primaryColor : themeManager.secondaryBackgroundColor)
                            .foregroundColor(riskPercentage == percentage ? .white : themeManager.textSecondaryColor)
                            .cornerRadius(6)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Results Section
    
    private func resultsSection(_ calc: RiskCalculation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Position")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            // Main Results
            VStack(spacing: 16) {
                // Position Size
                HStack {
                    VStack(alignment: .leading) {
                        Text("Position Size")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Text("\(Int(calc.recommendedShares)) shares")
                            .font(.title.weight(.bold))
                            .foregroundColor(themeManager.primaryColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Total Investment")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Text(String(format: "$%.2f", calc.totalInvestment))
                            .font(.title2.weight(.semibold))
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                }
                .padding(16)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(12)
                
                // Risk Metrics Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    RiskMetricView(
                        title: "Max Risk Amount",
                        value: String(format: "$%.2f", calc.maxRiskAmount),
                        color: themeManager.negativeColor,
                        icon: "exclamationmark.shield"
                    )
                    
                    RiskMetricView(
                        title: "Portfolio Risk",
                        value: String(format: "%.1f%%", calc.portfolioRiskPercent),
                        color: themeManager.neutralColor,
                        icon: "percent"
                    )
                    
                    RiskMetricView(
                        title: "Risk Per Share",
                        value: String(format: "$%.2f", calc.riskPerShare),
                        color: themeManager.textSecondaryColor,
                        icon: "dollarsign.circle"
                    )
                    
                    RiskMetricView(
                        title: "Portfolio %",
                        value: String(format: "%.1f%%", calc.portfolioAllocation),
                        color: themeManager.positiveColor,
                        icon: "chart.pie"
                    )
                }
            }
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Guidelines Section
    
    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Management Guidelines")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            VStack(alignment: .leading, spacing: 12) {
                GuidelineRow(
                    icon: "1.circle.fill",
                    title: "Conservative Risk",
                    description: "Risk 1-2% per trade for steady growth",
                    color: themeManager.positiveColor
                )
                
                GuidelineRow(
                    icon: "2.circle.fill",
                    title: "Moderate Risk",
                    description: "Risk 2-3% per trade for balanced approach",
                    color: themeManager.neutralColor
                )
                
                GuidelineRow(
                    icon: "3.circle.fill",
                    title: "Aggressive Risk",
                    description: "Risk 3-5% per trade for growth focus",
                    color: themeManager.primaryColor
                )
                
                GuidelineRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "High Risk Warning",
                    description: "Never risk more than 5% on a single trade",
                    color: themeManager.negativeColor
                )
            }
        }
        .padding(20)
        .themedCard()
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func calculateRisk() {
        guard let portfolioValue = Double(portfolioSize),
              let riskPercent = Double(riskPercentage),
              portfolioValue > 0,
              riskPercent > 0 else {
            calculation = nil
            return
        }
        
        let riskPerShare = abs(buyPrice - stopLoss)
        let maxRiskAmount = portfolioValue * (riskPercent / 100)
        let recommendedShares = maxRiskAmount / riskPerShare
        let totalInvestment = recommendedShares * buyPrice
        let portfolioAllocation = (totalInvestment / portfolioValue) * 100
        
        calculation = RiskCalculation(
            recommendedShares: recommendedShares,
            totalInvestment: totalInvestment,
            maxRiskAmount: maxRiskAmount,
            riskPerShare: riskPerShare,
            portfolioRiskPercent: riskPercent,
            portfolioAllocation: portfolioAllocation
        )
    }
}

// MARK: - Supporting Views

struct RiskMetricView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(color)
            }
        }
        .padding(12)
        .background(themeManager.secondaryBackgroundColor)
        .cornerRadius(8)
    }
}

struct GuidelineRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Model

struct RiskCalculation {
    let recommendedShares: Double
    let totalInvestment: Double
    let maxRiskAmount: Double
    let riskPerShare: Double
    let portfolioRiskPercent: Double
    let portfolioAllocation: Double
}

#Preview {
    RiskCalculatorView(
        buyPrice: 150.0,
        stopLoss: 140.0,
        onCalculation: { _ in }
    )
    .environmentObject(ThemeManager())
} 