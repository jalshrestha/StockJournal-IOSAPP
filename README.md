# 📈 Stock Journal - iOS Portfolio Tracker

A comprehensive iOS app for tracking your stock portfolio, built with SwiftUI and Core Data.

## ✨ Features

### 📊 Portfolio Management
- **Real-time Portfolio Overview** - Track total value, P&L, and performance metrics
- **Position Tracking** - Manage active and closed positions with detailed analytics
- **Live Stock Data** - Real-time price updates via Alpha Vantage API
- **Risk Management** - Built-in position sizing calculator and risk metrics

### 📈 Analytics & Insights
- **Interactive Charts** - Multiple timeframes (1D, 5D, 1M, 3M, 1Y)
- **Performance Analytics** - Win rate, profit factor, average win/loss
- **Sector Allocation** - Visualize portfolio diversification
- **Top/Worst Performers** - Quick identification of best and worst positions

### 🔔 Smart Alerts
- **Price Alerts** - Get notified when stocks hit target prices
- **Custom Notifications** - Set alerts for percentage changes
- **Portfolio Updates** - Stay informed about significant portfolio changes

### 🎨 User Experience
- **Dark/Light Mode** - Seamless theme switching
- **Custom Accent Colors** - Personalize your app experience
- **Stock Search** - Find and add new positions easily
- **Data Export** - Export portfolio data for external analysis

## 🛠 Technical Stack

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Database**: Core Data with iCloud sync
- **API**: Alpha Vantage for real-time stock data
- **Notifications**: UserNotifications framework
- **Persistence**: SQLite via Core Data

## 🚀 Getting Started

### Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- Alpha Vantage API key (free tier available)

### Installation
1. Clone the repository:
   ```bash
   git clone git@github.com:jalshrestha/StockJournal-IOSAPP.git
   ```

2. Open `StockJournal.xcodeproj` in Xcode

3. Add your Alpha Vantage API key in `StockDataService.swift`:
   ```swift
   private let apiKey = "YOUR_API_KEY_HERE"
   ```

4. Build and run the project

### API Key Setup
1. Visit [Alpha Vantage](https://www.alphavantage.co/support/#api-key) to get a free API key
2. Replace the placeholder in `StockDataService.swift` with your actual API key

## 📱 App Structure

```
StockJournal/
├── Models/
│   ├── Portfolio.swift      # Portfolio data model
│   ├── Position.swift       # Position entity
│   ├── Stock.swift          # Stock data model
│   └── ChartData.swift      # Chart data structures
├── Views/
│   ├── PortfolioView.swift  # Main portfolio overview
│   ├── PositionsView.swift  # Position list and management
│   ├── AddPositionView.swift # Add new positions
│   ├── AnalyticsView.swift  # Portfolio analytics
│   └── SettingsView.swift   # App settings
├── ViewModels/
│   └── PortfolioViewModel.swift # Main business logic
├── Services/
│   ├── StockDataService.swift   # API integration
│   └── NotificationService.swift # Push notifications
├── Managers/
│   └── ThemeManager.swift   # Theme and color management
└── Persistence.swift        # Core Data stack
```

## 💾 Data Storage

- **Local Storage**: SQLite database via Core Data
- **iCloud Sync**: Automatic synchronization across devices
- **Privacy**: All portfolio data remains on your devices
- **Backup**: Included in iOS device backups

## 🔒 Privacy & Security

- Portfolio data never leaves Apple's ecosystem
- Stock prices fetched from Alpha Vantage (no personal data shared)
- Local encryption when device is locked
- No third-party analytics or tracking

## 🛣 Roadmap

- [ ] Apple Watch companion app
- [ ] Widget support for iOS home screen
- [ ] Advanced technical indicators
- [ ] News integration for holdings
- [ ] Options tracking support
- [ ] Tax reporting features

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support or questions, please open an issue on GitHub.

---

**Built with ❤️ using SwiftUI** 