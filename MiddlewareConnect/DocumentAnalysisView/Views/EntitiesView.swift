import SwiftUI
import LLMServiceProvider

/// A specialized view for visualizing and interacting with extracted entities
///
/// Provides comprehensive entity visualization with filtering, grouping, and
/// expandable detail views for exploring entity relationships and references.
public struct EntitiesView: View {
    /// Core view model for entity visualization
    @StateObject private var viewModel: ViewModel
    
    /// ViewModel handling entity data and interaction
    public class ViewModel: ObservableObject {
        /// Entities extracted from documents
        @Published public var entities: [Entity] = []
        
        /// Currently selected entity
        @Published public var selectedEntity: Entity?
        
        /// Active filter text
        @Published public var filterText: String = ""
        
        /// Entity type filter selection
        @Published public var typeFilter: Set<EntityType> = []
        
        /// Confidence threshold for filtering
        @Published public var confidenceThreshold: Double = 0.5
        
        /// Current grouping criterion
        @Published public var groupBy: GroupingCriterion = .type
        
        /// Current sort criterion
        @Published public var sortBy: SortCriterion = .confidence
        
        /// Whether to show relationships
        @Published public var showRelationships: Bool = true
        
        /// Whether to show references
        @Published public var showReferences: Bool = true
        
        /// Current view mode
        @Published public var viewMode: ViewMode = .list
        
        /// Currently expanded entity details
        @Published public var expandedEntities: Set<UUID> = []
        
        /// Initialize the view model with entities
        /// - Parameter entities: Array of extracted entities
        public init(entities: [Entity] = []) {
            self.entities = entities
        }
        
        /// Filtered entities based on current settings
        public var filteredEntities: [Entity] {
            var result = entities
            
            // Apply text filter
            if !filterText.isEmpty {
                result = result.filter { entity in
                    entity.name.lowercased().contains(filterText.lowercased()) ||
                    entity.references.contains { reference in
                        reference.text.lowercased().contains(filterText.lowercased())
                    }
                }
            }
            
            // Apply type filter
            if !typeFilter.isEmpty {
                result = result.filter { entity in
                    typeFilter.contains(entity.type)
                }
            }
            
            // Apply confidence threshold
            result = result.filter { $0.confidence >= confidenceThreshold }
            
            // Apply sorting
            result = sortedEntities(result)
            
            return result
        }
        
        /// Group entities by the current grouping criterion
        /// - Returns: Dictionary of grouped entities
        public func groupedEntities() -> [String: [Entity]] {
            let filteredEntities = self.filteredEntities
            var groupedDict: [String: [Entity]] = [:]
            
            switch groupBy {
            case .type:
                // Group by entity type
                for entity in filteredEntities {
                    let key = entityTypeDisplayName(entity.type)
                    if groupedDict[key] == nil {
                        groupedDict[key] = []
                    }
                    groupedDict[key]?.append(entity)
                }
                
            case .confidenceLevel:
                // Group by confidence level range
                for entity in filteredEntities {
                    let key: String
                    if entity.confidence >= 0.9 {
                        key = "High (90-100%)"
                    } else if entity.confidence >= 0.7 {
                        key = "Medium (70-90%)"
                    } else {
                        key = "Low (50-70%)"
                    }
                    
                    if groupedDict[key] == nil {
                        groupedDict[key] = []
                    }
                    groupedDict[key]?.append(entity)
                }
                
            case .document:
                // Group by source document
                for entity in filteredEntities {
                    let sources = Set(entity.references.map { $0.location.components(separatedBy: ":").first ?? "Unknown" })
                    for source in sources {
                        if groupedDict[source] == nil {
                            groupedDict[source] = []
                        }
                        groupedDict[source]?.append(entity)
                    }
                }
                
            case .none:
                // No grouping, just use a single key
                groupedDict["All Entities"] = filteredEntities
            }
            
            // Sort each group by the current sort criterion
            for (key, entitiesInGroup) in groupedDict {
                groupedDict[key] = sortedEntities(entitiesInGroup)
            }
            
            return groupedDict
        }
        
        /// Sort entities based on current sort criterion
        /// - Parameter entitiesToSort: Entities to sort
        /// - Returns: Sorted array of entities
        private func sortedEntities(_ entitiesToSort: [Entity]) -> [Entity] {
            switch sortBy {
            case .name:
                return entitiesToSort.sorted { $0.name < $1.name }
            case .confidence:
                return entitiesToSort.sorted { $0.confidence > $1.confidence }
            case .references:
                return entitiesToSort.sorted { $0.references.count > $1.references.count }
            case .type:
                return entitiesToSort.sorted { 
                    entityTypeDisplayName($0.type) < entityTypeDisplayName($1.type)
                }
            }
        }
        
        /// Get all unique entity types from the entities
        /// - Returns: Array of unique entity types
        public func uniqueEntityTypes() -> [EntityType] {
            return Array(Set(entities.map { $0.type })).sorted { 
                entityTypeDisplayName($0) < entityTypeDisplayName($1)
            }
        }
        
        /// Get a descriptive name for an entity type
        /// - Parameter type: Entity type
        /// - Returns: Display name string
        private func entityTypeDisplayName(_ type: EntityType) -> String {
            switch type {
            case .person: return "Person"
            case .organization: return "Organization"
            case .location: return "Location"
            case .date: return "Date"
            case .concept: return "Concept"
            case .custom(let name): return name
            }
        }
        
        /// Toggle expanded state for an entity
        /// - Parameter entityId: Entity UUID to toggle
        public func toggleExpanded(entityId: UUID) {
            if expandedEntities.contains(entityId) {
                expandedEntities.remove(entityId)
            } else {
                expandedEntities.insert(entityId)
            }
        }
        
        /// Check if an entity is currently expanded
        /// - Parameter entityId: Entity UUID to check
        /// - Returns: Boolean indicating expanded state
        public func isExpanded(entityId: UUID) -> Bool {
            return expandedEntities.contains(entityId)
        }
        
        /// Select an entity and show details
        /// - Parameter entity: Entity to select
        public func selectEntity(_ entity: Entity) {
            selectedEntity = entity
        }
        
        /// Clear the current entity selection
        public func clearSelection() {
            selectedEntity = nil
        }
    }
    
    /// Criteria for grouping entities
    public enum GroupingCriterion: String, CaseIterable {
        /// Group by entity type
        case type = "Type"
        
        /// Group by confidence level
        case confidenceLevel = "Confidence"
        
        /// Group by source document
        case document = "Document"
        
        /// No grouping
        case none = "None"
    }
    
    /// Criteria for sorting entities
    public enum SortCriterion: String, CaseIterable {
        /// Sort by entity name
        case name = "Name"
        
        /// Sort by confidence score
        case confidence = "Confidence"
        
        /// Sort by reference count
        case references = "References"
        
        /// Sort by entity type
        case type = "Type"
    }
    
    /// View modes for entity display
    public enum ViewMode: String, CaseIterable {
        /// List view
        case list = "List"
        
        /// Card view
        case card = "Card"
        
        /// Network graph view
        case graph = "Graph"
        
        /// Tag cloud view
        case cloud = "Cloud"
    }
    
    /// Initializes an entities view
    /// - Parameter entities: Array of entities to display
    public init(entities: [Entity] = []) {
        self._viewModel = StateObject(wrappedValue: ViewModel(entities: entities))
    }
    
    /// Initializes an entities view with a pre-configured view model
    /// - Parameter viewModel: View model for the entities view
    public init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Controls and filters
            controlsBar
                .padding()
                .background(Color.gray.opacity(0.05))
            
            // Main content based on view mode
            Group {
                switch viewModel.viewMode {
                case .list:
                    listView
                case .card:
                    cardView
                case .graph:
                    graphView
                case .cloud:
                    cloudView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Entity detail panel if selected
            if let selectedEntity = viewModel.selectedEntity {
                entityDetailPanel(selectedEntity)
            }
        }
    }
    
    /// Controls and filters bar
    private var controlsBar: some View {
        VStack(spacing: 12) {
            // Search and view controls
            HStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search entities...", text: $viewModel.filterText)
                        .font(.callout)
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 2)
                
                Spacer()
                
                // View mode selector
                Picker("View", selection: $viewModel.viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: viewModeIcon(mode))
                            .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
            }
            
            // Filtering and grouping
            HStack {
                // Type filter
                Menu {
                    ForEach(viewModel.uniqueEntityTypes(), id: \.self) { type in
                        Button {
                            toggleTypeFilter(type)
                        } label: {
                            Label(
                                entityTypeDisplayName(type),
                                systemImage: viewModel.typeFilter.contains(type) ? "checkmark" : ""
                            )
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        viewModel.typeFilter = []
                    } label: {
                        Text("Clear Filters")
                    }
                } label: {
                    HStack {
                        Text(typeFilterLabel())
                            .font(.callout)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(6)
                }
                
                // Confidence threshold slider
                HStack {
                    Text("Min Confidence:")
                        .font(.caption)
                    
                    Slider(
                        value: $viewModel.confidenceThreshold,
                        in: 0.0...1.0,
                        step: 0.1
                    )
                    .frame(width: 120)
                    
                    Text(String(format: "%.0f%%", viewModel.confidenceThreshold * 100))
                        .font(.caption)
                        .frame(width: 40)
                }
                .padding(6)
                .background(Color.white)
                .cornerRadius(6)
                
                Spacer()
                
                // Grouping control
                HStack {
                    Text("Group by:")
                        .font(.caption)
                    
                    Picker("", selection: $viewModel.groupBy) {
                        ForEach(GroupingCriterion.allCases, id: \.self) { criterion in
                            Text(criterion.rawValue).tag(criterion)
                        }
                    }
                    .frame(width: 120)
                }
                
                // Sorting control
                HStack {
                    Text("Sort by:")
                        .font(.caption)
                    
                    Picker("", selection: $viewModel.sortBy) {
                        ForEach(SortCriterion.allCases, id: \.self) { criterion in
                            Text(criterion.rawValue).tag(criterion)
                        }
                    }
                    .frame(width: 120)
                }
            }
        }
    }
    
    /// List view for entities
    private var listView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                let groupedEntities = viewModel.groupedEntities()
                let sortedGroups = groupedEntities.keys.sorted()
                
                ForEach(sortedGroups, id: \.self) { group in
                    if let entities = groupedEntities[group] {
                        VStack(alignment: .leading, spacing: 8) {
                            // Group header
                            HStack {
                                Text(group)
                                    .font(.headline)
                                
                                Text("(\(entities.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Entities in the group
                            ForEach(entities) { entity in
                                entityListItem(entity)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.03))
                        .cornerRadius(8)
                    }
                }
                
                if viewModel.filteredEntities.isEmpty {
                    emptyStateView
                }
            }
            .padding()
        }
    }
    
    /// Card view for entities
    private var cardView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                let groupedEntities = viewModel.groupedEntities()
                let sortedGroups = groupedEntities.keys.sorted()
                
                ForEach(sortedGroups, id: \.self) { group in
                    if let entities = groupedEntities[group] {
                        VStack(alignment: .leading, spacing: 12) {
                            // Group header
                            Text(group)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Card grid
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16)
                            ], spacing: 16) {
                                ForEach(entities) { entity in
                                    entityCard(entity)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.filteredEntities.isEmpty {
                    emptyStateView
                }
            }
            .padding()
        }
    }
    
    /// Graph view for entities
    private var graphView: some View {
        // Placeholder for network graph visualization
        VStack {
            Text("Entity Relationship Graph")
                .font(.headline)
            
            if viewModel.filteredEntities.isEmpty {
                emptyStateView
            } else {
                Text("Network graph visualization would be implemented here")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Cloud view for entities
    private var cloudView: some View {
        // Placeholder for tag cloud visualization
        VStack {
            Text("Entity Tag Cloud")
                .font(.headline)
            
            if viewModel.filteredEntities.isEmpty {
                emptyStateView
            } else {
                Text("Tag cloud visualization would be implemented here")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Single entity list item
    private func entityListItem(_ entity: Entity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Entity header
            HStack {
                Image(systemName: iconForEntityType(entity.type))
                    .foregroundColor(colorForEntityType(entity.type))
                
                Text(entity.name)
                    .font(.headline)
                
                Spacer()
                
                // Confidence indicator
                HStack(spacing: 2) {
                    Text(String(format: "%.0f%%", entity.confidence * 100))
                        .font(.caption)
                        .foregroundColor(confidenceColor(entity.confidence))
                    
                    confidenceBar(entity.confidence)
                        .frame(width: 50, height: 4)
                }
                
                // Expand/collapse button
                Button(action: {
                    viewModel.toggleExpanded(entityId: entity.id)
                }) {
                    Image(systemName: viewModel.isExpanded(entityId: entity.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Entity details if expanded
            if viewModel.isExpanded(entityId: entity.id) {
                VStack(alignment: .leading, spacing: 8) {
                    // Type and classification
                    HStack {
                        Label(
                            entityTypeDisplayName(entity.type),
                            systemImage: "tag"
                        )
                        .font(.caption)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    // References section
                    if viewModel.showReferences && !entity.references.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("References (\(entity.references.count))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // Show first 3 references
                            ForEach(Array(entity.references.prefix(3)), id: \.text) { reference in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(reference.text)
                                            .font(.caption)
                                            .lineLimit(2)
                                        
                                        Text(reference.location)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // Show 'more' indicator if there are additional references
                            if entity.references.count > 3 {
                                Text("+ \(entity.references.count - 3) more...")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                    }
                    
                    // View details button
                    Button(action: {
                        viewModel.selectEntity(entity)
                    }) {
                        Text("View Details")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.leading, 24)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
        .onTapGesture {
            viewModel.toggleExpanded(entityId: entity.id)
        }
    }
    
    /// Entity card view for grid layout
    private func entityCard(_ entity: Entity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Card header
            HStack {
                Image(systemName: iconForEntityType(entity.type))
                    .foregroundColor(colorForEntityType(entity.type))
                    .font(.headline)
                
                Spacer()
                
                // Confidence pill
                Text(String(format: "%.0f%%", entity.confidence * 100))
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(confidenceColor(entity.confidence).opacity(0.1))
                    .foregroundColor(confidenceColor(entity.confidence))
                    .cornerRadius(10)
            }
            
            // Entity name
            Text(entity.name)
                .font(.headline)
                .lineLimit(1)
            
            // Entity type
            Text(entityTypeDisplayName(entity.type))
                .font(.caption)
                .foregroundColor(.gray)
            
            Divider()
            
            // References count
            HStack {
                Label("\(entity.references.count) references", systemImage: "text.quote")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            // First reference preview
            if let firstReference = entity.references.first {
                Text(firstReference.text)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // View details button
            Button(action: {
                viewModel.selectEntity(entity)
            }) {
                Text("View Details")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .frame(height: 200)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2)
    }
    
    /// Detailed panel for selected entity
    private func entityDetailPanel(_ entity: Entity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with close button
            HStack {
                Label(
                    entity.name,
                    systemImage: iconForEntityType(entity.type)
                )
                .font(.title3)
                .foregroundColor(colorForEntityType(entity.type))
                
                Spacer()
                
                Button(action: {
                    viewModel.clearSelection()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(alignment: .top, spacing: 16) {
                // Left column: Entity details
                VStack(alignment: .leading, spacing: 12) {
                    // Type and classification
                    HStack {
                        Label(
                            "Type: \(entityTypeDisplayName(entity.type))",
                            systemImage: "tag"
                        )
                        .font(.body)
                        
                        Spacer()
                        
                        // Confidence indicator
                        HStack(spacing: 4) {
                            Text("Confidence:")
                                .font(.body)
                            
                            Text(String(format: "%.0f%%", entity.confidence * 100))
                                .font(.body)
                                .foregroundColor(confidenceColor(entity.confidence))
                        }
                    }
                    
                    Divider()
                    
                    // Relationships section would go here
                    // This is a placeholder for now
                    if viewModel.showRelationships {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Relationships", systemImage: "arrow.triangle.branch")
                                .font(.headline)
                            
                            Text("Entity relationship data would be displayed here.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                    }
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity)
                
                // Right column: References list
                VStack(alignment: .leading, spacing: 12) {
                    Label("References (\(entity.references.count))", systemImage: "text.quote")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(entity.references, id: \.text) { reference in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reference.text)
                                        .font(.body)
                                    
                                    Text(reference.location)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding()
    }
    
    /// Empty state when no entities match criteria
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No entities match your criteria")
                .font(.headline)
                .foregroundColor(.gray)
            
            Button("Clear Filters") {
                viewModel.filterText = ""
                viewModel.typeFilter = []
                viewModel.confidenceThreshold = 0.5
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    /// Confidence indicator bar
    private func confidenceBar(_ value: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.2)
                    .foregroundColor(Color.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(confidenceColor(value))
            }
            .cornerRadius(2)
        }
    }
    
    /// Get color based on confidence value
    private func confidenceColor(_ value: Double) -> Color {
        if value >= 0.8 {
            return .green
        } else if value >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    /// Get icon for entity type
    private func iconForEntityType(_ type: EntityType) -> String {
        switch type {
        case .person: return "person.fill"
        case .organization: return "building.2.fill"
        case .location: return "mappin.circle.fill"
        case .date: return "calendar"
        case .concept: return "lightbulb.fill"
        case .custom: return "tag.fill"
        }
    }
    
    /// Get color for entity type
    private func colorForEntityType(_ type: EntityType) -> Color {
        switch type {
        case .person: return .blue
        case .organization: return .purple
        case .location: return .green
        case .date: return .orange
        case .concept: return .pink
        case .custom: return .gray
        }
    }
    
    /// Get icon for view mode
    private func viewModeIcon(_ mode: ViewMode) -> String {
        switch mode {
        case .list: return "list.bullet"
        case .card: return "square.grid.2x2"
        case .graph: return "circle.hexagongrid.fill"
        case .cloud: return "tag.fill"
        }
    }
    
    /// Get display name for entity type
    private func entityTypeDisplayName(_ type: EntityType) -> String {
        switch type {
        case .person: return "Person"
        case .organization: return "Organization"
        case .location: return "Location"
        case .date: return "Date"
        case .concept: return "Concept"
        case .custom(let name): return name
        }
    }
    
    /// Toggle type filter selection
    private func toggleTypeFilter(_ type: EntityType) {
        if viewModel.typeFilter.contains(type) {
            viewModel.typeFilter.remove(type)
        } else {
            viewModel.typeFilter.insert(type)
        }
    }
    
    /// Get display label for type filter
    private func typeFilterLabel() -> String {
        if viewModel.typeFilter.isEmpty {
            return "All Types"
        } else if viewModel.typeFilter.count == 1 {
            return entityTypeDisplayName(viewModel.typeFilter.first!)
        } else {
            return "\(viewModel.typeFilter.count) Types"
        }
    }
}

// MARK: - CaseIterable Conformance
extension EntitiesView.ViewMode: CaseIterable {}
extension EntitiesView.GroupingCriterion: CaseIterable {}
extension EntitiesView.SortCriterion: CaseIterable {}

// MARK: - Preview Support
#if DEBUG
struct EntitiesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // View with sample data
            EntitiesView(
                viewModel: EntitiesView.ViewModel(
                    entities: [
                        Entity(
                            id: UUID(),
                            name: "John Smith",
                            type: .person,
                            confidence: 0.95,
                            references: [
                                TextReference(text: "John Smith is the CEO of Acme Corp.", location: "p.1"),
                                TextReference(text: "Smith joined the company in 2015.", location: "p.3")
                            ]
                        ),
                        Entity(
                            id: UUID(),
                            name: "Acme Corporation",
                            type: .organization,
                            confidence: 0.92,
                            references: [
                                TextReference(text: "Acme Corporation was founded in 1985.", location: "p.1"),
                                TextReference(text: "The company headquarters is in New York.", location: "p.2")
                            ]
                        ),
                        Entity(
                            id: UUID(),
                            name: "New York",
                            type: .location,
                            confidence: 0.88,
                            references: [
                                TextReference(text: "The company headquarters is in New York.", location: "p.2")
                            ]
                        ),
                        Entity(
                            id: UUID(),
                            name: "January 15, 2022",
                            type: .date,
                            confidence: 0.75,
                            references: [
                                TextReference(text: "The merger was completed on January 15, 2022.", location: "p.4")
                            ]
                        ),
                        Entity(
                            id: UUID(),
                            name: "Strategic Restructuring",
                            type: .concept,
                            confidence: 0.65,
                            references: [
                                TextReference(text: "The strategic restructuring initiative aims to improve efficiency.", location: "p.5")
                            ]
                        )
                    ]
                )
            )
            .previewDisplayName("With Data")
            
            // Empty state
            EntitiesView()
                .previewDisplayName("Empty State")
        }
    }
}
#endif
