/**
@fileoverview Split Strategy Selector component for PDF splitting
@module SplitStrategySelector
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
Exports:
- SplitStrategySelector
Notes:
- Component for selecting PDF splitting strategies
- Provides visual representation of available strategies
/

import SwiftUI

/// Component for selecting PDF splitting strategies
public struct SplitStrategySelector: View {
    // MARK: - Properties
    
    /// Binding to the selected strategy
    @Binding var selectedStrategy: SplitStrategy?
    
    /// Available strategies
    let strategies: [SplitStrategy]
    
    /// Display mode
    let displayMode: DisplayMode
    
    // MARK: - Initialization
    
    /// Initialize with strategies and selected strategy
    /// - Parameters:
    ///   - selectedStrategy: Binding to the selected strategy
    ///   - strategies: Available strategies
    ///   - displayMode: Display mode (default: .card)
    public init(
        selectedStrategy: Binding<SplitStrategy?>,
        strategies: [SplitStrategy],
        displayMode: DisplayMode = .card
    ) {
        self._selectedStrategy = selectedStrategy
        self.strategies = strategies
        self.displayMode = displayMode
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch displayMode {
            case .card:
                cardLayout
            case .list:
                listLayout
            case .compact:
                compactLayout
            }
        }
    }
    
    // MARK: - Layouts
    
    /// Card layout
    private var cardLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(strategies) { strategy in
                    StrategyCard(
                        strategy: strategy,
                        isSelected: strategy.id == selectedStrategy?.id,
                        action: {
                            withAnimation {
                                selectedStrategy = strategy
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// List layout
    private var listLayout: some View {
        VStack(spacing: 4) {
            ForEach(strategies) { strategy in
                StrategyListItem(
                    strategy: strategy,
                    isSelected: strategy.id == selectedStrategy?.id,
                    action: {
                        withAnimation {
                            selectedStrategy = strategy
                        }
                    }
                )
            }
        }
    }
    
    /// Compact layout
    private var compactLayout: some View {
        Picker("Strategy", selection: $selectedStrategy) {
            ForEach(strategies) { strategy in
                HStack {
                    Image(systemName: strategy.iconName)
                    Text(strategy.name)
                }
                .tag(strategy as SplitStrategy?)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    // MARK: - Display Modes
    
    /// Display mode options
    public enum DisplayMode {
        case card     // Card layout with icons and descriptions
        case list     // Vertical list with details
        case compact  // Compact dropdown/picker
    }
}

// MARK: - Supporting Views

/// Card view for a strategy
struct StrategyCard: View {
    let strategy: SplitStrategy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon
                HStack {
                    Image(systemName: strategy.iconName)
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // Title
                Text(strategy.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Description
                Text(strategy.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 220, height: 150)
            .background(isSelected ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// List item for a strategy
struct StrategyListItem: View {
    let strategy: SplitStrategy
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Icon
                Image(systemName: strategy.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 30)
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct SplitStrategySelector_Previews: PreviewProvider {
    static var previews: some View {
        let strategies = [
            SplitStrategy(
                type: .byPage,
                name: "By Page Count",
                description: "Split PDF into chunks with a specific number of pages",
                iconName: "doc.on.doc"
            ),
            SplitStrategy(
                type: .byPageRange,
                name: "By Page Ranges",
                description: "Split PDF using custom page ranges",
                iconName: "text.insert"
            ),
            SplitStrategy(
                type: .byBookmark,
                name: "By Bookmarks",
                description: "Split PDF at bookmark/outline entries",
                iconName: "bookmark"
            )
        ]
        
        return Group {
            SplitStrategySelector(
                selectedStrategy: .constant(strategies.first),
                strategies: strategies,
                displayMode: .card
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Card Layout")
            
            SplitStrategySelector(
                selectedStrategy: .constant(strategies.first),
                strategies: strategies,
                displayMode: .list
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("List Layout")
            
            SplitStrategySelector(
                selectedStrategy: .constant(strategies.first),
                strategies: strategies,
                displayMode: .compact
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .previewDisplayName("Compact Layout")
        }
    }
}
