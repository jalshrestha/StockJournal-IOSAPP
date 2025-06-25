import Foundation
import UserNotifications
import Combine

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var priceAlerts: [PriceAlert] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var alertTimer: Timer?
    
    init() {
        requestNotificationPermission()
        startMonitoringAlerts()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Price Alerts
    
    func addPriceAlert(symbol: String, targetPrice: Double, alertType: AlertType, message: String? = nil) {
        let alert = PriceAlert(
            id: UUID(),
            symbol: symbol,
            targetPrice: targetPrice,
            alertType: alertType,
            message: message ?? "Price alert for \(symbol)",
            isActive: true,
            createdDate: Date()
        )
        
        priceAlerts.append(alert)
        scheduleLocalNotification(for: alert)
    }
    
    func removePriceAlert(_ alert: PriceAlert) {
        priceAlerts.removeAll { $0.id == alert.id }
        cancelLocalNotification(for: alert)
    }
    
    func toggleAlert(_ alert: PriceAlert) {
        if let index = priceAlerts.firstIndex(where: { $0.id == alert.id }) {
            priceAlerts[index].isActive.toggle()
            
            if priceAlerts[index].isActive {
                scheduleLocalNotification(for: priceAlerts[index])
            } else {
                cancelLocalNotification(for: priceAlerts[index])
            }
        }
    }
    
    // MARK: - Live Monitoring
    
    private func startMonitoringAlerts() {
        alertTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.checkPriceAlerts()
        }
    }
    
    private func checkPriceAlerts() {
        let activeAlerts = priceAlerts.filter { $0.isActive }
        
        for alert in activeAlerts {
            StockDataService.shared.getStockQuote(symbol: alert.symbol)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Error checking alert for \(alert.symbol): \(error)")
                        }
                    },
                    receiveValue: { stock in
                        self.evaluateAlert(alert, currentPrice: stock.currentPrice)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func evaluateAlert(_ alert: PriceAlert, currentPrice: Double) {
        let shouldTrigger: Bool
        
        switch alert.alertType {
        case .priceAbove:
            shouldTrigger = currentPrice >= alert.targetPrice
        case .priceBelow:
            shouldTrigger = currentPrice <= alert.targetPrice
        case .percentageChange(let _):
            // This would require baseline price - simplified for now
            shouldTrigger = false
        }
        
        if shouldTrigger {
            triggerAlert(alert, currentPrice: currentPrice)
        }
    }
    
    private func triggerAlert(_ alert: PriceAlert, currentPrice: Double) {
        // Send local notification
        sendLocalNotification(
            title: "Price Alert: \(alert.symbol)",
            body: "\(alert.symbol) has reached $\(String(format: "%.2f", currentPrice)). \(alert.message)",
            identifier: alert.id.uuidString
        )
        
        // Optionally disable the alert after triggering
        if let index = priceAlerts.firstIndex(where: { $0.id == alert.id }) {
            priceAlerts[index].isActive = false
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleLocalNotification(for alert: PriceAlert) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Price Alert Set"
        content.body = "Monitoring \(alert.symbol) for \(alert.alertType.description) $\(String(format: "%.2f", alert.targetPrice))"
        content.sound = .default
        
        // For immediate confirmation
        let request = UNNotificationRequest(
            identifier: "alert_set_\(alert.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func cancelLocalNotification(for alert: PriceAlert) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [alert.id.uuidString, "alert_set_\(alert.id.uuidString)"]
        )
    }
    
    private func sendLocalNotification(title: String, body: String, identifier: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    // MARK: - Portfolio Updates
    
    func sendPortfolioUpdate(title: String, message: String) {
        sendLocalNotification(
            title: title,
            body: message,
            identifier: "portfolio_\(UUID().uuidString)"
        )
    }
    
    func sendTradeAlert(symbol: String, action: String, price: Double) {
        sendLocalNotification(
            title: "Trade Alert: \(symbol)",
            body: "\(action) executed at $\(String(format: "%.2f", price))",
            identifier: "trade_\(UUID().uuidString)"
        )
    }
    
    deinit {
        alertTimer?.invalidate()
    }
}

// MARK: - Data Models

struct PriceAlert: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let targetPrice: Double
    let alertType: AlertType
    let message: String
    var isActive: Bool
    let createdDate: Date
}

enum AlertType: Codable {
    case priceAbove
    case priceBelow
    case percentageChange(Double)
    
    var description: String {
        switch self {
        case .priceAbove:
            return "above"
        case .priceBelow:
            return "below"
        case .percentageChange(let percentage):
            return "\(percentage > 0 ? "+" : "")\(String(format: "%.1f", percentage))%"
        }
    }
} 