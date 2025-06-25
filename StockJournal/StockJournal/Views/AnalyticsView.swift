import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab: JournalTab = .entries
    @State private var showingAddEntry = false
    @State private var journalEntries: [JournalEntry] = []
    @State private var newEntryTitle = ""
    @State private var newEntryContent = ""
    @State private var selectedMood: TradingMood = .neutral
    @State private var selectedPosition: Position?
    
    enum JournalTab: String, CaseIterable {
        case entries = "Journal Entries"
        case lessons = "Lessons Learned"
        case goals = "Trading Goals"
        case reviews = "Trade Reviews"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                tabSelector
                
                // Content Area
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedTab {
                        case .entries:
                            journalEntriesView
                        case .lessons:
                            lessonsLearnedView
                        case .goals:
                            tradingGoalsView
                        case .reviews:
                            tradeReviewsView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Trading Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddJournalEntryView(
                title: $newEntryTitle,
                content: $newEntryContent,
                mood: $selectedMood,
                position: $selectedPosition,
                onSave: addJournalEntry
            )
        }
        .onAppear {
            loadSampleData()
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JournalTab.allCases, id: \.self) { tab in
                    Button(tab.rawValue) {
                        selectedTab = tab
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? themeManager.primaryColor : themeManager.secondaryBackgroundColor)
                    .foregroundColor(selectedTab == tab ? .white : themeManager.textSecondaryColor)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Journal Entries View
    
    private var journalEntriesView: some View {
        VStack(spacing: 16) {
            if journalEntries.isEmpty {
                emptyJournalState
            } else {
                ForEach(journalEntries) { entry in
                    JournalEntryCard(entry: entry)
                }
            }
        }
    }
    
    // MARK: - Lessons Learned View
    
    private var lessonsLearnedView: some View {
        VStack(spacing: 16) {
            LessonCard(
                title: "Risk Management is Key",
                lesson: "Never risk more than 2% of your portfolio on a single trade. Setting stop losses is crucial for preserving capital.",
                date: Date().addingTimeInterval(-86400 * 7),
                category: "Risk Management"
            )
            
            LessonCard(
                title: "Patience Pays Off",
                lesson: "Waiting for the right setup is better than forcing trades. Quality over quantity always wins in the long run.",
                date: Date().addingTimeInterval(-86400 * 14),
                category: "Psychology"
            )
            
            LessonCard(
                title: "Cut Losses Early",
                lesson: "Admitting when you're wrong and cutting losses quickly prevents small losses from becoming large ones.",
                date: Date().addingTimeInterval(-86400 * 21),
                category: "Execution"
            )
        }
    }
    
    // MARK: - Trading Goals View
    
    private var tradingGoalsView: some View {
        VStack(spacing: 16) {
            GoalCard(
                title: "Monthly Return Target",
                target: "5%",
                current: "3.2%",
                progress: 0.64,
                color: themeManager.primaryColor
            )
            
            GoalCard(
                title: "Win Rate Goal",
                target: "70%",
                current: portfolioViewModel.winRate,
                progress: 0.58,
                color: themeManager.positiveColor
            )
            
            GoalCard(
                title: "Maximum Drawdown",
                target: "10%",
                current: "4.2%",
                progress: 0.58,
                color: themeManager.negativeColor
            )
            
            GoalCard(
                title: "Number of Trades",
                target: "20",
                current: "\(portfolioViewModel.positions.count)",
                progress: Double(portfolioViewModel.positions.count) / 20.0,
                color: themeManager.neutralColor
            )
        }
    }
    
    // MARK: - Trade Reviews View
    
    private var tradeReviewsView: some View {
        VStack(spacing: 16) {
            ForEach(portfolioViewModel.positions.prefix(5)) { position in
                TradeReviewCard(position: position)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyJournalState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textSecondaryColor)
            
            VStack(spacing: 8) {
                Text("Start Your Trading Journal")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text("Document your trading journey, track lessons learned, and reflect on your decisions to become a better trader.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button("Add First Entry") {
                showingAddEntry = true
            }
            .font(.headline.weight(.medium))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(themeManager.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Helper Methods
    
    private func addJournalEntry() {
        let entry = JournalEntry(
            title: newEntryTitle,
            content: newEntryContent,
            mood: selectedMood,
            position: selectedPosition,
            date: Date()
        )
        journalEntries.insert(entry, at: 0)
        
        // Clear form
        newEntryTitle = ""
        newEntryContent = ""
        selectedMood = .neutral
        selectedPosition = nil
        showingAddEntry = false
    }
    
    private func loadSampleData() {
        if journalEntries.isEmpty {
            journalEntries = [
                JournalEntry(
                    title: "Learning from AAPL Trade",
                    content: "Today I bought AAPL at $175. The technical setup looked good with a clean breakout above resistance. I'm feeling confident about this trade but need to stick to my stop loss at $170.",
                    mood: .optimistic,
                    position: portfolioViewModel.positions.first,
                    date: Date().addingTimeInterval(-86400)
                ),
                JournalEntry(
                    title: "Market Volatility Reflection",
                    content: "The market has been quite volatile lately. I'm learning to be more patient and not rush into trades. Sometimes the best trade is no trade at all.",
                    mood: .cautious,
                    position: nil,
                    date: Date().addingTimeInterval(-86400 * 3)
                )
            ]
        }
    }
}

// MARK: - Supporting Models

struct JournalEntry: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let mood: TradingMood
    let position: Position?
    let date: Date
}

enum TradingMood: String, CaseIterable {
    case optimistic = "Optimistic"
    case confident = "Confident"
    case neutral = "Neutral"
    case cautious = "Cautious"
    case concerned = "Concerned"
    
    var emoji: String {
        switch self {
        case .optimistic: return "😊"
        case .confident: return "💪"
        case .neutral: return "😐"
        case .cautious: return "🤔"
        case .concerned: return "😰"
        }
    }
    
    var color: Color {
        switch self {
        case .optimistic, .confident: return .green
        case .neutral: return .blue
        case .cautious: return .orange
        case .concerned: return .red
        }
    }
}

// MARK: - Supporting Views

struct JournalEntryCard: View {
    let entry: JournalEntry
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(entry.mood.emoji)
                        .font(.title2)
                    Text(entry.mood.rawValue)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(entry.mood.color.opacity(0.1))
                        .foregroundColor(entry.mood.color)
                        .cornerRadius(8)
                }
            }
            
            Text(entry.content)
                .font(.body)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(nil)
            
            if let position = entry.position {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(themeManager.primaryColor)
                    Text("Related to \(position.stockSymbol)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(themeManager.primaryColor)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct LessonCard: View {
    let title: String
    let lesson: String
    let date: Date
    let category: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                Text(category)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.primaryColor.opacity(0.1))
                    .foregroundColor(themeManager.primaryColor)
                    .cornerRadius(8)
            }
            
            Text(lesson)
                .font(.body)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(nil)
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct GoalCard: View {
    let title: String
    let target: String
    let current: String
    let progress: Double
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(current) / \(target)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(color)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }
            
            ProgressView(value: min(progress, 1.0))
                .tint(color)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct TradeReviewCard: View {
    let position: Position
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.stockSymbol)
                        .font(.headline.weight(.bold))
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text(position.dateAdded, style: .date)
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(position.profitLoss)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
                    
                    Text(position.profitLossPercent)
                        .font(.caption)
                        .foregroundColor(themeManager.colorForPerformance(position.profitLossValue))
                }
            }
            
            if !position.thesis.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Investment Thesis:")
                        .font(.caption.weight(.medium))
                        .foregroundColor(themeManager.textSecondaryColor)
                    
                    Text(position.thesis)
                        .font(.body)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .lineLimit(3)
                }
            }
            
            HStack {
                Label("Entry: \(position.formattedBuyPrice)", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
                
                Spacer()
                
                Label("Target: \(position.formattedPriceTarget)", systemImage: "target")
                    .font(.caption)
                    .foregroundColor(themeManager.positiveColor)
            }
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct AddJournalEntryView: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var mood: TradingMood
    @Binding var position: Position?
    let onSave: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry Title")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        TextField("What's on your mind?", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Thoughts")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                            .background(themeManager.secondaryBackgroundColor)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Mood")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Picker("Mood", selection: $mood) {
                            ForEach(TradingMood.allCases, id: \.self) { mood in
                                HStack {
                                    Text(mood.emoji)
                                    Text(mood.rawValue)
                                }
                                .tag(mood)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Position (Optional)")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Picker("Position", selection: $position) {
                            Text("None").tag(Position?.none)
                            ForEach(portfolioViewModel.positions) { pos in
                                Text(pos.stockSymbol).tag(Optional(pos))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
            }
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(ThemeManager())
        .environmentObject(PortfolioViewModel())
} 