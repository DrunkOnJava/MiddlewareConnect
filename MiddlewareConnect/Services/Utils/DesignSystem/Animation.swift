import SwiftUI

struct _DesignSystemAnimation {
    static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
    static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
}