import Foundation

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", close)
    }
}

enum ChartTimeframe: String, CaseIterable {
    case oneDay = "1D"
    case fiveDays = "5D"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    
    var displayName: String {
        return self.rawValue
    }
    
    var days: Int {
        switch self {
        case .oneDay: return 1
        case .fiveDays: return 5
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .oneYear: return 365
        }
    }
    
    var dataPointCount: Int {
        switch self {
        case .oneDay: return 24
        case .fiveDays: return 120
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .oneYear: return 365
        }
    }
    
    var intervalSeconds: Int {
        switch self {
        case .oneDay: return 3600 // 1 hour
        case .fiveDays: return 3600 // 1 hour
        case .oneMonth: return 86400 // 1 day
        case .threeMonths: return 86400 // 1 day
        case .oneYear: return 86400 // 1 day
        }
    }
    
    var dateFormat: String {
        switch self {
        case .oneDay: return "HH:mm"
        case .fiveDays, .oneMonth: return "MMM d"
        case .threeMonths: return "MMM d"
        case .oneYear: return "MMM yyyy"
        }
    }
}

struct TechnicalIndicator {
    let name: String
    let value: Double
    let signal: Signal
    
    enum Signal {
        case buy
        case sell
        case hold
        
        var color: String {
            switch self {
            case .buy: return "green"
            case .sell: return "red"
            case .hold: return "yellow"
            }
        }
        
        var displayName: String {
            switch self {
            case .buy: return "BUY"
            case .sell: return "SELL"
            case .hold: return "HOLD"
            }
        }
    }
}

struct MovingAverage {
    let period: Int
    let value: Double
    let type: MAType
    
    enum MAType {
        case simple
        case exponential
        case weighted
        
        var displayName: String {
            switch self {
            case .simple: return "SMA"
            case .exponential: return "EMA"
            case .weighted: return "WMA"
            }
        }
    }
}

// MARK: - Sample Data
extension ChartData {
    static func generateSampleData(for timeframe: ChartTimeframe, basePrice: Double = 150.0) -> [ChartData] {
        var data: [ChartData] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        for i in 0..<timeframe.days {
            let date = calendar.date(byAdding: .day, value: -i, to: endDate) ?? endDate
            
            // Generate realistic OHLC data with some volatility
            let randomFactor = Double.random(in: 0.95...1.05)
            let dailyVolatility = Double.random(in: -0.03...0.03)
            
            let close = basePrice * randomFactor * (1 + dailyVolatility)
            let open = close * Double.random(in: 0.98...1.02)
            let high = max(open, close) * Double.random(in: 1.0...1.02)
            let low = min(open, close) * Double.random(in: 0.98...1.0)
            
            let volume = Int64.random(in: 1_000_000...10_000_000)
            
            let chartPoint = ChartData(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
            
            data.append(chartPoint)
        }
        
        return data.sorted { $0.date < $1.date }
    }
}

extension TechnicalIndicator {
    static let sampleIndicators = [
        TechnicalIndicator(name: "RSI (14)", value: 65.4, signal: .hold),
        TechnicalIndicator(name: "MACD", value: 2.34, signal: .buy),
        TechnicalIndicator(name: "Stochastic", value: 45.2, signal: .hold),
        TechnicalIndicator(name: "Williams %R", value: -35.7, signal: .buy)
    ]
}

extension MovingAverage {
    static let sampleMovingAverages = [
        MovingAverage(period: 20, value: 152.45, type: .simple),
        MovingAverage(period: 50, value: 148.92, type: .simple),
        MovingAverage(period: 200, value: 145.67, type: .simple),
        MovingAverage(period: 12, value: 153.21, type: .exponential),
        MovingAverage(period: 26, value: 150.88, type: .exponential)
    ]
} 