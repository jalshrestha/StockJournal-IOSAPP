import Foundation

struct Stock: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let name: String
    let currentPrice: Double
    let change: Double
    let changePercent: Double
    let sector: String
    
    init(symbol: String, name: String, currentPrice: Double, change: Double, changePercent: Double, sector: String) {
        self.id = UUID()
        self.symbol = symbol
        self.name = name
        self.currentPrice = currentPrice
        self.change = change
        self.changePercent = changePercent
        self.sector = sector
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", change))"
    }
    
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
}

extension Stock {
    static let sampleStocks = [
        Stock(symbol: "AAPL", name: "Apple Inc.", currentPrice: 175.43, change: 2.34, changePercent: 1.35, sector: "Technology"),
        Stock(symbol: "GOOGL", name: "Alphabet Inc.", currentPrice: 142.56, change: -1.23, changePercent: -0.85, sector: "Technology"),
        Stock(symbol: "MSFT", name: "Microsoft Corporation", currentPrice: 378.85, change: 5.67, changePercent: 1.52, sector: "Technology"),
        Stock(symbol: "TSLA", name: "Tesla, Inc.", currentPrice: 248.50, change: -3.45, changePercent: -1.37, sector: "Consumer Cyclical"),
        Stock(symbol: "AMZN", name: "Amazon.com, Inc.", currentPrice: 145.86, change: 0.75, changePercent: 0.52, sector: "Consumer Cyclical"),
        Stock(symbol: "NVDA", name: "NVIDIA Corporation", currentPrice: 875.28, change: 12.34, changePercent: 1.43, sector: "Technology"),
        Stock(symbol: "META", name: "Meta Platforms, Inc.", currentPrice: 497.21, change: -2.89, changePercent: -0.58, sector: "Communication Services"),
        Stock(symbol: "NFLX", name: "Netflix, Inc.", currentPrice: 692.12, change: 8.45, changePercent: 1.24, sector: "Communication Services"),
        Stock(symbol: "CRM", name: "Salesforce, Inc.", currentPrice: 264.18, change: 1.87, changePercent: 0.71, sector: "Technology"),
        Stock(symbol: "ADBE", name: "Adobe Inc.", currentPrice: 567.23, change: -4.56, changePercent: -0.80, sector: "Technology")
    ]
    
    static let popularStocks = [
        "AAPL", "GOOGL", "MSFT", "TSLA", "AMZN", "NVDA", "META", "NFLX", "CRM", "ADBE",
        "BABA", "V", "JNJ", "WMT", "JPM", "PG", "UNH", "HD", "MA", "BAC"
    ]
} 