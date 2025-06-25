import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTimeframe: PortfolioTimeframe = .day
    @State private var portfolioChartData: [PortfolioChartData] = []
    @State private var showingPositionDetail = false
    @State private var selectedPosition: Position?
    
    enum PortfolioTimeframe: String, CaseIterable {
        case day = "1D"
        case week = "1W"
        case month = "1M"
        case threeMonth = "3M"
        case year = "1Y"
        case all = "ALL"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Portfolio Value Header
                    portfolioValueHeader
                    
                    // Performance Chart
                    portfolioPerformanceChart
                    
                    // Quick Analytics Cards
                    analyticsCardsGrid
                    
                    // Top Holdings
                    topHoldingsSection
                    
                    // Performance Metrics
                    performanceMetricsSection
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            generatePortfolioChartData()
        }
    }
    
    // MARK: - Portfolio Value Header
    
    private var portfolioValueHeader: some View {
        VStack(spacing: 12) {
            // Total Portfolio Value
            VStack(spacing: 4) {
                Text("Total Portfolio Value")
                    .font(.headline)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Text(portfolioViewModel.totalPortfolioValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.textPrimaryColor)
            }
            
            // Daily Change
            HStack(spacing: 8) {
                Image(systemName: portfolioViewModel.totalProfitLossValue >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.weight(.bold))
                
                Text(portfolioViewModel.totalProfitLoss)
                    .font(.headline.weight(.semibold))
                
                Text("(\(portfolioViewModel.totalProfitLossPercent))")
                    .font(.headline.weight(.medium))
                
                Text("Today")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .foregroundColor(themeManager.colorForPerformance(portfolioViewModel.totalProfitLossValue))
            
            // Timeframe Selector
            HStack(spacing: 0) {
                ForEach(PortfolioTimeframe.allCases, id: \.self) { timeframe in
                    Button(timeframe.rawValue) {
                        selectedTimeframe = timeframe
                        generatePortfolioChartData()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(selectedTimeframe == timeframe ? themeManager.primaryColor : themeManager.textSecondaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Rectangle()
                            .fill(selectedTimeframe == timeframe ? themeManager.primaryColor.opacity(0.1) : Color.clear)
                    )
                }
            }
            .background(themeManager.secondaryBackgroundColor)
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Portfolio Performance Chart
    
    private var portfolioPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(portfolioChartData) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.primaryColor.opacity(0.8), themeManager.primaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                
                AreaMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.primaryColor.opacity(0.3), themeManager.primaryColor.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartBackground { _ in
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Analytics Cards Grid
    
    private var analyticsCardsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            AnalyticsCard(
                title: "Active Positions",
                value: "\(portfolioViewModel.activePositions.count)",
                subtitle: "Investments",
                color: themeManager.primaryColor,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            AnalyticsCard(
                title: "Win Rate",
                value: portfolioViewModel.winRate,
                subtitle: "Success Rate",
                color: themeManager.positiveColor,
                icon: "target"
            )
            
            AnalyticsCard(
                title: "Total Risk",
                value: portfolioViewModel.totalRiskAmount,
                subtitle: "At Risk",
                color: themeManager.negativeColor,
                icon: "exclamationmark.triangle"
            )
            
            AnalyticsCard(
                title: "Portfolio Risk",
                value: String(format: "%.1f%%", portfolioViewModel.portfolioRiskPercent),
                subtitle: "Of Total",
                color: themeManager.neutralColor,
                icon: "shield"
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Top Holdings Section
    
    private var topHoldingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Holdings")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                NavigationLink("View All") {
                    PositionsView()
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(themeManager.primaryColor)
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(portfolioViewModel.topHoldings.prefix(5)) { position in
                        TopHoldingCard(position: position)
                            .onTapGesture {
                                selectedPosition = position
                                showingPositionDetail = true
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Performance Metrics Section
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.title2.weight(.semibold))
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                MetricRow(
                    title: "Best Performer",
                    value: portfolioViewModel.bestPerformer?.stockSymbol ?? "N/A",
                    subtitle: portfolioViewModel.bestPerformerGain,
                    color: themeManager.positiveColor,
                    icon: "arrow.up.circle.fill"
                )
                
                MetricRow(
                    title: "Worst Performer",
                    value: portfolioViewModel.worstPerformer?.stockSymbol ?? "N/A",
                    subtitle: portfolioViewModel.worstPerformerLoss,
                    color: themeManager.negativeColor,
                    icon: "arrow.down.circle.fill"
                )
                
                MetricRow(
                    title: "Largest Position",
                    value: portfolioViewModel.largestPosition?.stockSymbol ?? "N/A",
                    subtitle: portfolioViewModel.largestPositionValue,
                    color: themeManager.primaryColor,
                    icon: "circle.fill"
                )
                
                MetricRow(
                    title: "Average Return",
                    value: portfolioViewModel.averageReturn,
                    subtitle: "Per Position",
                    color: themeManager.textPrimaryColor,
                    icon: "chart.bar.fill"
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func generatePortfolioChartData() {
        let _ = Calendar.current
        let now = Date()
        let timeInterval: TimeInterval
        let pointCount: Int
        
        switch selectedTimeframe {
        case .day:
            timeInterval = -24 * 60 * 60 // 24 hours
            pointCount = 24
        case .week:
            timeInterval = -7 * 24 * 60 * 60 // 7 days
            pointCount = 7
        case .month:
            timeInterval = -30 * 24 * 60 * 60 // 30 days
            pointCount = 30
        case .threeMonth:
            timeInterval = -90 * 24 * 60 * 60 // 90 days
            pointCount = 30
        case .year:
            timeInterval = -365 * 24 * 60 * 60 // 365 days
            pointCount = 50
        case .all:
            timeInterval = -730 * 24 * 60 * 60 // 2 years
            pointCount = 100
        }
        
        let startDate = Date(timeIntervalSinceNow: timeInterval)
        let interval = abs(timeInterval) / Double(pointCount)
        
        // Generate sample portfolio performance data
        let baseValue = 10000.0
        var currentValue = baseValue
        var chartData: [PortfolioChartData] = []
        
        for i in 0..<pointCount {
            let date = Date(timeInterval: interval * Double(i), since: startDate)
            
            // Simulate portfolio growth/decline
            let randomChange = Double.random(in: -0.02...0.025) // -2% to +2.5% daily change
            currentValue *= (1 + randomChange)
            
            chartData.append(PortfolioChartData(date: date, value: currentValue))
        }
        
        // Add current portfolio value as last point
        if let actualValue = Double(portfolioViewModel.totalPortfolioValue.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
            chartData.append(PortfolioChartData(date: now, value: actualValue))
        }
        
        portfolioChartData = chartData
    }
}

// MARK: - Supporting Views

struct PortfolioChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct TopHoldingCard: View {
    let position: Position
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(position.stockSymbol)
                    .font(.headline.weight(.bold))
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
                Text(position.formattedPositionValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            Text(position.stockName)
                .font(.caption)
                .foregroundColor(themeManager.textSecondaryColor)
                .lineLimit(1)
            
            Spacer()
            
            HStack {
                Text(position.profitLoss)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
                
                Spacer()
                
                Text(position.profitLossPercent)
                    .font(.caption.weight(.medium))
                    .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
            }
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PortfolioView()
        .environmentObject(ThemeManager())
        .environmentObject(PortfolioViewModel())
} 