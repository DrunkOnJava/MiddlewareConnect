import SwiftUI

extension CustomButton {
    /// Button style options for the `CustomButton` component
    enum Style {
        case primary
        case secondary
        case destructive
        case text       // Text-only button, like a link
        case icon       // Icon-only button
        case custom(Color) // Custom color button
    }
}