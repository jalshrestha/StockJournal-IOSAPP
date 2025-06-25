import SwiftUI
import Charts
import Combine

struct PositionDetailView: View {
    let position: Position
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeframe = ChartTimeframe.oneDay
    @State private var chartData: [ChartData] = []
    @State private var isLoadingChart = false
    @State private var showingEditPosition = false
    @State private var showingCloseAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Summary
                    headerSummaryCard
                    
                    // Live Chart
                    liveChartCard
                    
                    // Position Analytics
                    positionAnalyticsCard
                    
                    // Risk Analysis
                    riskAnalysisCard
                    
                    // Investment Thesis
                    investmentThesisCard
                    
                    // Action Buttons
                    actionButtonsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle(position.stockSymbol)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditPosition = true
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .onAppear {
            loadChartData()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            loadChartData()
        }
        .sheet(isPresented: $showingEditPosition) {
            // EditPositionView(position: position)
        }
        .alert("Close Position", isPresented: $showingCloseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Close Position", role: .destructive) {
                portfolioViewModel.closePosition(position)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to close this position?")
        }
        .alert("Delete Position", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                portfolioViewModel.deletePosition(position)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to permanently delete this position?")
        }
    }
    
    // MARK: - Header Summary Card
    
    private var headerSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stock Info Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.stockName)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text(position.sector)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(position.formattedCurrentPrice)
                        .font(.title.weight(.bold))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: position.profitLossValue >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(position.profitLossPercent)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
                }
            }
            
            // P&L Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total P&L")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                    Text(position.profitLoss)
                        .font(.title.weight(.bold))
                        .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Position Value")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                    Text(position.formattedPositionValue)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(themeManager.textPrimaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                    Text(String(format: "%.1f%%", position.progressToTarget))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Live Chart Card
    
    private var liveChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Header
            HStack {
                Text("Price Chart")
                    .font(themeManager.headlineFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                if isLoadingChart {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Timeframe Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                        Button(timeframe.displayName) {
                            selectedTimeframe = timeframe
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTimeframe == timeframe ? themeManager.primaryColor : themeManager.secondaryBackgroundColor)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : themeManager.textSecondaryColor)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Chart View
            if chartData.isEmpty {
                chartPlaceholder
            } else {
                liveChart
            }
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Chart Placeholder
    
    private var chartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(themeManager.textSecondaryColor)
            
            Text("Loading chart data...")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(themeManager.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Live Chart
    
    private var liveChart: some View {
        Chart(chartData) { dataPoint in
            LineMark(
                x: .value("Time", dataPoint.date),
                y: .value("Price", dataPoint.close)
            )
            .foregroundStyle(themeManager.primaryColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Time", dataPoint.date),
                y: .value("Price", dataPoint.close)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [themeManager.primaryColor.opacity(0.3), themeManager.primaryColor.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Buy Price Line
            RuleMark(y: .value("Buy Price", position.buyPrice))
                .foregroundStyle(themeManager.neutralColor)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            // Stop Loss Line
            RuleMark(y: .value("Stop Loss", position.stopLoss))
                .foregroundStyle(themeManager.negativeColor)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            
            // Price Target Line
            RuleMark(y: .value("Target", position.priceTarget))
                .foregroundStyle(themeManager.positiveColor)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .currency(code: "USD"))
            }
        }
    }
    
    // MARK: - Position Analytics Card
    
    private var positionAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Position Analytics")
                .font(themeManager.headlineFont)
                .foregroundColor(themeManager.textPrimaryColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                AnalyticsMetric(
                    title: "Quantity",
                    value: "\(Int(position.quantity)) shares",
                    icon: "number.circle",
                    color: themeManager.textPrimaryColor
                )
                
                AnalyticsMetric(
                    title: "Buy Price",
                    value: position.formattedBuyPrice,
                    icon: "dollarsign.circle",
                    color: themeManager.textPrimaryColor
                )
                
                AnalyticsMetric(
                    title: "Current Price",
                    value: position.formattedCurrentPrice,
                    icon: "chart.line.uptrend.xyaxis.circle",
                    color: themeManager.primaryColor
                )
                
                AnalyticsMetric(
                    title: "Total Investment",
                    value: String(format: "$%.2f", position.buyPrice * position.quantity),
                    icon: "banknote.fill",
                    color: themeManager.textPrimaryColor
                )
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
            
            VStack(spacing: 12) {
                // Risk Levels
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stop Loss")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Text(position.formattedStopLoss)
                            .font(.headline.weight(.bold))
                            .foregroundColor(themeManager.negativeColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Price Target")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Text(position.formattedPriceTarget)
                            .font(.headline.weight(.bold))
                            .foregroundColor(themeManager.positiveColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Risk:Reward")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Text(String(format: "1:%.1f", position.riskRewardRatio))
                            .font(.headline.weight(.bold))
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
                .padding(16)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(12)
                
                // Risk Metrics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    RiskMetric(
                        title: "Max Risk",
                        value: String(format: "$%.2f", abs(position.buyPrice - position.stopLoss) * position.quantity),
                        color: themeManager.negativeColor
                    )
                    
                    RiskMetric(
                        title: "Potential Profit",
                        value: String(format: "$%.2f", abs(position.priceTarget - position.buyPrice) * position.quantity),
                        color: themeManager.positiveColor
                    )
                    
                    RiskMetric(
                        title: "Stop Loss %",
                        value: String(format: "%.1f%%", ((position.stopLoss - position.buyPrice) / position.buyPrice) * 100),
                        color: themeManager.negativeColor
                    )
                    
                    RiskMetric(
                        title: "Target %",
                        value: String(format: "%.1f%%", ((position.priceTarget - position.buyPrice) / position.buyPrice) * 100),
                        color: themeManager.positiveColor
                    )
                }
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
            
            Text(position.thesis.isEmpty ? "No thesis provided" : position.thesis)
                .font(.subheadline)
                .foregroundColor(position.thesis.isEmpty ? themeManager.textSecondaryColor : themeManager.textPrimaryColor)
                .padding(16)
                .background(themeManager.secondaryBackgroundColor)
                .cornerRadius(12)
        }
        .padding(20)
        .themedCard()
    }
    
    // MARK: - Action Buttons Card
    
    private var actionButtonsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Edit Position") {
                    showingEditPosition = true
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("Close Trade") {
                    showingCloseAlert = true
                }
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button("Delete Position") {
                showingDeleteAlert = true
            }
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.negativeColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(20)
        .themedCard()
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func loadChartData() {
        isLoadingChart = true
        
        // Use real Alpha Vantage API for historical data
        StockDataService.shared.getHistoricalData(for: position.stockSymbol, timeframe: selectedTimeframe)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingChart = false
                    if case .failure(let error) = completion {
                        print("Chart data error: \(error)")
                        // Fallback to demo data
                        self.chartData = self.generateDemoChartData()
                    }
                },
                receiveValue: { data in
                    self.chartData = data.isEmpty ? self.generateDemoChartData() : data
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private func generateDemoChartData() -> [ChartData] {
        let basePrice = position.currentPrice
        let variation = basePrice * 0.05 // 5% variation
        let pointCount = selectedTimeframe.dataPointCount
        
        return (0..<pointCount).map { index in
            let timeOffset = TimeInterval(index * selectedTimeframe.intervalSeconds)
            let timestamp = Date().addingTimeInterval(-timeOffset)
            let randomFactor = Double.random(in: -1...1)
            let price = basePrice + (variation * randomFactor)
            
            return ChartData(date: timestamp, open: price, high: price * 1.01, low: price * 0.99, close: price, volume: 1000)
        }.reversed()
    }
}

// MARK: - Supporting Views

struct AnalyticsMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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

struct RiskMetric: View {
    let title: String
    let value: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.textSecondaryColor)
            
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
        }
        .padding(12)
        .background(themeManager.secondaryBackgroundColor)
        .cornerRadius(8)
    }
}

#Preview {
    // Create a sample position for preview
    let samplePosition = Position(context: PersistenceController.preview.container.viewContext)
    samplePosition.stockSymbol = "AAPL"
    samplePosition.stockName = "Apple Inc."
    samplePosition.sector = "Technology"
    samplePosition.quantity = 100
    samplePosition.buyPrice = 150.0
    samplePosition.currentPrice = 175.0
    samplePosition.stopLoss = 140.0
    samplePosition.priceTarget = 200.0
    samplePosition.thesis = "Strong fundamentals and growth potential"
    samplePosition.dateAdded = Date()
    samplePosition.isActive = true
    samplePosition.id = UUID()
    samplePosition.sellPrice = 0
    
    return PositionDetailView(position: samplePosition)
        .environmentObject(ThemeManager())
        .environmentObject(PortfolioViewModel())
} 