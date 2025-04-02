import SwiftUI

// Simple ContentView with TabView
struct ContentView: View {
    var body: some View {
        TabView {
            // Home Tab
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Chat Tab
            NavigationView {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            // Tools Tab
            NavigationView {
                ToolsView()
            }
            .tabItem {
                Label("Tools", systemImage: "wrench.and.screwdriver.fill")
            }
            
            // Analysis Tab
            NavigationView {
                AnalysisView()
            }
            .tabItem {
                Label("Analysis", systemImage: "chart.bar.fill")
            }
            
            // Settings Tab
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

// Home Tab View
struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to MiddlewareConnect")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your AI Tools Companion")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Home")
    }
}

// Chat Tab View
struct ChatView: View {
    var body: some View {
        VStack {
            Text("Chat Interface")
                .font(.title)
                .padding()
            
            List(1...5, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conversation \(index)")
                        .font(.headline)
                    Text("Last message from this conversation...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Chat")
    }
}

// Tools Tab View
struct ToolsView: View {
    var body: some View {
        List {
            Section(header: Text("Document Tools")) {
                NavigationLink(destination: Text("PDF Combiner Tool")) {
                    Label("PDF Combiner", systemImage: "doc.on.doc")
                }
                NavigationLink(destination: Text("PDF Splitter Tool")) {
                    Label("PDF Splitter", systemImage: "doc.text")
                }
            }
            
            Section(header: Text("Text Processing")) {
                NavigationLink(destination: Text("Text Chunker Tool")) {
                    Label("Text Chunker", systemImage: "text.insert")
                }
                NavigationLink(destination: Text("Text Cleaner Tool")) {
                    Label("Text Cleaner", systemImage: "sparkles")
                }
            }
        }
        .navigationTitle("Tools")
    }
}

// Analysis Tab View
struct AnalysisView: View {
    var body: some View {
        VStack {
            Text("LLM Analysis Tools")
                .font(.title)
                .padding()
            
            List {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.green)
                    Text("Token Cost Calculator")
                }
                
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                    Text("Context Window Visualizer")
                }
                
                HStack {
                    Image(systemName: "text.magnifyingglass")
                        .foregroundColor(.purple)
                    Text("Prompt Analyzer")
                }
            }
        }
        .navigationTitle("Analysis")
    }
}

// Settings Tab View
struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("API Settings")) {
                HStack {
                    Label("API Keys", systemImage: "key")
                    Spacer()
                    Text("Configured")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Label("LLM Model", systemImage: "brain")
                    Spacer()
                    Text("Claude 3.5 Sonnet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Appearance")) {
                HStack {
                    Label("Theme", systemImage: "paintbrush")
                    Spacer()
                    Text("System")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    ContentView()
}
