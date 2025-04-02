# LLMBuddy iOS Views Architecture

This directory contains the view components for the LLMBuddy iOS application. The views have been organized following a modular architecture to improve maintainability and readability.

## Directory Structure

- **Views/**
  - **Components/**: Reusable UI components used throughout the app
  - **Tabs/**: Main tab views for primary app navigation
  - **Common/**: Common UI elements like buttons, cards, etc.
  - **Utils/**: Utility views and helper components
  - **ContentView.swift**: Main container view

## Navigation Structure

The app uses a tab-based navigation on iPhone and a split view with sidebar on iPad:

- **Phone Layout**: Uses TabView with main tabs
- **iPad Layout**: Uses NavigationView with SidebarView and destination views

## Main Components

### Tabs

- **HomeTabView**: Home tab showing welcome message, recent activities, and featured tools
- **ToolsTabView**: Collection of all available tools organized by category
- **ChatTabView**: Chat interface for conversational interactions
- **AnalysisTabView**: LLM analysis tools for token costs and context window visualization
- **SettingsTabView**: App settings and configuration options

### Components

- **SidebarView**: Sidebar navigation for iPad layout
- **ApiFeatureNotificationView**: Notification when API settings are required
- **LoadingView**: Loading indicator with message
- **ChatBubbleView**: Individual chat message bubble

### Utils

- **AppTab**: Enum defining main tabs for navigation
- **Tab**: Enum defining the detailed navigation options
- **PlaceholderView**: Temporary view for features under development

## Design Principles

1. **Single Responsibility**: Each view file focuses on a specific UI component
2. **Reusability**: Common components are extracted for reuse
3. **Consistency**: Views follow the app's design system
4. **Modularity**: Components can be updated independently
5. **Readability**: Smaller files improve code understanding

## Usage Guidelines

- For new features, create appropriate view files in the relevant directories
- Follow existing naming conventions and design patterns
- Integrate with the ViewFactory for consistent instantiation
- Ensure proper use of environment objects and state

## View Instantiation

Views should be instantiated through the ViewFactory to maintain consistency and facilitate dependency injection:

```swift
let view = ViewFactory.shared.getTextChunkerView()
```

## State Management

- App-wide state is managed through the AppState environment object
- Local state specific to a view should be handled with @State
- Communication between views should use bindings and environment objects