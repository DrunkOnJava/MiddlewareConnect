/**
 * @fileoverview Accessibility extensions and components
 * @module AccessibilityExtensions
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - UIKit
 * 
 * Exports:
 * - View extensions for accessibility
 * - Accessibility-enhanced components
 * - Supporting modifiers and utilities
 * 
 * Notes:
 * - Use these extensions to enhance accessibility throughout the app
 * - All custom UI components should use these extensions
 */

import SwiftUI

/// A set of extensions and modifiers to improve accessibility throughout the app
extension View {
    /// Applies comprehensive accessibility features to the view
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Accessibility hint
    ///   - isButton: Whether the view should be treated as a button
    ///   - trait: Additional accessibility trait
    ///   - enableDynamicType: Whether to support dynamic type
    ///   - enableReducedMotion: Whether to respect reduced motion preferences
    ///   - enableVoiceOver: Whether to optimize for VoiceOver
    ///   - enableKeyboardFocus: Whether to support keyboard navigation
    ///   - feedback: Optional haptic feedback style
    /// - Returns: View with enhanced accessibility
    func enhancedAccessibility(
        label: String? = nil,
        hint: String? = nil,
        isButton: Bool = false,
        trait: AccessibilityTraits? = nil,
        enableDynamicType: Bool = true,
        enableReducedMotion: Bool = true,
        enableVoiceOver: Bool = true,
        enableKeyboardFocus: Bool = true,
        feedback: UIImpactFeedbackGenerator.FeedbackStyle? = nil
    ) -> some View {
        self.modifier(EnhancedAccessibilityModifier(
            label: label,
            hint: hint,
            isButton: isButton,
            trait: trait,
            enableDynamicType: enableDynamicType,
            enableReducedMotion: enableReducedMotion,
            enableVoiceOver: enableVoiceOver,
            enableKeyboardFocus: enableKeyboardFocus,
            feedback: feedback
        ))
    }
    
    /// Provides a consistent way to make views adjustable with VoiceOver
    /// - Parameters:
    ///   - value: Binding to the adjustable value
    ///   - min: Minimum value
    ///   - max: Maximum value
    ///   - step: Value increment for adjustments
    ///   - label: Accessibility label
    ///   - hint: Optional accessibility hint
    /// - Returns: View with adjustable accessibility
    func accessibilityAdjustable(
        value: Binding<Double>,
        min: Double,
        max: Double,
        step: Double = 1,
        label: String,
        hint: String? = nil
    ) -> some View {
        self.modifier(AccessibilityAdjustableModifier(
            value: value,
            min: min,
            max: max,
            step: step,
            label: label,
            hint: hint
        ))
    }
    
    /// Provides an accessible alternative for complex visualizations
    /// - Parameters:
    ///   - description: Short description of the visualization
    ///   - data: Optional detailed data description
    /// - Returns: View with accessible visualization
    func accessibleVisualization(description: String, data: String? = nil) -> some View {
        self.modifier(AccessibleVisualizationModifier(
            description: description,
            data: data
        ))
    }
    
    /// Conditionally apply a transformation
    /// - Parameters:
    ///   - condition: Condition to check
    ///   - transform: Transformation to apply if condition is true
    /// - Returns: Transformed view if condition is true, otherwise the original view
    @ViewBuilder
    func apply<T: View>(if condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Modifier that enhances accessibility for any view
struct EnhancedAccessibilityModifier: ViewModifier {
    let label: String?
    let hint: String?
    let isButton: Bool
    let trait: AccessibilityTraits?
    let enableDynamicType: Bool
    let enableReducedMotion: Bool
    let enableVoiceOver: Bool
    let enableKeyboardFocus: Bool
    let feedback: UIImpactFeedbackGenerator.FeedbackStyle?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityEnabled) private var accessibilityEnabled
    
    func body(content: Content) -> some View {
        content
            .apply(if: label != nil) { content in
                content.accessibilityLabel(label ?? "")
            }
            .apply(if: hint != nil) { content in
                content.accessibilityHint(hint ?? "")
            }
            .apply(if: isButton) { content in
                content.accessibilityAddTraits(.isButton)
            }
            .apply(if: trait != nil) { content in
                content.accessibilityAddTraits(trait!)
            }
            .apply(if: feedback != nil) { content in
                content.onTapGesture {
                    provideFeedback()
                }
            }
            .apply(if: enableKeyboardFocus) { content in
                content.focusable(accessibilityEnabled)
            }
            .contentShape(Rectangle()) // Makes the entire view tappable for VoiceOver
    }
    
    private func provideFeedback() {
        guard let feedback = feedback else { return }
        
        let generator = UIImpactFeedbackGenerator(style: feedback)
        generator.prepare()
        generator.impactOccurred()
    }
}

/// Modifier that makes a view adjustable with VoiceOver
struct AccessibilityAdjustableModifier: ViewModifier {
    @Binding var value: Double
    let min: Double
    let max: Double
    let step: Double
    let label: String
    let hint: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value))")
            .apply(if: hint != nil) { content in
                content.accessibilityHint(hint ?? "")
            }
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    value = min(max, value + step)
                case .decrement:
                    value = max(min, value - step)
                @unknown default:
                    break
                }
            }
    }
}

/// Modifier that provides an accessible alternative for complex visualizations
struct AccessibleVisualizationModifier: ViewModifier {
    let description: String
    let data: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel("Visualization: \(description)")
            .accessibilityHint("Double tap to hear data details")
            .accessibilityAction {
                // This would trigger an actual accessibility action in a real implementation
                // Such as reading out the data or navigating to a more accessible view
                UIAccessibility.post(notification: .announcement, argument: data ?? description)
            }
    }
}

// MARK: - Accessibility Components

/// A specialized text view that scales correctly with Dynamic Type
struct AccessibleText: View {
    let text: String
    let style: TextStyle
    let weight: Font.Weight
    let maxSize: CGFloat
    
    enum TextStyle {
        case title
        case headline
        case body
        case caption
        
        var font: Font {
            switch self {
            case .title: return .title
            case .headline: return .headline
            case .body: return .body
            case .caption: return .caption
            }
        }
    }
    
    init(_ text: String, style: TextStyle = .body, weight: Font.Weight = .regular, maxSize: CGFloat = 100) {
        self.text = text
        self.style = style
        self.weight = weight
        self.maxSize = maxSize
    }
    
    var body: some View {
        Text(text)
            .font(style.font.weight(weight))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
    }
}

/// Accessibility importance level for buttons
enum AccessibilityButtonImportance {
    case primary
    case secondary
    case tertiary
    
    var role: AccessibilityRoleHint {
        switch self {
        case .primary: return .button
        case .secondary: return .button
        case .tertiary: return .link
        }
    }
}

/// A button with improved accessibility features
struct AccessibleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let feedback: UIImpactFeedbackGenerator.FeedbackStyle
    let importance: AccessibilityButtonImportance
    
    init(
        _ title: String,
        icon: String? = nil,
        importance: AccessibilityButtonImportance = .primary,
        feedback: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.feedback = feedback
        self.importance = importance
    }
    
    var body: some View {
        Button(action: {
            // Provide haptic feedback
            let generator = UIImpactFeedbackGenerator(style: feedback)
            generator.impactOccurred()
            
            // Perform the action
            action()
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true)
                }
                
                Text(title)
                    .fontWeight(importance == .primary ? .semibold : .regular)
            }
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
        .accessibilityRole(importance.role)
    }
    
    private var backgroundColor: Color {
        switch importance {
        case .primary: return Color("PrimaryColor")
        case .secondary: return Color("SecondaryColor")
        case .tertiary: return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch importance {
        case .primary: return .white
        case .secondary: return Color("PrimaryTextColor")
        case .tertiary: return Color("PrimaryColor")
        }
    }
}

/// Accessible alternative for charts and graphs
struct AccessibleChartAlternative: View {
    let chartTitle: String
    let description: String
    let dataPoints: [AccessibleDataPoint]
    
    struct AccessibleDataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let description: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartTitle)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Table representation of data
            VStack(spacing: 8) {
                ForEach(dataPoints) { point in
                    HStack {
                        Text(point.label)
                            .frame(width: 100, alignment: .leading)
                        
                        ProgressView(value: point.value, total: 100)
                            .accessibilityLabel("\(point.label): \(Int(point.value))%")
                            .accessibilityValue(point.description)
                        
                        Text("\(Int(point.value))%")
                            .frame(width: 50, alignment: .trailing)
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(chartTitle) data")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(chartTitle)
        .accessibilityHint("Contains chart data in accessible format")
    }
}