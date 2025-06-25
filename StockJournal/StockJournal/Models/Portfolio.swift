import Foundation

struct Portfolio {
    let positions: [Position]
    
    var totalValue: Double {
        positions.reduce(0) { $0 + $1.currentValue }
    }
    
    var totalInvestment: Double {
        positions.reduce(0) { $0 + $1.totalInvestment }
    }
    
    var totalUnrealizedPnL: Double {
        positions.filter { $0.isActive }.reduce(0) { $0 + $1.unrealizedPnL }
    }
    
    var totalRealizedPnL: Double {
        positions.filter { !$0.isActive }.reduce(0) { $0 + $1.realizedPnL }
    }
    
    var totalPnL: Double {
        return totalUnrealizedPnL + totalRealizedPnL
    }
    
    var totalPnLPercent: Double {
        guard totalInvestment > 0 else { return 0 }
        return (totalPnL / totalInvestment) * 100
    }
    
    var activePositions: [Position] {
        positions.filter { $0.isActive }
    }
    
    var closedPositions: [Position] {
        positions.filter { !$0.isActive }
    }
    
    var winRate: Double {
        let closedPositions = self.closedPositions
        guard !closedPositions.isEmpty else { return 0 }
        
        let winners = closedPositions.filter { $0.realizedPnL > 0 }.count
        return (Double(winners) / Double(closedPositions.count)) * 100
    }
    
    var averageWin: Double {
        let winners = closedPositions.filter { $0.realizedPnL > 0 }
        guard !winners.isEmpty else { return 0 }
        
        return winners.reduce(0) { $0 + $1.realizedPnL } / Double(winners.count)
    }
    
    var averageLoss: Double {
        let losers = closedPositions.filter { $0.realizedPnL < 0 }
        guard !losers.isEmpty else { return 0 }
        
        return losers.reduce(0) { $0 + $1.realizedPnL } / Double(losers.count)
    }
    
    var profitFactor: Double {
        let totalWins = closedPositions.filter { $0.realizedPnL > 0 }.reduce(0) { $0 + $1.realizedPnL }
        let totalLosses = abs(closedPositions.filter { $0.realizedPnL < 0 }.reduce(0) { $0 + $1.realizedPnL })
        
        guard totalLosses > 0 else { return totalWins > 0 ? Double.infinity : 0 }
        return totalWins / totalLosses
    }
    
    var sectorAllocation: [String: Double] {
        var allocation: [String: Double] = [:]
        
        for position in activePositions {
            let value = position.currentValue
            allocation[position.sector, default: 0] += value
        }
        
        return allocation
    }
    
    var sectorAllocationPercent: [String: Double] {
        let allocation = sectorAllocation
        let total = totalValue
        
        guard total > 0 else { return [:] }
        
        return allocation.mapValues { ($0 / total) * 100 }
    }
    
    var topPerformers: [Position] {
        activePositions.sorted { $0.unrealizedPnLPercent > $1.unrealizedPnLPercent }.prefix(5).map { $0 }
    }
    
    var worstPerformers: [Position] {
        activePositions.sorted { $0.unrealizedPnLPercent < $1.unrealizedPnLPercent }.prefix(5).map { $0 }
    }
    
    var largestPositions: [Position] {
        activePositions.sorted { $0.currentValue > $1.currentValue }.prefix(5).map { $0 }
    }
    
    var portfolioRisk: Double {
        activePositions.reduce(0) { $0 + $1.riskAmount }
    }
    
    var portfolioRiskPercent: Double {
        guard totalValue > 0 else { return 0 }
        return (portfolioRisk / totalValue) * 100
    }
    
    // Formatted strings
    var formattedTotalValue: String {
        return String(format: "$%.2f", totalValue)
    }
    
    var formattedTotalPnL: String {
        let sign = totalPnL >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", totalPnL))"
    }
    
    var formattedTotalPnLPercent: String {
        let sign = totalPnLPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", totalPnLPercent))%"
    }
}

// MARK: - Sample Data
extension Portfolio {
    static let samplePortfolio = Portfolio(positions: [])
} 