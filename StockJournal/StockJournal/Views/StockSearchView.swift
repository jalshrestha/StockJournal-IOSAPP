import SwiftUI
import Combine

struct StockSearchView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var searchResults: [Stock] = []
    @State private var isLoading = false
    
    let onStockSelected: (Stock) -> Void
    
    init(onStockSelected: @escaping (Stock) -> Void) {
        self.onStockSelected = onStockSelected
    }
    
    // Demo stock database - In real app, this would come from API
    private let stockDatabase: [Stock] = [
        Stock(symbol: "AAPL", name: "Apple Inc.", currentPrice: 175.84, change: 2.41, changePercent: 1.39, sector: "Technology"),
        Stock(symbol: "MSFT", name: "Microsoft Corporation", currentPrice: 378.85, change: -1.23, changePercent: -0.32, sector: "Technology"),
        Stock(symbol: "GOOGL", name: "Alphabet Inc.", currentPrice: 139.69, change: 1.87, changePercent: 1.36, sector: "Technology"),
        Stock(symbol: "AMZN", name: "Amazon.com Inc.", currentPrice: 127.74, change: 0.95, changePercent: 0.75, sector: "Consumer Discretionary"),
        Stock(symbol: "TSLA", name: "Tesla Inc.", currentPrice: 248.50, change: -5.67, changePercent: -2.23, sector: "Automotive"),
        Stock(symbol: "META", name: "Meta Platforms Inc.", currentPrice: 298.58, change: 3.21, changePercent: 1.09, sector: "Technology"),
        Stock(symbol: "NVDA", name: "NVIDIA Corporation", currentPrice: 875.28, change: 15.44, changePercent: 1.80, sector: "Technology"),
        Stock(symbol: "NFLX", name: "Netflix Inc.", currentPrice: 485.73, change: 7.89, changePercent: 1.65, sector: "Entertainment"),
        Stock(symbol: "DIS", name: "The Walt Disney Company", currentPrice: 111.25, change: -0.87, changePercent: -0.78, sector: "Entertainment"),
        Stock(symbol: "CRM", name: "Salesforce Inc.", currentPrice: 216.90, change: 4.33, changePercent: 2.04, sector: "Technology"),
        
        // Banking & Finance
        Stock(symbol: "JPM", name: "JPMorgan Chase & Co.", currentPrice: 154.32, change: 1.67, changePercent: 1.09, sector: "Financial Services"),
        Stock(symbol: "BAC", name: "Bank of America Corp.", currentPrice: 32.44, change: 0.23, changePercent: 0.71, sector: "Financial Services"),
        Stock(symbol: "WFC", name: "Wells Fargo & Company", currentPrice: 45.67, change: -0.34, changePercent: -0.74, sector: "Financial Services"),
        Stock(symbol: "GS", name: "Goldman Sachs Group Inc.", currentPrice: 365.78, change: 2.89, changePercent: 0.80, sector: "Financial Services"),
        
        // Healthcare
        Stock(symbol: "JNJ", name: "Johnson & Johnson", currentPrice: 160.45, change: 0.78, changePercent: 0.49, sector: "Healthcare"),
        Stock(symbol: "PFE", name: "Pfizer Inc.", currentPrice: 27.89, change: -0.12, changePercent: -0.43, sector: "Healthcare"),
        Stock(symbol: "UNH", name: "UnitedHealth Group Inc.", currentPrice: 528.90, change: 6.45, changePercent: 1.23, sector: "Healthcare"),
        Stock(symbol: "ABBV", name: "AbbVie Inc.", currentPrice: 145.67, change: 1.23, changePercent: 0.85, sector: "Healthcare"),
        
        // Energy
        Stock(symbol: "XOM", name: "Exxon Mobil Corporation", currentPrice: 104.56, change: 2.34, changePercent: 2.29, sector: "Energy"),
        Stock(symbol: "CVX", name: "Chevron Corporation", currentPrice: 147.89, change: 1.78, changePercent: 1.22, sector: "Energy"),
        
        // Consumer Goods
        Stock(symbol: "KO", name: "The Coca-Cola Company", currentPrice: 58.23, change: 0.45, changePercent: 0.78, sector: "Consumer Staples"),
        Stock(symbol: "PEP", name: "PepsiCo Inc.", currentPrice: 171.34, change: 0.89, changePercent: 0.52, sector: "Consumer Staples"),
        Stock(symbol: "WMT", name: "Walmart Inc.", currentPrice: 159.78, change: 1.12, changePercent: 0.71, sector: "Consumer Staples"),
        
        // Industrial
        Stock(symbol: "BA", name: "The Boeing Company", currentPrice: 203.45, change: -3.67, changePercent: -1.77, sector: "Aerospace & Defense"),
        Stock(symbol: "CAT", name: "Caterpillar Inc.", currentPrice: 267.89, change: 4.23, changePercent: 1.60, sector: "Machinery"),
        
        // Real Estate
        Stock(symbol: "AMT", name: "American Tower Corporation", currentPrice: 198.67, change: 2.34, changePercent: 1.19, sector: "Real Estate"),
        
        // Utilities
        Stock(symbol: "NEE", name: "NextEra Energy Inc.", currentPrice: 56.78, change: 0.67, changePercent: 1.19, sector: "Utilities")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeader
                
                // Search Results
                if isLoading {
                    loadingView
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptyStateView
                } else if searchResults.isEmpty {
                    popularStocksView
                } else {
                    searchResultsList
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Search Stocks")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // This will be handled by parent view
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
        .onAppear {
            searchResults = Array(stockDatabase.prefix(10)) // Show popular stocks initially
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(newValue)
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.textSecondaryColor)
                
                TextField("Search by symbol or company name...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .onSubmit {
                        performSearch(searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
            }
            .padding(12)
            .background(themeManager.secondaryBackgroundColor)
            .cornerRadius(10)
            
            if !searchText.isEmpty {
                HStack {
                    Text("Found \(searchResults.count) results")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching stocks...")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeManager.textSecondaryColor)
            
            Text("No stocks found")
                .font(.headline)
                .foregroundColor(themeManager.textPrimaryColor)
            
            Text("Try searching with a different symbol or company name")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Popular Stocks View
    
    private var popularStocksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Stocks")
                    .font(themeManager.headlineFont)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(searchResults) { stock in
                        StockRowView(stock: stock) {
                            onStockSelected(stock)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(searchResults) { stock in
                    StockRowView(stock: stock) {
                        onStockSelected(stock)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func performSearch(_ query: String) {
        if query.isEmpty {
            searchResults = Array(stockDatabase.prefix(10))
            return
        }
        
        isLoading = true
        
        // Use real Alpha Vantage API
        StockDataService.shared.searchStocks(query: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("Search error: \(error)")
                        // Fallback to local search on error
                        let filtered = self.stockDatabase.filter { stock in
                            stock.symbol.localizedCaseInsensitiveContains(query) ||
                            stock.name.localizedCaseInsensitiveContains(query)
                        }
                        self.searchResults = Array(filtered.prefix(20))
                    }
                },
                receiveValue: { stocks in
                    self.searchResults = stocks.isEmpty ? Array(self.stockDatabase.prefix(10)) : stocks
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Stock Row View

struct StockRowView: View {
    let stock: Stock
    let onTap: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Stock Icon/Symbol
                VStack {
                    Text(String(stock.symbol.prefix(2)))
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                }
                
                // Stock Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(stock.symbol)
                            .font(.headline.weight(.bold))
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Spacer()
                        
                        Text(stock.formattedPrice)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                    
                    HStack {
                        Text(stock.name)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: stock.change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text(stock.formattedChangePercent)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(themeManager.colorForPerformance(stock.change))
                    }
                    
                    Text(stock.sector)
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.neutralColor.opacity(0.2))
                        .cornerRadius(4)
                }
                
                // Selection Indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            .padding(16)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    StockSearchView { stock in
        print("Selected: \(stock.symbol)")
    }
    .environmentObject(ThemeManager())
} 