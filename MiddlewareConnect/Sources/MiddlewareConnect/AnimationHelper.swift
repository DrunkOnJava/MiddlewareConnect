import SwiftUI

/// Helper for consistent animations throughout the app
struct AnimationHelper {
    
    // MARK: - Animation Presets
    
    /// Standard animations for different purposes
    struct Animations {
        /// Quick animation for small UI changes
        static let quick = Animation.easeOut(duration: 0.2)
        
        /// Standard animation for most UI changes
        static let standard = Animation.easeInOut(duration: 0.3)
        
        /// Slow animation for emphasis
        static let emphasis = Animation.easeInOut(duration: 0.5)
        
        /// Spring animation for natural movement
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
        
        /// Delayed animation for sequential effects
        static func delayed(delay: Double = 0.2, duration: Double = 0.3) -> Animation {
            Animation.easeInOut(duration: duration).delay(delay)
        }
        
        /// Repeating animation for attention
        static func repeating(duration: Double = 1.0) -> Animation {
            Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)
        }
    }
    
    // MARK: - Transition Presets
    
    /// Standard transitions for different purposes
    struct Transitions {
        /// Fade transition for subtle appearance/disappearance
        static let fade = AnyTransition.opacity
        
        /// Slide transition from the leading edge
        static let slideFromLeading = AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .leading)
        )
        
        /// Slide transition from the trailing edge
        static let slideFromTrailing = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .trailing)
        )
        
        /// Slide transition from the top
        static let slideFromTop = AnyTransition.asymmetric(
            insertion: .move(edge: .top),
            removal: .move(edge: .top)
        )
        
        /// Slide transition from the bottom
        static let slideFromBottom = AnyTransition.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .bottom)
        )
        
        /// Scale transition for emphasis
        static let scale = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        
        /// Slide and fade transition for cards
        static let card = AnyTransition.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        )
    }
    
    // MARK: - Animation Modifiers
    
    /// Applies a fade-in animation when a view appears
    struct FadeIn: ViewModifier {
        @State private var opacity: Double = 0
        
        let duration: Double
        let delay: Double
        
        init(duration: Double = 0.3, delay: Double = 0) {
            self.duration = duration
            self.delay = delay
        }
        
        func body(content: Content) -> some View {
            content
                .opacity(opacity)
                .onAppear {
                    withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
                        opacity = 1
                    }
                }
        }
    }
    
    /// Applies a slide-in animation when a view appears
    struct SlideIn: ViewModifier {
        @State private var offset: CGFloat = 100
        @State private var opacity: Double = 0
        
        let edge: Edge
        let duration: Double
        let delay: Double
        
        init(edge: Edge = .bottom, duration: Double = 0.3, delay: Double = 0) {
            self.edge = edge
            self.duration = duration
            self.delay = delay
        }
        
        func body(content: Content) -> some View {
            content
                .opacity(opacity)
                .offset(
                    x: edge == .leading ? offset : (edge == .trailing ? -offset : 0),
                    y: edge == .top ? offset : (edge == .bottom ? -offset : 0)
                )
                .onAppear {
                    withAnimation(Animation.easeOut(duration: duration).delay(delay)) {
                        offset = 0
                        opacity = 1
                    }
                }
        }
    }
    
    /// Applies a pulse animation to draw attention
    struct Pulse: ViewModifier {
        @State private var isPulsing = false
        
        let duration: Double
        let scale: CGFloat
        let autoStart: Bool
        
        init(duration: Double = 1.5, scale: CGFloat = 1.05, autoStart: Bool = true) {
            self.duration = duration
            self.scale = scale
            self.autoStart = autoStart
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPulsing ? scale : 1.0)
                .onAppear {
                    if autoStart {
                        startPulsing()
                    }
                }
        }
        
        private func startPulsing() {
            withAnimation(Animation.easeInOut(duration: duration / 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a fade-in animation when a view appears
    func fadeIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        modifier(AnimationHelper.FadeIn(duration: duration, delay: delay))
    }
    
    /// Applies a slide-in animation when a view appears
    func slideIn(from edge: Edge = .bottom, duration: Double = 0.3, delay: Double = 0) -> some View {
        modifier(AnimationHelper.SlideIn(edge: edge, duration: duration, delay: delay))
    }
    
    /// Applies a pulse animation to draw attention
    func pulse(duration: Double = 1.5, scale: CGFloat = 1.05, autoStart: Bool = true) -> some View {
        modifier(AnimationHelper.Pulse(duration: duration, scale: scale, autoStart: autoStart))
    }
    
    /// Applies a staggered animation delay based on an index
    func staggered(delay: Double = 0.05, index: Int) -> some View {
        self.transition(AnimationHelper.Transitions.fade)
            .animation(Animation.easeInOut(duration: 0.3).delay(Double(index) * delay))
    }
}

// MARK: - Preview

struct AnimationHelper_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Fade In
            Text("Fade In Animation")
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .fadeIn()
            
            // Slide In
            Text("Slide In Animation")
                .font(.headline)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .slideIn(from: .trailing)
            
            // Pulse
            Text("Pulse Animation")
                .font(.headline)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .pulse()
            
            // Staggered
            HStack(spacing: 10) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 30, height: 30)
                        .staggered(index: index)
                }
            }
        }
        .padding()
    }
}
