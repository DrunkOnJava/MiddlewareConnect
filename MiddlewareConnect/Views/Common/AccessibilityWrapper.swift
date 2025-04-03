import SwiftUI

/// A wrapper view that adds accessibility features to any view
struct AccessibilityWrapper<Content: View>: View {
    /// The content view to wrap
    let content: Content
    
    /// Accessibility label
    var label: String?
    
    /// Accessibility hint
    var hint: String?
    
    /// Accessibility traits
    var traits: AccessibilityTraits = []
    
    /// Accessibility identifier (for UI testing)
    var identifier: String?
    
    /// Whether the element is hidden from accessibility
    var isHidden: Bool = false
    
    /// Whether to combine children into this element
    var combineChildren: Bool = false
    
    /// Sort priority for accessibility
    var sortPriority: Double?
    
    /// Accessibility add traits to add (doesn't replace existing traits)
    var addTraits: AccessibilityTraits = []
    
    /// Accessibility remove traits
    var removeTraits: AccessibilityTraits = []
    
    /// Accessibility adjustable action
    var adjustableAction: ((AccessibilityAdjustmentDirection) -> Void)?
    
    /// Focus state for keyboard and accessibility focus support
    @FocusState private var isFocused: Bool
    
    /// Whether this element can get accessibility focus
    var canBeFocused: Bool = false
    
    /// Action to perform when focused
    var onFocusAction: (() -> Void)?
    
    /// Initializer
    init(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        identifier: String? = nil,
        isHidden: Bool = false,
        combineChildren: Bool = false,
        sortPriority: Double? = nil,
        addTraits: AccessibilityTraits = [],
        removeTraits: AccessibilityTraits = [],
        adjustableAction: ((AccessibilityAdjustmentDirection) -> Void)? = nil,
        canBeFocused: Bool = false,
        onFocusAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.label = label
        self.hint = hint
        self.traits = traits
        self.identifier = identifier
        self.isHidden = isHidden
        self.combineChildren = combineChildren
        self.sortPriority = sortPriority
        self.addTraits = addTraits
        self.removeTraits = removeTraits
        self.adjustableAction = adjustableAction
        self.canBeFocused = canBeFocused
        self.onFocusAction = onFocusAction
    }
    
    var body: some View {
        content
            // Basic accessibility modifiers
            .accessibility(label: label != nil ? Text(label!) : nil)
            .accessibility(hint: hint != nil ? Text(hint!) : nil)
            .accessibility(hidden: isHidden)
            .accessibility(identifier: identifier)
            
            // Additional accessibility options
            .accessibility(addTraits: addTraits)
            .accessibility(removeTraits: removeTraits)
            .accessibility(sortPriority: sortPriority ?? 0)
            
            // Children handling
            .accessibilityElement(children: combineChildren ? .combine : .contain)
            
            // If specified, make this an adjustable element
            .accessibilityAdjustableAction(adjustableAction)
            
            // Focus handling
            .focused($isFocused)
            .onChange(of: isFocused) { focused in
                if focused && canBeFocused {
                    onFocusAction?()
                }
            }
    }
}

/// An accessibility wrapper specifically for buttons
struct AccessibleButton<Content: View>: View {
    /// The content view of the button
    let content: Content
    
    /// Accessibility label
    var label: String
    
    /// Accessibility hint
    var hint: String?
    
    /// Additional traits beyond button trait
    var additionalTraits: AccessibilityTraits = []
    
    /// Action to perform when the button is tapped
    var action: () -> Void
    
    /// Initializer
    init(
        label: String,
        hint: String? = nil,
        additionalTraits: AccessibilityTraits = [],
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.label = label
        self.hint = hint
        self.additionalTraits = additionalTraits
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            AccessibilityWrapper(
                label: label,
                hint: hint,
                addTraits: [.isButton] + additionalTraits
            ) {
                content
            }
        }
    }
}

/// An accessibility wrapper specifically for images
struct AccessibleImage: View {
    /// The name of the image
    let imageName: String
    
    /// Accessibility label
    var label: String
    
    /// Accessibility hint
    var hint: String?
    
    /// Whether the image is decorative (hidden from accessibility)
    var isDecorative: Bool = false
    
    /// Additional modifiers for the image
    var renderingMode: Image.TemplateRenderingMode? = nil
    var resizable: Bool = false
    var interpolation: Image.Interpolation = .medium
    var antialiased: Bool = false
    
    var body: some View {
        let image = Image(imageName)
            .applyIf(renderingMode != nil) { image in
                image.renderingMode(renderingMode!)
            }
            .applyIf(resizable) { image in
                image.resizable()
            }
            .interpolation(interpolation)
            .antialiased(antialiased)
        
        AccessibilityWrapper(
            label: isDecorative ? nil : label,
            hint: isDecorative ? nil : hint,
            isHidden: isDecorative,
            addTraits: isDecorative ? [] : [.isImage]
        ) {
            image
        }
    }
}

/// An accessibility wrapper for system images
struct AccessibleSystemImage: View {
    /// The name of the system image
    let systemName: String
    
    /// Accessibility label
    var label: String
    
    /// Accessibility hint
    var hint: String?
    
    /// Whether the image is decorative (hidden from accessibility)
    var isDecorative: Bool = false
    
    /// Additional modifiers for the image
    var renderingMode: Image.TemplateRenderingMode? = nil
    var font: Font? = nil
    var foregroundColor: Color? = nil
    
    var body: some View {
        var image = Image(systemName: systemName)
        
        if let renderingMode = renderingMode {
            image = image.renderingMode(renderingMode)
        }
        
        return AccessibilityWrapper(
            label: isDecorative ? nil : label,
            hint: isDecorative ? nil : hint,
            isHidden: isDecorative,
            addTraits: isDecorative ? [] : [.isImage]
        ) {
            image
                .applyIf(font != nil) { view in
                    view.font(font)
                }
                .applyIf(foregroundColor != nil) { view in
                    view.foregroundColor(foregroundColor)
                }
        }
    }
}

// MARK: - Helper Extensions

extension View {
    /// Conditionally applies a transformation to a view
    @ViewBuilder func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

struct AccessibilityWrapper_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                Text("Accessibility Components")
                    .font(.title)
                    .padding(.bottom, 20)
                
                // Basic wrapper
                AccessibilityWrapper(
                    label: "Example wrapped text",
                    hint: "This demonstrates the accessibility wrapper"
                ) {
                    Text("Wrapped Text")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Accessible button
                AccessibleButton(
                    label: "Example accessible button",
                    hint: "Tap to trigger action",
                    action: {}
                ) {
                    Text("Accessible Button")
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Accessible System Image
                HStack(spacing: 20) {
                    AccessibleSystemImage(
                        systemName: "heart.fill",
                        label: "Heart icon",
                        foregroundColor: .red
                    )
                    .font(.system(size: 30))
                    
                    AccessibleSystemImage(
                        systemName: "star.fill",
                        label: "Star icon",
                        foregroundColor: .yellow
                    )
                    .font(.system(size: 30))
                    
                    AccessibleSystemImage(
                        systemName: "person.fill",
                        label: "Person icon",
                        isDecorative: true,
                        foregroundColor: .blue
                    )
                    .font(.system(size: 30))
                }
                
                // Adjustable component example
                AccessibilityWrapper(
                    label: "Adjustable slider example",
                    hint: "Swipe up or down to adjust value",
                    addTraits: [.isAdjustable],
                    adjustableAction: { direction in
                        print("Adjusted: \(direction == .increment ? "up" : "down")")
                    }
                ) {
                    Slider(value: .constant(0.5))
                        .padding()
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
        }
    }
}
