import SwiftUI

struct AddPositionView: View {
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var stockSymbol = ""
    @State private var stockName = ""
    @State private var quantity = ""
    @State private var buyPrice = ""
    @State private var currentPrice = ""
    @State private var stopLoss = ""
    @State private var priceTarget = ""
    @State private var thesis = ""
    @State private var sector = ""
    @State private var showingStockSearch = false
    @State private var selectedStock: Stock?
    @State private var showingRiskCalculator = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Stock Selection Card
                    stockSelectionCard
                    
                    // Position Details Card
                    positionDetailsCard
                    
                    // Risk Analysis Card
                    riskAnalysisCard
                    
                    // Investment Thesis Card
                    investmentThesisCard
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Add Position")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingStockSearch) {
            StockSearchView(onStockSelected: { stock in
                selectStock(stock)
                showingStockSearch = false
            })
        }
        .sheet(isPresented: $showingRiskCalculator) {
            RiskCalculatorView(
                buyPrice: Double(buyPrice) ?? 0,
                stopLoss: Double(stopLoss) ?? 0,
                onCalculation: { _ in }
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(themeManager.primaryColor)
            
            Text("Add New Position")
                .font(.title2.weight(.semibold))
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Build your portfolio with smart risk management")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Stock Selection Card
    
    private var stockSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stock Selection")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            // Stock Search Button
            Button(action: { showingStockSearch = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let stock = selectedStock {
                            Text(stock.symbol)
                                .font(.headline.weight(.bold))
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Text(stock.name)
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondaryColor)
                            
                            HStack {
                                Text(stock.formattedPrice)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: stock.change >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption2)
                                    Text(stock.formattedChangePercent)
                                        .font(.caption)
                                }
                                .foregroundColor(themeManager.colorForPerformance(stock.change))
                            }
                        } else {
                            Text("Search for a stock...")
                                .font(.headline)
                                .foregroundColor(themeManager.textSecondaryColor)
                            
                            Text("Tap to search by symbol or company name")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(themeManager.primaryColor)
                }
                .padding(16)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if let stock = selectedStock {
                // Auto-filled information
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Sector", value: stock.sector)
                    InfoRow(title: "Current Price", value: stock.formattedPrice)
                    InfoRow(title: "24h Change", value: stock.formattedChangePercent)
                }
            }
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Position Details Card
    
    private var positionDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Position Details")
                    .font(themeManager.headlineFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                Button("Risk Calculator") {
                    showingRiskCalculator = true
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(6)
                .disabled(selectedStock == nil)
            }
            
            VStack(spacing: 12) {
                CustomTextField(title: "Quantity", value: $quantity, placeholder: "Number of shares", keyboardType: .decimalPad)
                
                CustomTextField(title: "Buy Price", value: $buyPrice, placeholder: selectedStock?.formattedPrice ?? "$0.00", keyboardType: .decimalPad)
                
                CustomTextField(title: "Stop Loss", value: $stopLoss, placeholder: "Risk management level", keyboardType: .decimalPad)
                
                CustomTextField(title: "Price Target", value: $priceTarget, placeholder: "Profit target", keyboardType: .decimalPad)
            }
            
            if !quantity.isEmpty && !buyPrice.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    HStack {
                        Text("Total Investment")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        
                        Spacer()
                        
                        Text(calculateTotalInvestment())
                            .font(.headline.weight(.semibold))
                            .foregroundColor(themeManager.primaryColor)
                    }
                    
                    if !stopLoss.isEmpty {
                        HStack {
                            Text("Risk Amount")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondaryColor)
                            
                            Spacer()
                            
                            Text(calculateRiskAmount())
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(themeManager.negativeColor)
                        }
                    }
                }
            }
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Risk Analysis Card
    
    private var riskAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Analysis")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            if !buyPrice.isEmpty && !stopLoss.isEmpty && !priceTarget.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    RiskMetricCard(
                        title: "Risk:Reward",
                        value: calculateRiskRewardRatio(),
                        color: themeManager.primaryColor,
                        icon: "scale.3d"
                    )
                    
                    RiskMetricCard(
                        title: "Stop Loss %",
                        value: calculateStopLossPercent(),
                        color: themeManager.negativeColor,
                        icon: "shield.fill"
                    )
                    
                    RiskMetricCard(
                        title: "Target %",
                        value: calculateTargetPercent(),
                        color: themeManager.positiveColor,
                        icon: "target"
                    )
                    
                    RiskMetricCard(
                        title: "Risk Level",
                        value: getRiskLevel(),
                        color: getRiskLevelColor(),
                        icon: "exclamationmark.triangle.fill"
                    )
                }
            } else {
                Text("Enter position details to see risk analysis")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .padding()
            }
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Investment Thesis Card
    
    private var investmentThesisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Investment Thesis")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            TextField("Why are you investing in this stock? What's your thesis?", text: $thesis, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
                .lineLimit(4...8)
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Add Position") {
                addPosition()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? themeManager.primaryColor : themeManager.neutralColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline.weight(.semibold))
            .disabled(!isFormValid)
            
            Button("Clear Form") {
                clearForm()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.secondaryBackgroundColor)
            .foregroundColor(themeManager.primaryColor)
            .cornerRadius(12)
            .font(.headline.weight(.semibold))
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        selectedStock != nil &&
        !quantity.isEmpty &&
        !buyPrice.isEmpty &&
        !stopLoss.isEmpty &&
        !priceTarget.isEmpty &&
        !thesis.isEmpty
    }
    
    private func selectStock(_ stock: Stock) {
        selectedStock = stock
        stockSymbol = stock.symbol
        stockName = stock.name
        sector = stock.sector
        currentPrice = String(format: "%.2f", stock.currentPrice)
        
        // Auto-suggest buy price based on current price
        if buyPrice.isEmpty {
            buyPrice = String(format: "%.2f", stock.currentPrice)
        }
    }
    
    private func addPosition() {
        guard let stock = selectedStock,
              let quantityValue = Double(quantity),
              let buyPriceValue = Double(buyPrice),
              let stopLossValue = Double(stopLoss),
              let priceTargetValue = Double(priceTarget) else {
            return
        }
        
        portfolioViewModel.addPosition(
            symbol: stock.symbol,
            name: stock.name,
            quantity: quantityValue,
            buyPrice: buyPriceValue,
            stopLoss: stopLossValue,
            priceTarget: priceTargetValue,
            thesis: thesis,
            sector: stock.sector
        )
        
        clearForm()
        
        // Show success feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Auto-clear form after successful addition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Form is already cleared above
        }
    }
    
    private func clearForm() {
        selectedStock = nil
        stockSymbol = ""
        stockName = ""
        quantity = ""
        buyPrice = ""
        currentPrice = ""
        stopLoss = ""
        priceTarget = ""
        thesis = ""
        sector = ""
    }
    
    // MARK: - Calculation Methods
    
    private func calculateTotalInvestment() -> String {
        guard let qty = Double(quantity),
              let price = Double(buyPrice) else {
            return "$0.00"
        }
        return String(format: "$%.2f", qty * price)
    }
    
    private func calculateRiskAmount() -> String {
        guard let qty = Double(quantity),
              let price = Double(buyPrice),
              let stop = Double(stopLoss) else {
            return "$0.00"
        }
        return String(format: "$%.2f", qty * abs(price - stop))
    }
    
    private func calculateRiskRewardRatio() -> String {
        guard let price = Double(buyPrice),
              let stop = Double(stopLoss),
              let target = Double(priceTarget) else {
            return "N/A"
        }
        
        let risk = abs(price - stop)
        let reward = abs(target - price)
        
        guard risk > 0 else { return "N/A" }
        
        return String(format: "1:%.1f", reward / risk)
    }
    
    private func calculateStopLossPercent() -> String {
        guard let price = Double(buyPrice),
              let stop = Double(stopLoss) else {
            return "N/A"
        }
        
        let percent = ((stop - price) / price) * 100
        return String(format: "%.1f%%", percent)
    }
    
    private func calculateTargetPercent() -> String {
        guard let price = Double(buyPrice),
              let target = Double(priceTarget) else {
            return "N/A"
        }
        
        let percent = ((target - price) / price) * 100
        return String(format: "+%.1f%%", percent)
    }
    
    private func getRiskLevel() -> String {
        guard let price = Double(buyPrice),
              let stop = Double(stopLoss) else {
            return "N/A"
        }
        
        let percent = abs((stop - price) / price) * 100
        
        if percent <= 5 {
            return "Low"
        } else if percent <= 10 {
            return "Medium"
        } else {
            return "High"
        }
    }
    
    private func getRiskLevelColor() -> Color {
        let level = getRiskLevel()
        switch level {
        case "Low": return themeManager.positiveColor
        case "Medium": return themeManager.neutralColor
        case "High": return themeManager.negativeColor
        default: return themeManager.textSecondaryColor
        }
    }
}

// MARK: - Supporting Views

struct CustomTextField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(themeManager.textPrimaryColor)
            
            TextField(placeholder, text: $value)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(8)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeManager.textPrimaryColor)
        }
    }
}

struct RiskMetricCard: View {
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

#Preview {
    AddPositionView()
        .environmentObject(ThemeManager())
        .environmentObject(PortfolioViewModel())
} 