/**
@fileoverview List Item components for MiddlewareConnect
@module ListItem
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
- DesignSystem
Exports:
- MCListItem struct
- MCConversationListItem struct
- MCModelListItem struct
/

import SwiftUI

/// Standard list item component with various configurations
public struct MCListItem: View {
    // MARK: - Properties
    
    /// Title text
    private let title: String
    
    /// Subtitle text (optional)
    private let subtitle: String?
    
    /// Description text (optional)
    private let description: String?
    
    /// Leading icon (optional)
    private let leadingIcon: String?
    
    /// Trailing icon (optional)
    private let trailingIcon: String?
    
    /// Leading image (optional)
    private let leadingImage: Image?
    
    /// Color for the leading icon/image
    private let iconColor: Color?
    
    /// Custom background color
    private let backgroundColor: Color
    
    /// Selected state
    private let isSelected: Bool
    
    /// Whether to show a divider below
    private let showDivider: Bool
    
    /// Action when tapped
    private let action: (() -> Void)?
    
    /// Context menu items if any
    private let contextMenu: [ContextMenuItem]?
    
    /// Context menu item definition
    public struct ContextMenuItem: Identifiable {
        public var id = UUID()
        let title: String
        let icon: String
        let action: () -> Void
        let isDestructive: Bool
        
        public init(title: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.isDestructive = isDestructive
            self.action = action
        }
    }
    
    // MARK: - Initializers
    
    /// Initialize a list item with title, subtitle and icons
    public init(
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        leadingImage: Image? = nil,
        iconColor: Color? = nil,
        backgroundColor: Color = Color.clear,
        isSelected: Bool = false,
        showDivider: Bool = true,
        action: (() -> Void)? = nil,
        contextMenu: [ContextMenuItem]? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.leadingImage = leadingImage
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.isSelected = isSelected
        self.showDivider = showDivider
        self.action = action
        self.contextMenu = contextMenu
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: { 
            if let action = action {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    // Leading icon or image
                    if let icon = leadingIcon {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(iconColor ?? DesignSystem.Colors.gray600)
                            .frame(width: 24, height: 24)
                    } else if let image = leadingImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .cornerRadius(DesignSystem.Sizing.cornerSmall)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text(title)
                            .font(DesignSystem.Typography.bodyMedium.weight(.medium))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(DesignSystem.Typography.bodySmall)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        if let description = description {
                            Text(description)
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .lineLimit(2)
                                .padding(.top, DesignSystem.Spacing.xxs)
                        }
                    }
                    
                    Spacer()
                    
                    // Trailing icon
                    if let icon = trailingIcon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.gray400)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.s)
                .padding(.horizontal, DesignSystem.Spacing.m)
                .background(
                    isSelected ? 
                        DesignSystem.Colors.primary.opacity(0.1) :
                        backgroundColor
                )
                
                // Divider
                if showDivider {
                    Divider()
                        .padding(.leading, leadingIcon == nil && leadingImage == nil ? 
                                DesignSystem.Spacing.m : 64)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
        .contextMenu(contextMenu.map { items in
            ContextMenu {
                ForEach(items) { item in
                    Button(action: item.action) {
                        Label(item.title, systemImage: item.icon)
                    }
                    .foregroundColor(item.isDestructive ? DesignSystem.Colors.error : nil)
                }
            }
        })
    }
}

/// Specialized list item for displaying conversations
public struct MCConversationListItem: View {
    // MARK: - Properties
    
    /// Conversation to display
    private let conversation: Conversation
    
    /// Whether the conversation is selected
    private let isSelected: Bool
    
    /// Action when tapped
    private let action: () -> Void
    
    /// Context menu actions
    private let onRename: (() -> Void)?
    private let onShare: (() -> Void)?
    private let onDelete: (() -> Void)?
    
    // MARK: - Initializers
    
    /// Initialize with a conversation
    public init(
        conversation: Conversation,
        isSelected: Bool = false,
        action: @escaping () -> Void,
        onRename: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.conversation = conversation
        self.isSelected = isSelected
        self.action = action
        self.onRename = onRename
        self.onShare = onShare
        self.onDelete = onDelete
    }
    
    // MARK: - Body
    
    public var body: some View {
        let contextItems = buildContextMenu()
        
        MCListItem(
            title: conversation.title,
            subtitle: "\(conversation.messages.count) messages",
            description: conversation.messages.last?.content.prefix(80).appending(conversation.messages.last?.content.count ?? 0 > 80 ? "..." : "") ?? "",
            leadingIcon: getIconForModel(conversation.model),
            iconColor: getColorForModel(conversation.model),
            isSelected: isSelected,
            action: action,
            contextMenu: contextItems
        )
    }
    
    // MARK: - Helper Methods
    
    /// Build context menu items based on available actions
    private func buildContextMenu() -> [MCListItem.ContextMenuItem]? {
        var items = [MCListItem.ContextMenuItem]()
        
        if let onRename = onRename {
            items.append(MCListItem.ContextMenuItem(
                title: "Rename",
                icon: "pencil",
                action: onRename
            ))
        }
        
        if let onShare = onShare {
            items.append(MCListItem.ContextMenuItem(
                title: "Share",
                icon: "square.and.arrow.up",
                action: onShare
            ))
        }
        
        if let onDelete = onDelete {
            items.append(MCListItem.ContextMenuItem(
                title: "Delete",
                icon: "trash",
                isDestructive: true,
                action: onDelete
            ))
        }
        
        return items.isEmpty ? nil : items
    }
    
    /// Get icon for model
    private func getIconForModel(_ model: LLMModel) -> String {
        switch model.provider {
        case .anthropic:
            return "a.circle.fill"
        case .openai:
            return "o.circle.fill"
        case .google:
            return "g.circle.fill"
        case .mistral:
            return "m.circle.fill"
        case .meta:
            return "m.square.fill"
        case .local:
            return "desktopcomputer"
        }
    }
    
    /// Get color for model
    private func getColorForModel(_ model: LLMModel) -> Color {
        model.color
    }
}

/// Specialized list item for displaying LLM models
public struct MCModelListItem: View {
    // MARK: - Properties
    
    /// Model to display
    private let model: LLMModel
    
    /// Whether the model is selected
    private let isSelected: Bool
    
    /// Whether to show the token count
    private let showTokenCount: Bool
    
    /// Whether the model is available (has API key)
    private let isAvailable: Bool
    
    /// Action when tapped
    private let action: () -> Void
    
    // MARK: - Initializers
    
    /// Initialize with an LLM model
    public init(
        model: LLMModel,
        isSelected: Bool = false,
        showTokenCount: Bool = true,
        isAvailable: Bool = true,
        action: @escaping () -> Void
    ) {
        self.model = model
        self.isSelected = isSelected
        self.showTokenCount = showTokenCount
        self.isAvailable = isAvailable
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        MCListItem(
            title: model.displayName,
            subtitle: showTokenCount ? "Context window: \(formatTokenCount(model.contextWindow)) tokens" : model.providerName,
            description: isAvailable ? nil : "API key required",
            leadingIcon: getIconForModel(model),
            trailingIcon: isSelected ? "checkmark" : nil,
            iconColor: getColorForModel(model),
            backgroundColor: isAvailable ? Color.clear : DesignSystem.Colors.gray100,
            isSelected: isSelected,
            action: isAvailable ? action : nil
        )
    }
    
    // MARK: - Helper Methods
    
    /// Format token count with thousands separator
    private func formatTokenCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
    
    /// Get icon for model
    private func getIconForModel(_ model: LLMModel) -> String {
        switch model.provider {
        case .anthropic:
            return "a.circle.fill"
        case .openai:
            return "o.circle.fill"
        case .google:
            return "g.circle.fill"
        case .mistral:
            return "m.circle.fill"
        case .meta:
            return "m.square.fill"
        case .local:
            return "desktopcomputer"
        }
    }
    
    /// Get color for model
    private func getColorForModel(_ model: LLMModel) -> Color {
        model.color
    }
}

// MARK: - Previews
struct MCListItem_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                Group {
                    MCListItem(
                        title: "Basic List Item",
                        action: {}
                    )
                    
                    MCListItem(
                        title: "List Item with Subtitle",
                        subtitle: "This is a subtitle"
                    )
                    
                    MCListItem(
                        title: "List Item with Description",
                        subtitle: "Subtitle text",
                        description: "This is a longer description that can span multiple lines and provides more details about this item."
                    )
                    
                    MCListItem(
                        title: "List Item with Leading Icon",
                        subtitle: "With custom icon color",
                        leadingIcon: "star.fill",
                        iconColor: DesignSystem.Colors.accent
                    )
                    
                    MCListItem(
                        title: "List Item with Trailing Icon",
                        trailingIcon: "chevron.right"
                    )
                    
                    MCListItem(
                        title: "Selected List Item",
                        subtitle: "This item is in selected state",
                        leadingIcon: "checkmark.circle.fill",
                        isSelected: true
                    )
                    
                    MCListItem(
                        title: "List Item with Context Menu",
                        subtitle: "Right-click or long-press",
                        leadingIcon: "ellipsis.circle",
                        contextMenu: [
                            MCListItem.ContextMenuItem(
                                title: "Edit",
                                icon: "pencil",
                                action: {}
                            ),
                            MCListItem.ContextMenuItem(
                                title: "Share",
                                icon: "square.and.arrow.up",
                                action: {}
                            ),
                            MCListItem.ContextMenuItem(
                                title: "Delete",
                                icon: "trash",
                                isDestructive: true,
                                action: {}
                            )
                        ]
                    )
                }
                
                Group {
                    // Conversation List Item Examples
                    Text("Conversation Items")
                        .font(DesignSystem.Typography.headingSmall)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(DesignSystem.Colors.gray100)
                    
                    MCConversationListItem(
                        conversation: Conversation(
                            title: "Claude Conversation",
                            messages: [
                                Conversation.Message(content: "Hello, I'm Claude!", isUser: false),
                                Conversation.Message(content: "Can you help me with a coding question?", isUser: true),
                                Conversation.Message(content: "Certainly! What would you like to know about coding?", isUser: false)
                            ],
                            model: .claudeSonnet
                        ),
                        action: {}
                    )
                    
                    MCConversationListItem(
                        conversation: Conversation(
                            title: "GPT-4 Conversation",
                            messages: [
                                Conversation.Message(content: "Hello, I'm GPT-4!", isUser: false),
                                Conversation.Message(content: "How can generative AI be applied to healthcare?", isUser: true),
                                Conversation.Message(content: "Generative AI in healthcare has numerous applications including medical imaging analysis, drug discovery, personalized treatment plans, and clinical documentation automation...", isUser: false)
                            ],
                            model: .gpt4
                        ),
                        isSelected: true,
                        action: {},
                        onRename: {},
                        onShare: {},
                        onDelete: {}
                    )
                }
                
                Group {
                    // Model List Item Examples
                    Text("Model Items")
                        .font(DesignSystem.Typography.headingSmall)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(DesignSystem.Colors.gray100)
                    
                    MCModelListItem(
                        model: .claudeSonnet,
                        isSelected: true,
                        action: {}
                    )
                    
                    MCModelListItem(
                        model: .gpt4,
                        action: {}
                    )
                    
                    MCModelListItem(
                        model: .mistral7B,
                        isAvailable: false,
                        action: {}
                    )
                }
            }
        }
    }
}
