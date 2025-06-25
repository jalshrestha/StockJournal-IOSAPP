import Foundation
import CoreData
import Combine

class PortfolioViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var filteredPositions: [Position] = []
    @Published var searchText = ""
    @Published var selectedFilter: PositionFilter = .all
    @Published var sortOption: SortOption = .dateAdded
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var managedObjectContext: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()
    
    enum PositionFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case closed = "Closed"
        case profitable = "Profitable"
        case unprofitable = "At Loss"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case symbol = "Symbol"
        case performance = "Performance"
        case value = "Value"
        case risk = "Risk"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init() {
        setupSearchAndFilter()
    }
    
    func setContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
        fetchPositions()
    }
    
    // MARK: - Core Data Operations
    
    func fetchPositions() {
        guard let context = managedObjectContext else { return }
        
        let request: NSFetchRequest<Position> = Position.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Position.dateAdded, ascending: false)]
        
        do {
            positions = try context.fetch(request)
            updateCurrentPrices()
        } catch {
            errorMessage = "Failed to fetch positions: \(error.localizedDescription)"
        }
    }
    
    func addPosition(
        symbol: String,
        name: String,
        quantity: Double,
        buyPrice: Double,
        stopLoss: Double,
        priceTarget: Double,
        thesis: String,
        sector: String,
        tags: String = "",
        notes: String = ""
    ) {
        guard let context = managedObjectContext else { return }
        
        let position = Position(context: context)
        position.id = UUID()
        position.stockSymbol = symbol.uppercased()
        position.stockName = name
        position.quantity = quantity
        position.buyPrice = buyPrice
        position.currentPrice = buyPrice // Initial price same as buy price
        position.stopLoss = stopLoss
        position.priceTarget = priceTarget
        position.thesis = thesis
        position.sector = sector
        position.tags = tags
        position.notes = notes
        position.dateAdded = Date()
        position.isActive = true
        position.sellPrice = 0
        
        saveContext()
    }
    
    func updatePosition(_ position: Position) {
        saveContext()
    }
    
    func closePosition(_ position: Position, sellPrice: Double) {
        position.sellPrice = sellPrice
        position.sellDate = Date()
        position.isActive = false
        saveContext()
    }
    
    func closePosition(_ position: Position) {
        closePosition(position, sellPrice: position.currentPrice)
    }
    
    func deletePosition(_ position: Position) {
        guard let context = managedObjectContext else { return }
        context.delete(position)
        saveContext()
    }
    
    private func saveContext() {
        guard let context = managedObjectContext else { return }
        
        do {
            try context.save()
            fetchPositions()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Price Updates (Mock)
    
    private func updateCurrentPrices() {
        // In a real app, this would fetch live prices from an API
        for position in positions {
            if position.isActive {
                // Simulate price changes
                let randomChange = Double.random(in: -0.05...0.05)
                let newPrice = position.buyPrice * (1 + randomChange)
                position.currentPrice = max(newPrice, 0.01) // Ensure price doesn't go negative
            }
        }
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Search and Filter
    
    private func setupSearchAndFilter() {
        Publishers.CombineLatest3($positions, $searchText, $selectedFilter)
            .map { [weak self] positions, searchText, filter in
                self?.filterAndSortPositions(positions, searchText: searchText, filter: filter) ?? []
            }
            .assign(to: \.filteredPositions, on: self)
            .store(in: &cancellables)
    }
    
    private func filterAndSortPositions(_ positions: [Position], searchText: String, filter: PositionFilter) -> [Position] {
        var filtered = positions
        
        // Apply text search
        if !searchText.isEmpty {
            filtered = filtered.filter { position in
                position.stockSymbol.localizedCaseInsensitiveContains(searchText) ||
                position.stockName.localizedCaseInsensitiveContains(searchText) ||
                position.sector.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filter
        switch filter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .closed:
            filtered = filtered.filter { !$0.isActive }
        case .profitable:
            filtered = filtered.filter { 
                $0.isActive ? $0.unrealizedPnL > 0 : $0.realizedPnL > 0 
            }
        case .unprofitable:
            filtered = filtered.filter { 
                $0.isActive ? $0.unrealizedPnL < 0 : $0.realizedPnL < 0 
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        case .symbol:
            filtered.sort { $0.stockSymbol < $1.stockSymbol }
        case .performance:
            filtered.sort { 
                let pnl1 = $0.isActive ? $0.unrealizedPnLPercent : $0.realizedPnLPercent
                let pnl2 = $1.isActive ? $1.unrealizedPnLPercent : $1.realizedPnLPercent
                return pnl1 > pnl2
            }
        case .value:
            filtered.sort { $0.currentValue > $1.currentValue }
        case .risk:
            filtered.sort { $0.riskAmount > $1.riskAmount }
        }
        
        return filtered
    }
    
    // MARK: - Portfolio Analytics
    
    var portfolio: Portfolio {
        return Portfolio(positions: positions)
    }
    
    var activePositions: [Position] {
        positions.filter { $0.isActive }
    }
    
    var closedPositions: [Position] {
        positions.filter { !$0.isActive }
    }
    
    var totalProfitLoss: String {
        let total = positions.reduce(0.0) { sum, position in
            return sum + (position.isActive ? position.unrealizedPnL : position.realizedPnL)
        }
        return String(format: "$%.2f", total)
    }
    
    var totalProfitLossValue: Double {
        return positions.reduce(0.0) { sum, position in
            return sum + (position.isActive ? position.unrealizedPnL : position.realizedPnL)
        }
    }
    
    var winRate: String {
        let winningPositions = positions.filter { position in
            let pnl = position.isActive ? position.unrealizedPnL : position.realizedPnL
            return pnl > 0
        }
        
        guard !positions.isEmpty else { return "0%" }
        
        let rate = (Double(winningPositions.count) / Double(positions.count)) * 100
        return String(format: "%.1f%%", rate)
    }
    
    var totalPortfolioValue: String {
        let total = positions.reduce(0.0) { sum, position in
            return sum + (position.isActive ? position.currentValue : 0)
        }
        return String(format: "$%.2f", total)
    }
    
    var totalProfitLossPercent: String {
        let totalInvested = positions.reduce(0.0) { sum, position in
            return sum + (position.quantity * position.buyPrice)
        }
        
        guard totalInvested > 0 else { return "0.0%" }
        
        let percent = (totalProfitLossValue / totalInvested) * 100
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percent))%"
    }
    
    var totalRiskAmount: String {
        let risk = positions.reduce(0.0) { sum, position in
            return sum + (position.isActive ? position.riskAmount : 0)
        }
        return String(format: "$%.0f", risk)
    }
    
    var portfolioRiskPercent: Double {
        let totalValue = positions.reduce(0.0) { sum, position in
            return sum + (position.isActive ? position.currentValue : 0)
        }
        let totalRisk = positions.reduce(0.0) { sum, position in
            return sum + (position.isActive ? position.riskAmount : 0)
        }
        
        guard totalValue > 0 else { return 0 }
        return (totalRisk / totalValue) * 100
    }
    
    var topHoldings: [Position] {
        return activePositions.sorted { $0.currentValue > $1.currentValue }
    }
    
    var bestPerformer: Position? {
        return activePositions.max { 
            $0.unrealizedPnLPercent < $1.unrealizedPnLPercent 
        }
    }
    
    var worstPerformer: Position? {
        return activePositions.min { 
            $0.unrealizedPnLPercent < $1.unrealizedPnLPercent 
        }
    }
    
    var largestPosition: Position? {
        return activePositions.max { $0.currentValue < $1.currentValue }
    }
    
    var bestPerformerGain: String {
        guard let best = bestPerformer else { return "N/A" }
        let sign = best.unrealizedPnLPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", best.unrealizedPnLPercent))%"
    }
    
    var worstPerformerLoss: String {
        guard let worst = worstPerformer else { return "N/A" }
        let sign = worst.unrealizedPnLPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", worst.unrealizedPnLPercent))%"
    }
    
    var largestPositionValue: String {
        guard let largest = largestPosition else { return "N/A" }
        return String(format: "$%.0f", largest.currentValue)
    }
    
    var averageReturn: String {
        guard !activePositions.isEmpty else { return "N/A" }
        
        let total = activePositions.reduce(0.0) { sum, position in
            return sum + position.unrealizedPnLPercent
        }
        let average = total / Double(activePositions.count)
        let sign = average >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", average))%"
    }
    
    // MARK: - Utility Methods
    
    func refreshPrices() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateCurrentPrices()
            self.isLoading = false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func exportData() -> String {
        var csvContent = "Symbol,Name,Quantity,Buy Price,Current Price,P&L,P&L %,Status,Date Added\n"
        
        for position in positions {
            let pnl = position.isActive ? position.unrealizedPnL : position.realizedPnL
            let pnlPercent = position.isActive ? position.unrealizedPnLPercent : position.realizedPnLPercent
            let status = position.isActive ? "Active" : "Closed"
            
            csvContent += "\(position.stockSymbol),\(position.stockName),\(position.quantity),\(position.buyPrice),\(position.currentPrice),\(pnl),\(pnlPercent),\(status),\(position.dateAdded)\n"
        }
        
        return csvContent
    }
} 