import SwiftUI

/**
 * ContentView - Placeholder
 * 
 * This view is a placeholder that redirects to the app's main implementation.
 * The actual implementation of the app's interface is in MiddlewareConnectApp.swift
 * using the MainContentView struct.
 */
struct ContentView: View {
    var body: some View {
        Text("Loading MiddlewareConnect...")
            .font(.title)
            .onAppear {
                // This is just a placeholder - the actual app uses MainContentView
                // from MiddlewareConnectApp.swift
            }
    }
}

#Preview {
    ContentView()
}
