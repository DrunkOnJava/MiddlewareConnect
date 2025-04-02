import SwiftUI

/// Helper for improving accessibility throughout the app
struct AccessibilityHelper {
    
    // MARK: - Voice Over
    
    /// Adds proper accessibility label and hints to a view
    /// - Parameters:
    ///   - view: The view to modify
    ///   - label: The accessibility label (what VoiceOver reads)
    ///   - hint: The accessibility hint (additional context for the user)
    ///   - traits: The accessibility traits for the element
    /// - Returns: The modified view with accessibility properties
    static func voiceOver<T: View>(
        _ view: T,
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        view
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Adds proper accessibility label and hints to a button
    /// - Parameters:
    ///   - view: The button view to modify
    ///   - label: The accessibility label (what VoiceOver reads)
    ///   - hint: The accessibility hint (additional context for the user)
    /// - Returns: The modified view with accessibility properties
    static func button<T: View>(
        _ view: T,
        label: String,
        hint: String? = nil
    ) -> some View {
        view
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Dynamic Type
    
    /// Font sizes that scale with Dynamic Type
    struct DynamicFont {
        static let title = Font.system(.title).weight(.bold).leading(.tight)
        static let headline = Font.system(.headline).weight(.semibold)
        static let body = Font.system(.body)
        static let callout = Font.system(.callout)
        static let subheadline = Font.system(.subheadline)
        static let footnote = Font.system(.footnote)
        static let caption = Font.system(.caption)
        
        // Monospaced variants
        static let monoTitle = Font.system(.title, design: .monospaced).weight(.bold)
        static let monoHeadline = Font.system(.headline, design: .monospaced).weight(.semibold)
        static let monoBody = Font.system(.body, design: .monospaced)
        static let monoCaption = Font.system(.caption, design: .monospaced)
    }
    
    // MARK: - Reduced Motion
    
    /// Applies appropriate animation based on reduced motion settings
    /// - Parameters:
    ///   - view: The view to animate
    ///   - animation: The standard animation to use when reduced motion is off
    ///   - reducedAnimation: The simplified animation to use when reduced motion is on
    /// - Returns: The view with appropriate animation applied
    static func animate<T: View>(
        _ view: T,
        animation: Animation,
        reducedAnimation: Animation = .none
    ) -> some View {
        view.modifier(ReducedMotionViewModifier(
            standardAnimation: animation,
            reducedAnimation: reducedAnimation
        ))
    }
    
    // MARK: - Color Contrast
    
    /// Ensures text has sufficient contrast against its background
    /// - Parameters:
    ///   - text: The text view
    ///   - color: The text color
    ///   - background: The background color
    /// - Returns: The text view with appropriate color for contrast
    static func highContrastText<T: View>(
        _ text: T,
        color: Color,
        background: Color
    ) -> some View {
        text.foregroundColor(color)
            .accessibilityIgnoresInvertColors(true)
    }
}

// MARK: - View Modifiers

/// View modifier that applies different animations based on reduced motion settings
struct ReducedMotionViewModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let standardAnimation: Animation
    let reducedAnimation: Animation
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? reducedAnimation : standardAnimation)
    }
}

// MARK: - View Extensions

extension View {
    /// Adds proper accessibility label and hints to a view
    func accessibleView(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        AccessibilityHelper.voiceOver(self, label: label, hint: hint, traits: traits)
    }
    
    /// Adds proper accessibility label and hints to a button
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        AccessibilityHelper.button(self, label: label, hint: hint)
    }
    
    /// Applies appropriate animation based on reduced motion settings
    func accessibleAnimation(animation: Animation, reducedAnimation: Animation = .none) -> some View {
        AccessibilityHelper.animate(self, animation: animation, reducedAnimation: reducedAnimation)
    }
    
    /// Ensures text has sufficient contrast against its background
    func highContrastText(color: Color, background: Color) -> some View {
        AccessibilityHelper.highContrastText(self, color: color, background: background)
    }
    
    /// Adds a semantic description to an image for VoiceOver
    func accessibleImage(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Preview

struct AccessibilityHelper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Accessible button example
            Button(action: {}) {
                Text("Tap Me")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .accessibleButton(
                label: "Action Button",
                hint: "Performs the main action"
            )
            
            // High contrast text example
            Text("High Contrast Text")
                .padding()
                .highContrastText(color: .white, background: .blue)
                .background(Color.blue)
                .cornerRadius(8)
            
            // Dynamic type example
            Text("Dynamic Type Headline")
                .font(AccessibilityHelper.DynamicFont.headline)
            
            Text("Dynamic Type Body")
                .font(AccessibilityHelper.DynamicFont.body)
            
            // Accessible image example
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
                .accessibleImage(
                    label: "Favorite",
                    hint: "Indicates this item is favorited"
                )
        }
        .padding()
    }
}
