/**
 * @fileoverview Main content view for the app
 * @module MainContentView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - MainContentView
 */

import SwiftUI

/// Main content view containing the app content
struct AppMainContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                Text("MiddlewareConnect")
                    .font(.largeTitle)
                    .padding()
                
                Text("Your gateway to LLM integration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("MiddlewareConnect")
        }
    }
}

// Preview
struct AppMainContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainContentView()
            .environmentObject(AppState())
    }
}
