# LLMBuddy Design System Architecture

This document outlines the architecture of the design system used in the LLMBuddy iOS application.

## Overview

The design system provides a centralized collection of UI components, styles, and utilities to ensure consistency across the application. It is implemented through the `AppDesignSystem` struct with a typealias to `DesignSystem` for backward compatibility.

## Components

### Typography

The typography system defines a consistent set of font styles:

```swift
public struct Typography {
    public static let title = Font.title
    public static let title2 = Font.title2
    public static let title3 = Font.title3
    public static let headline = Font.headline
    public static let subheadline = Font.subheadline
    // Additional styles...
}
```

### Colors

The color palette defines the application's color scheme:

```swift
public struct Colors {
    // Primary colors
    public static let primary = Color("PrimaryColor", default: .blue)
    public static let secondary = Color("SecondaryColor", default: .orange)
    // Additional colors...
}
```

### Layout

Layout metrics provide consistent spacing and sizing:

```swift
public struct Layout {
    // Spacing
    public static let small: CGFloat = 12
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    // Additional metrics...
}
```

### Radius

Corner radius values for consistent UI elements:

```swift
public struct Radius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 16
    public static let extraLarge: CGFloat = 24
    public static let circle: CGFloat = 999
}
```

### Shadows

Shadow styles for depth and elevation:

```swift
public struct Shadows {
    public static let small = Shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    public static let medium = Shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    // Additional shadows...
}
```

### Haptic Feedback

The design system includes haptic feedback utilities for tactile responses:

```swift
// In AppDesignSystem.swift
public static func hapticFeedback(_ intensity: HapticFeedbackIntensity) {
    // Implementation...
}

public static func notificationHaptic(_ type: NotificationHapticType) {
    // Implementation...
}

// In DesignSystem+Extensions.swift (for direct access)
public static let light = HapticFeedbackIntensity.light
public static let medium = HapticFeedbackIntensity.medium
public static let success = NotificationHapticType.success
// Additional static values...
```

## Technical Architecture

### Implementation Pattern

The design system follows a modular structure with nested structs for logical grouping. For backward compatibility and direct access to enum values, we use extensions to the `DesignSystem` typealias.

### Usage Examples

Typography:
```swift
Text("Heading")
    .font(DesignSystem.Typography.headline)
```

Haptic Feedback:
```swift
DesignSystem.hapticFeedback(.light)
DesignSystem.notificationHaptic(.success)
```

Shadows:
```swift
.shadow(
    color: DesignSystem.Shadows.medium.color,
    radius: DesignSystem.Shadows.medium.radius,
    x: DesignSystem.Shadows.medium.x,
    y: DesignSystem.Shadows.medium.y
)
```

## Maintenance Guidelines

When extending the design system:

1. Follow the established pattern of nested structs for logical grouping
2. Maintain backward compatibility through the `DesignSystem` typealias
3. Use extensions for direct access to enum values when necessary
4. Document new components thoroughly
5. Consider the impact on existing code when making changes
