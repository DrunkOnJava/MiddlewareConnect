import SwiftUI

/// Message role for chat bubbles
enum MessageRole: String {
    case user
    case assistant
    case system
    
    var color: Color {
        switch self {
        case .user:
            return DesignSystem.Colors.primary
        case .assistant:
            return DesignSystem.Colors.secondaryBackground
        case .system:
            return Color.gray.opacity(0.3)
        }
    }
    
    var textColor: Color {
        switch self {
        case .user:
            return .white
        case .assistant, .system:
            return DesignSystem.Colors.text
        }
    }
    
    var icon: String {
        switch self {
        case .user:
            return "person.crop.circle.fill"
        case .assistant:
            return "sparkle.magnifyingglass"
        case .system:
            return "info.circle.fill"
        }
    }
    
    var alignment: Alignment {
        switch self {
        case .user:
            return .trailing
        case .assistant, .system:
            return .leading
        }
    }
    
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .user:
            return .trailing
        case .assistant, .system:
            return .leading
        }
    }
}

/// A customizable chat bubble component for message display
struct ChatBubbleView<Content: View>: View {
    /// The role of the message sender (user, assistant, system)
    let role: MessageRole
    
    /// Timestamp for the message
    var timestamp: Date?
    
    /// Whether to show the avatar icon
    var showAvatar: Bool = true
    
    /// Animation state for streaming responses
    var isStreaming: Bool = false
    
    /// Custom avatar view to override the default
    var avatarView: AnyView?
    
    /// Message content
    let content: Content
    
    /// Actions (e.g., copy, regenerate)
    var actions: [ChatMessageAction] = []
    
    /// Action handler
    var onActionTriggered: ((ChatMessageAction) -> Void)?
    
    /// Shows whether actions menu is expanded
    @State private var showActions: Bool = false
    
    /// Shows whether the message is hovered for desktop
    @State private var isHovered: Bool = false
    
    init(
        role: MessageRole,
        timestamp: Date? = nil,
        showAvatar: Bool = true,
        isStreaming: Bool = false,
        avatarView: AnyView? = nil,
        actions: [ChatMessageAction] = [],
        onActionTriggered: ((ChatMessageAction) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.role = role
        self.timestamp = timestamp
        self.showAvatar = showAvatar
        self.isStreaming = isStreaming
        self.avatarView = avatarView
        self.content = content()
        self.actions = actions
        self.onActionTriggered = onActionTriggered
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if role != .user && showAvatar {
                avatarContent
                    .padding(.top, 4)
            }
            
            VStack(alignment: role.horizontalAlignment, spacing: 4) {
                // Content
                content
                    .padding(DesignSystem.Spacing.medium)
                    .foregroundColor(role.textColor)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                    .overlay(overlayContent)
                    .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.medium))
                    .onTapGesture {
                        if !actions.isEmpty {
                            withAnimation {
                                showActions.toggle()
                            }
                        }
                    }
                    .onHover { hovering in
                        withAnimation {
                            isHovered = hovering
                        }
                    }
                
                // Timestamp if available
                if let timestamp = timestamp {
                    Text(formatTimestamp(timestamp))
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, 8)
                }
                
                // Actions popup
                if showActions && !actions.isEmpty {
                    actionsMenu
                }
            }
            .frame(maxWidth: .infinity, alignment: role.alignment)
            
            if role == .user && showAvatar {
                avatarContent
                    .padding(.top, 4)
            }
        }
        .id(role.rawValue) // Ensure unique ID for animations
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibility(label: Text("\(role.rawValue) message"))
    }
    
    // MARK: - Subviews
    
    /// Avatar icon or custom view
    private var avatarContent: some View {
        Group {
            if let customAvatar = avatarView {
                customAvatar
            } else {
                Image(systemName: role.icon)
                    .font(.system(size: 18))
                    .foregroundColor(role == .user ? .white : DesignSystem.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(role == .user ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryBackground)
                    )
                    .overlay(
                        Circle()
                            .stroke(role == .user ? .clear : DesignSystem.Colors.primary, lineWidth: 1)
                    )
            }
        }
        .accessibilityHidden(true)
    }
    
    /// Background of the chat bubble
    private var bubbleBackground: some View {
        role.color
    }
    
    /// Overlay content for the bubble
    @ViewBuilder
    private var overlayContent: some View {
        if isStreaming && role == .assistant {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                .shadow(color: Color.blue.opacity(0.2), radius: 3, x: 0, y: 0)
        } else if isHovered && !actions.isEmpty {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
        }
    }
    
    /// Actions menu
    private var actionsMenu: some View {
        HStack(spacing: 8) {
            ForEach(actions, id: \.id) { action in
                Button(action: {
                    onActionTriggered?(action)
                    
                    withAnimation {
                        showActions = false
                    }
                    
                    DesignSystem.hapticFeedback(.light)
                }) {
                    Label(action.title, systemImage: action.icon)
                        .font(.caption)
                        .frame(height: 28)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.bordered)
                .tint(action.isDestructive ? DesignSystem.Colors.error : nil)
                .controlSize(.small)
            }
        }
        .transition(.opacity)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
    
    // MARK: - Helper Methods
    
    /// Formats the timestamp for display
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // If today, just show time
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

/// Model for chat message actions
struct ChatMessageAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let isDestructive: Bool
    
    static var copy: ChatMessageAction {
        ChatMessageAction(title: "Copy", icon: "doc.on.doc", isDestructive: false)
    }
    
    static var regenerate: ChatMessageAction {
        ChatMessageAction(title: "Regenerate", icon: "arrow.counterclockwise", isDestructive: false)
    }
    
    static var delete: ChatMessageAction {
        ChatMessageAction(title: "Delete", icon: "trash", isDestructive: true)
    }
}

// MARK: - Preview

struct ChatBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // User and assistant conversation
            VStack(spacing: 20) {
                Text("Conversation")
                    .font(DesignSystem.Typography.title2)
                
                ChatBubbleView(
                    role: .user,
                    timestamp: Date()
                ) {
                    Text("Hello, can you explain how machine learning works?")
                }
                
                ChatBubbleView(
                    role: .assistant,
                    timestamp: Date().addingTimeInterval(20),
                    actions: [.copy, .regenerate, .delete]
                ) {
                    Text("Machine learning is a subset of artificial intelligence that enables systems to learn and improve from experience without being explicitly programmed. It focuses on developing programs that can access data and use it to learn for themselves.")
                }
                
                ChatBubbleView(
                    role: .user,
                    timestamp: Date().addingTimeInterval(60)
                ) {
                    Text("Can you give me a simple example?")
                }
                
                ChatBubbleView(
                    role: .assistant,
                    timestamp: Date().addingTimeInterval(80),
                    isStreaming: true
                ) {
                    StreamingResponseView(
                        text: "Sure, a simple example would be an email spam filter that learns from examples of spam and non-spam emails to classify new emails correctly.",
                        isStreaming: true
                    )
                }
                
                ChatBubbleView(
                    role: .system,
                    timestamp: Date().addingTimeInterval(100)
                ) {
                    Text("This conversation uses GPT-4 model with temperature 0.7")
                        .italic()
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Conversation")
            
            // Custom avatar example
            VStack(spacing: 20) {
                Text("Custom Avatar")
                    .font(DesignSystem.Typography.title2)
                
                ChatBubbleView(
                    role: .assistant,
                    avatarView: AnyView(
                        Image(systemName: "brain")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.purple))
                    )
                ) {
                    Text("I'm using a custom brain avatar!")
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Custom Avatar")
            
            // Dark Mode
            VStack(spacing: 20) {
                Text("Dark Mode")
                    .font(DesignSystem.Typography.title2)
                
                ChatBubbleView(
                    role: .user
                ) {
                    Text("How does dark mode look?")
                }
                
                ChatBubbleView(
                    role: .assistant,
                    actions: [.copy]
                ) {
                    Text("Dark mode looks great with the bubbles! The contrast is adjusted automatically.")
                }
            }
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
    }
}
