import SwiftUI

// MARK: - Error Alert Extension
extension View {
    /// Adds an alert that displays an error when it is present
    /// - Parameters:
    ///   - error: Binding to the error that should be displayed
    ///   - showError: Binding to a boolean that controls whether the error alert is displayed
    /// - Returns: A view that shows an error alert
    func errorAlert(error: Binding<Error?>, showError: Binding<Bool>) -> some View {
        return self.alert(isPresented: showError) {
            Alert(
                title: Text("Error"),
                message: Text(error.wrappedValue?.localizedDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Helper to create rounded corners for specific corners only
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Round corner shape helper
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Background Task Status Extension
extension View {
    /// Adds a background task status view to the bottom of a view
    /// - Returns: A view with a background task status view
    func withBackgroundTaskStatus() -> some View {
        return self.modifier(BackgroundTaskStatusModifier())
    }
}

/// A modifier that adds a background task status view to a view
struct BackgroundTaskStatusModifier: ViewModifier {
    @EnvironmentObject var appState: AppState
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            if appState.showBackgroundTaskStatus && !appState.pendingBackgroundTasks.isEmpty {
                VStack {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.blue))
                        
                        VStack(alignment: .leading) {
                            Text("Background Tasks")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(appState.pendingBackgroundTasks.count) task\(appState.pendingBackgroundTasks.count == 1 ? "" : "s") in progress")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                appState.showBackgroundTaskStatus = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: appState.showBackgroundTaskStatus)
            }
        }
    }
}