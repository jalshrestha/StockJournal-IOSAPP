import Foundation
import CoreData

@objc(Position)
public class Position: NSManagedObject {
    
}

extension Position {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Position> {
        return NSFetchRequest<Position>(entityName: "Position")
    }

    @NSManaged public var id: UUID
    @NSManaged public var stockSymbol: String
    @NSManaged public var stockName: String
    @NSManaged public var quantity: Double
    @NSManaged public var buyPrice: Double
    @NSManaged public var currentPrice: Double
    @NSManaged public var stopLoss: Double
    @NSManaged public var priceTarget: Double
    @NSManaged public var thesis: String
    @NSManaged public var dateAdded: Date
    @NSManaged public var isActive: Bool
    @NSManaged public var sector: String
    @NSManaged public var tags: String?
    @NSManaged public var notes: String?
    @NSManaged public var sellPrice: Double
    @NSManaged public var sellDate: Date?
    
    // Computed properties
    var totalInvestment: Double {
        return quantity * buyPrice
    }
    
    var currentValue: Double {
        return quantity * currentPrice
    }
    
    var unrealizedPnL: Double {
        return currentValue - totalInvestment
    }
    
    var unrealizedPnLPercent: Double {
        guard totalInvestment > 0 else { return 0 }
        return (unrealizedPnL / totalInvestment) * 100
    }
    
    var realizedPnL: Double {
        guard !isActive else { return 0 }
        return (sellPrice * quantity) - totalInvestment
    }
    
    var realizedPnLPercent: Double {
        guard totalInvestment > 0, !isActive else { return 0 }
        return (realizedPnL / totalInvestment) * 100
    }
    
    var riskAmount: Double {
        return quantity * abs(buyPrice - stopLoss)
    }
    
    var potentialReward: Double {
        return quantity * abs(priceTarget - buyPrice)
    }
    
    var riskRewardRatio: Double {
        guard riskAmount > 0 else { return 0 }
        return potentialReward / riskAmount
    }
    
    var stopLossPercent: Double {
        guard buyPrice > 0 else { return 0 }
        return ((stopLoss - buyPrice) / buyPrice) * 100
    }
    
    var priceTargetPercent: Double {
        guard buyPrice > 0 else { return 0 }
        return ((priceTarget - buyPrice) / buyPrice) * 100
    }
    
    var tagsArray: [String] {
        guard let tags = tags, !tags.isEmpty else { return [] }
        return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // Formatted strings
    var formattedBuyPrice: String {
        return String(format: "$%.2f", buyPrice)
    }
    
    var formattedCurrentPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedTotalInvestment: String {
        return String(format: "$%.2f", totalInvestment)
    }
    
    var formattedCurrentValue: String {
        return String(format: "$%.2f", currentValue)
    }
    
    var formattedUnrealizedPnL: String {
        let sign = unrealizedPnL >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", unrealizedPnL))"
    }
    
    var formattedRealizedPnL: String {
        let sign = realizedPnL >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", realizedPnL))"
    }
    
    // Additional computed properties needed by views
    var profitLossValue: Double {
        return isActive ? unrealizedPnL : realizedPnL
    }
    
    var profitLossPercent: String {
        let percent = isActive ? unrealizedPnLPercent : realizedPnLPercent
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percent))%"
    }
    
    var profitLoss: String {
        return isActive ? formattedUnrealizedPnL : formattedRealizedPnL
    }
    
    var formattedPositionValue: String {
        return formattedCurrentValue
    }
    
    var progressToTarget: Double {
        guard priceTarget > buyPrice else { return 0 }
        let totalMove = priceTarget - buyPrice
        let currentMove = currentPrice - buyPrice
        return (currentMove / totalMove) * 100
    }
    
    var formattedStopLoss: String {
        return String(format: "$%.2f", stopLoss)
    }
    
    var formattedPriceTarget: String {
        return String(format: "$%.2f", priceTarget)
    }
}

extension Position: Identifiable {
    
}

// MARK: - Sample Data
extension Position {
    static func createSamplePosition(context: NSManagedObjectContext) -> Position {
        let position = Position(context: context)
        position.id = UUID()
        position.stockSymbol = "AAPL"
        position.stockName = "Apple Inc."
        position.quantity = 100
        position.buyPrice = 150.0
        position.currentPrice = 155.0
        position.stopLoss = 140.0
        position.priceTarget = 170.0
        position.thesis = "Long-term growth potential with strong iPhone sales and expanding services revenue. Apple's ecosystem creates high customer retention and pricing power."
        position.dateAdded = Date()
        position.isActive = true
        position.sector = "Technology"
        position.tags = "Growth, Large Cap, Dividend"
        position.notes = "Added on earnings dip, expecting recovery"
        position.sellPrice = 0
        return position
    }
} 