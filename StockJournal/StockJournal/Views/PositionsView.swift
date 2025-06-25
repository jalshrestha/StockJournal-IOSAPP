import SwiftUI

struct PositionsView: View {
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @State private var showingCloseAlert = false
    @State private var showingDeleteAlert = false
    @State private var selectedPosition: Position?
    @State private var selectedTab: PositionTab = .current
    
    enum PositionTab: CaseIterable {
        case current, history
        
        var title: String {
            switch self {
            case .current: return "Current"
            case .history: return "History"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBarView()
                TabSelectorView()
                PositionListView()
            }
            .navigationTitle("Positions")
            .alert("Close Position", isPresented: $showingCloseAlert, presenting: selectedPosition) { position in
                Button("Cancel", role: .cancel) { }
                Button("Close", role: .destructive) {
                    portfolioViewModel.closePosition(position, sellPrice: position.currentPrice)
                }
            } message: { position in
                Text("Close position for \(position.stockSymbol ?? "N/A") at current price $\(String(format: "%.2f", position.currentPrice))?")
            }
            .alert("Delete Position", isPresented: $showingDeleteAlert, presenting: selectedPosition) { position in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    portfolioViewModel.deletePosition(position)
                }
            } message: { position in
                Text("Are you sure you want to permanently delete the position for \(position.stockSymbol ?? "N/A")?")
            }
        }
        .environmentObject(portfolioViewModel)
    }
    
    @ViewBuilder
    private func SearchBarView() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search positions...", text: $portfolioViewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func TabSelectorView() -> some View {
        HStack {
            ForEach(PositionTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func PositionListView() -> some View {
        let displayedPositions = selectedTab == .current ? 
            portfolioViewModel.positions.filter { $0.isActive } : 
            portfolioViewModel.positions.filter { !$0.isActive }
        
        if displayedPositions.isEmpty {
            EmptyStateView()
        } else {
            List {
                ForEach(displayedPositions) { position in
                    if selectedTab == .current {
                        CurrentPositionCard(position: position)
                            .swipeActions(edge: .leading) {
                                Button("Close") {
                                    selectedPosition = position
                                    showingCloseAlert = true
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete") {
                                    selectedPosition = position
                                    showingDeleteAlert = true
                                }
                                .tint(.red)
                            }
                    } else {
                        HistoryPositionCard(position: position)
                            .swipeActions(edge: .trailing) {
                                Button("Delete") {
                                    selectedPosition = position
                                    showingDeleteAlert = true
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab == .current ? "doc.text.magnifyingglass" : "clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(selectedTab == .current ? "No Current Positions" : "No Trading History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(selectedTab == .current ? 
                 "Add your first position to get started" :
                 "No closed positions yet")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CurrentPositionCard: View {
    let position: Position
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.stockSymbol ?? "")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(position.stockName ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let unrealizedPL = (position.currentPrice - position.buyPrice) * position.quantity
                    Text(unrealizedPL >= 0 ? "+$\(String(format: "%.2f", unrealizedPL))" : "-$\(String(format: "%.2f", abs(unrealizedPL)))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(unrealizedPL >= 0 ? .green : .red)
                    
                    let unrealizedPLPercentage = ((position.currentPrice - position.buyPrice) / position.buyPrice) * 100
                    Text(unrealizedPLPercentage >= 0 ? "+\(String(format: "%.2f", unrealizedPLPercentage))%" : "\(String(format: "%.2f", unrealizedPLPercentage))%")
                        .font(.subheadline)
                        .foregroundColor(unrealizedPL >= 0 ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(position.quantity))")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Buy Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", position.buyPrice))
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", position.currentPrice))")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HistoryPositionCard: View {
    let position: Position
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.stockSymbol ?? "")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(position.stockName ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let realizedPL = (position.sellPrice - position.buyPrice) * position.quantity
                    Text(realizedPL >= 0 ? "+$\(String(format: "%.2f", realizedPL))" : "-$\(String(format: "%.2f", abs(realizedPL)))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(realizedPL >= 0 ? .green : .red)
                    
                    let realizedPLPercentage = ((position.sellPrice - position.buyPrice) / position.buyPrice) * 100
                    Text(realizedPLPercentage >= 0 ? "+\(String(format: "%.2f", realizedPLPercentage))%" : "\(String(format: "%.2f", realizedPLPercentage))%")
                        .font(.subheadline)
                        .foregroundColor(realizedPL >= 0 ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quantity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(position.quantity))")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Buy Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", position.buyPrice))
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sell Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", position.sellPrice))")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                let realizedPL = (position.sellPrice - position.buyPrice) * position.quantity
                Text(realizedPL >= 0 ? "PROFIT" : "LOSS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(realizedPL >= 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(realizedPL >= 0 ? .green : .red)
                    .cornerRadius(4)
                
                Spacer()
                
                if let sellDate = position.sellDate {
                    Text("Closed: \(sellDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PositionsView()
        .environmentObject(PortfolioViewModel())
} 