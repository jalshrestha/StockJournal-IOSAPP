import Foundation
import Combine

// MARK: - API Response Models
struct AlphaVantageSearchResponse: Codable {
    let bestMatches: [AlphaVantageSearchResult]
}

struct AlphaVantageSearchResult: Codable {
    let symbol: String
    let name: String
    let type: String
    let region: String
    let marketOpen: String
    let marketClose: String
    let timezone: String
    let currency: String
    let matchScore: String
    
    enum CodingKeys: String, CodingKey {
        case symbol = "1. symbol"
        case name = "2. name"
        case type = "3. type"
        case region = "4. region"
        case marketOpen = "5. marketOpen"
        case marketClose = "6. marketClose"
        case timezone = "7. timezone"
        case currency = "8. currency"
        case matchScore = "9. matchScore"
    }
}

struct AlphaVantageQuoteResponse: Codable {
    let globalQuote: AlphaVantageQuote
    
    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }
}

struct AlphaVantageQuote: Codable {
    let symbol: String
    let open: String
    let high: String
    let low: String
    let price: String
    let volume: String
    let latestTradingDay: String
    let previousClose: String
    let change: String
    let changePercent: String
    
    enum CodingKeys: String, CodingKey {
        case symbol = "01. symbol"
        case open = "02. open"
        case high = "03. high"
        case low = "04. low"
        case price = "05. price"
        case volume = "06. volume"
        case latestTradingDay = "07. latest trading day"
        case previousClose = "08. previous close"
        case change = "09. change"
        case changePercent = "10. change percent"
    }
}

struct AlphaVantageTimeSeriesResponse: Codable {
    let timeSeries: [String: AlphaVantageDataPoint]
    
    enum CodingKeys: String, CodingKey {
        case timeSeries = "Time Series (5min)"
    }
}

struct AlphaVantageDailyResponse: Codable {
    let timeSeries: [String: AlphaVantageDataPoint]
    
    enum CodingKeys: String, CodingKey {
        case timeSeries = "Time Series (Daily)"
    }
}

struct AlphaVantageDataPoint: Codable {
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String
    
    enum CodingKeys: String, CodingKey {
        case open = "1. open"
        case high = "2. high"
        case low = "3. low"
        case close = "4. close"
        case volume = "5. volume"
    }
}

// MARK: - Stock Data Service
class StockDataService: ObservableObject {
    static let shared = StockDataService()
    
    @Published var stocks: [Stock] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = "EKXF15KIY8O50E73"
    private let baseURL = "https://www.alphavantage.co/query"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Stock Search
    func searchStocks(query: String) -> AnyPublisher<[Stock], Error> {
        guard !query.isEmpty else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        let url = URL(string: "\(baseURL)?function=SYMBOL_SEARCH&keywords=\(query)&apikey=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AlphaVantageSearchResponse.self, decoder: JSONDecoder())
            .map { response in
                response.bestMatches.prefix(10).map { result in
                    Stock(
                        symbol: result.symbol,
                        name: result.name,
                        currentPrice: 0.0, // Will be updated with real price
                        change: 0.0,
                        changePercent: 0.0,
                        sector: self.determineSector(from: result.name)
                    )
                }
            }
            .catch { error in
                Just([])
                    .setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Real-time Stock Quote
    func getStockQuote(symbol: String) -> AnyPublisher<Stock, Error> {
        let url = URL(string: "\(baseURL)?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AlphaVantageQuoteResponse.self, decoder: JSONDecoder())
            .map { response in
                let quote = response.globalQuote
                return Stock(
                    symbol: quote.symbol,
                    name: quote.symbol, // Company name would need separate API call
                    currentPrice: Double(quote.price) ?? 0.0,
                    change: Double(quote.change) ?? 0.0,
                    changePercent: Double(quote.changePercent.replacingOccurrences(of: "%", with: "")) ?? 0.0,
                    sector: self.determineSector(from: quote.symbol)
                )
            }
            .catch { error in
                Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Historical Chart Data
    func getHistoricalData(for symbol: String, timeframe: ChartTimeframe) -> AnyPublisher<[ChartData], Error> {
        let function: String
        let interval: String
        
        switch timeframe {
        case .oneDay, .fiveDays:
            function = "TIME_SERIES_INTRADAY"
            interval = "&interval=5min"
        case .oneMonth, .threeMonths, .oneYear:
            function = "TIME_SERIES_DAILY"
            interval = ""
        }
        
        let url = URL(string: "\(baseURL)?function=\(function)\(interval)&symbol=\(symbol)&apikey=\(apiKey)")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data in
                if function == "TIME_SERIES_INTRADAY" {
                    let response = try JSONDecoder().decode(AlphaVantageTimeSeriesResponse.self, from: data)
                    return self.parseIntradayData(response.timeSeries, timeframe: timeframe)
                } else {
                    let response = try JSONDecoder().decode(AlphaVantageDailyResponse.self, from: data)
                    return self.parseDailyData(response.timeSeries, timeframe: timeframe)
                }
            }
            .catch { error in
                Just([])
                    .setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Data Parsing
    private func parseIntradayData(_ timeSeries: [String: AlphaVantageDataPoint], timeframe: ChartTimeframe) -> [ChartData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let sortedData = timeSeries.compactMap { (key, value) -> ChartData? in
            guard let date = dateFormatter.date(from: key),
                  let open = Double(value.open),
                  let high = Double(value.high),
                  let low = Double(value.low),
                  let close = Double(value.close),
                  let volume = Int64(value.volume) else { return nil }
            
            return ChartData(date: date, open: open, high: high, low: low, close: close, volume: volume)
        }.sorted { $0.date < $1.date }
        
        // Filter based on timeframe
        let now = Date()
        let cutoffDate: Date
        
        switch timeframe {
        case .oneDay:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .fiveDays:
            cutoffDate = Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now
        default:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        }
        
        return sortedData.filter { $0.date >= cutoffDate }
    }
    
    private func parseDailyData(_ timeSeries: [String: AlphaVantageDataPoint], timeframe: ChartTimeframe) -> [ChartData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let sortedData = timeSeries.compactMap { (key, value) -> ChartData? in
            guard let date = dateFormatter.date(from: key),
                  let open = Double(value.open),
                  let high = Double(value.high),
                  let low = Double(value.low),
                  let close = Double(value.close),
                  let volume = Int64(value.volume) else { return nil }
            
            return ChartData(date: date, open: open, high: high, low: low, close: close, volume: volume)
        }.sorted { $0.date < $1.date }
        
        // Filter based on timeframe
        let now = Date()
        let cutoffDate: Date
        
        switch timeframe {
        case .oneMonth:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        case .oneYear:
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        default:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        }
        
        return sortedData.filter { $0.date >= cutoffDate }
    }
    
    // MARK: - Helper Methods
    private func determineSector(from name: String) -> String {
        let lowercaseName = name.lowercased()
        
        if lowercaseName.contains("tech") || lowercaseName.contains("software") || lowercaseName.contains("computer") {
            return "Technology"
        } else if lowercaseName.contains("health") || lowercaseName.contains("pharma") || lowercaseName.contains("bio") {
            return "Healthcare"
        } else if lowercaseName.contains("bank") || lowercaseName.contains("financial") || lowercaseName.contains("insurance") {
            return "Financial"
        } else if lowercaseName.contains("energy") || lowercaseName.contains("oil") || lowercaseName.contains("gas") {
            return "Energy"
        } else if lowercaseName.contains("retail") || lowercaseName.contains("consumer") {
            return "Consumer"
        } else {
            return "Other"
        }
    }
} 