import SwiftUI

struct PromptTemplatesView: View {
    @State private var templates: [PromptTemplate] = []
    @State private var selectedTemplate: PromptTemplate?
    @State private var isEditMode: Bool = false
    @State private var showingTemplateEditor: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var newTemplateTitle: String = ""
    @State private var newTemplateContent: String = ""
    @State private var newTemplateDescription: String = ""
    @State private var newTemplateCategory: TemplateCategory = .general
    @State private var searchText: String = ""
    @State private var selectedCategory: TemplateCategory = .all
    @State private var showingVariableEditor: Bool = false
    @State private var templateToFill: PromptTemplate?
    
    private var filteredTemplates: [PromptTemplate] {
        var filtered = templates
        
        // Apply category filter if not "all"
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply search filter if search text is not empty
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased()) ||
                $0.content.lowercased().contains(searchText.lowercased())
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter header
            searchAndFilterHeader
            
            if filteredTemplates.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Template list
                List {
                    ForEach(filteredTemplates) { template in
                        templateRow(template)
                    }
                    .onDelete(perform: deleteTemplates)
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, .constant(isEditMode ? EditMode.active : EditMode.inactive))
            }
        }
        .navigationTitle("Prompt Templates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isEditMode.toggle()
                }) {
                    Text(isEditMode ? "Done" : "Edit")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    resetEditor()
                    showingTemplateEditor = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            loadSampleTemplates()
        }
        .sheet(isPresented: $showingTemplateEditor) {
            templateEditorView
        }
        .sheet(item: $selectedTemplate) { template in
            templateDetailView(template)
        }
        .sheet(isPresented: $showingVariableEditor, onDismiss: {
            templateToFill = nil
        }) {
            if let templateToFill = templateToFill {
                PromptVariableEditorView(
                    template: templateToFill,
                    isPresented: $showingVariableEditor
                ) { filledTemplate in
                    // Handle the filled template
                    UIPasteboard.general.string = filledTemplate
                    // In a real app, this would send to chat view
                }
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Template"),
                message: Text("Are you sure you want to delete this template? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let selectedTemplate = selectedTemplate,
                       let index = templates.firstIndex(where: { $0.id == selectedTemplate.id }) {
                        templates.remove(at: index)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Subviews
    
    private var searchAndFilterHeader: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TemplateCategory.allCases) { category in
                        categoryButton(category)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private func categoryButton(_ category: TemplateCategory) -> some View {
        Button(action: {
            selectedCategory = category
        }) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    selectedCategory == category
                    ? category.color.opacity(0.1)
                    : Color(.systemGray6)
                )
                .foregroundColor(selectedCategory == category ? category.color : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text(searchText.isEmpty ? "No Templates Yet" : "No Matching Templates")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(searchText.isEmpty ? 
                 "Create your first prompt template to save time with common tasks" : 
                 "Try adjusting your search or filters")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            if searchText.isEmpty && selectedCategory == .all {
                Button(action: {
                    resetEditor()
                    showingTemplateEditor = true
                }) {
                    Text("Create Template")
                        .fontWeight(.medium)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            } else {
                Button(action: {
                    searchText = ""
                    selectedCategory = .all
                }) {
                    Text("Clear Filters")
                        .fontWeight(.medium)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func templateRow(_ template: PromptTemplate) -> some View {
        Button(action: {
            if !isEditMode {
                selectedTemplate = template
            }
        }) {
            HStack(spacing: 12) {
                // Category indicator
                Circle()
                    .fill(template.category.color)
                    .frame(width: 12, height: 12)
                
                // Template details
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(template.content.count) characters")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if template.isPremium {
                            Label("Premium", systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Spacer()
                
                if !isEditMode {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                selectedTemplate = template
            }) {
                Label("View", systemImage: "eye")
            }
            
            Button(action: {
                editTemplate(template)
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {
                selectedTemplate = template
                showingDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var templateEditorView: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Details")) {
                    TextField("Title", text: $newTemplateTitle)
                    
                    TextField("Description", text: $newTemplateDescription)
                    
                    Picker("Category", selection: $newTemplateCategory) {
                        ForEach(TemplateCategory.allCases.filter { $0 != .all }) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Content")) {
                    TextEditor(text: $newTemplateContent)
                        .frame(minHeight: 200)
                    
                    Text("\(newTemplateContent.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Variables")) {
                    HStack {
                        Text("Add variables using {{variable_name}}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // Insert variable button
                            newTemplateContent += "{{variable}}"
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    
                    // Show detected variables
                    ForEach(extractVariables(from: newTemplateContent), id: \.self) { variable in
                        HStack {
                            Text(variable)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Button(action: {
                                // Remove variable
                                newTemplateContent = newTemplateContent.replacingOccurrences(
                                    of: "{{\(variable)}}",
                                    with: ""
                                )
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle(selectedTemplate == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingTemplateEditor = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                        showingTemplateEditor = false
                    }
                    .disabled(newTemplateTitle.isEmpty || newTemplateContent.isEmpty)
                }
            }
        }
    }
    
    private func templateDetailView(_ template: PromptTemplate) -> some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(template.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if template.isPremium {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(template.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(template.category.color.opacity(0.1))
                                .foregroundColor(template.category.color)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("\(template.content.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Template content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template Content")
                            .font(.headline)
                        
                        Text(template.content)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Variables
                    let variables = extractVariables(from: template.content)
                    if !variables.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Variables")
                                .font(.headline)
                            
                            ForEach(variables, id: \.self) { variable in
                                HStack {
                                    Text(variable)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("Required")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Use in conversation action with variables
                            templateToFill = template
                            showingVariableEditor = true
                        }) {
                            Label("Use in Conversation", systemImage: "bubble.left.and.bubble.right")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // Copy to clipboard
                            UIPasteboard.general.string = template.content
                        }) {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            editTemplate(template)
                            selectedTemplate = nil
                        }) {
                            Label("Edit Template", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedTemplate = nil
                    }) {
                        Text("Done")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func resetEditor() {
        newTemplateTitle = ""
        newTemplateContent = ""
        newTemplateDescription = ""
        newTemplateCategory = .general
    }
    
    private func editTemplate(_ template: PromptTemplate) {
        newTemplateTitle = template.title
        newTemplateContent = template.content
        newTemplateDescription = template.description
        newTemplateCategory = template.category
        selectedTemplate = template
        showingTemplateEditor = true
    }
    
    private func saveTemplate() {
        let newTemplate = PromptTemplate(
            id: selectedTemplate?.id ?? UUID(),
            title: newTemplateTitle,
            description: newTemplateDescription,
            content: newTemplateContent,
            category: newTemplateCategory,
            isPremium: false,
            usageCount: selectedTemplate?.usageCount ?? 0
        )
        
        if let selectedTemplate = selectedTemplate,
           let index = templates.firstIndex(where: { $0.id == selectedTemplate.id }) {
            // Update existing template
            templates[index] = newTemplate
        } else {
            // Add new template
            templates.append(newTemplate)
        }
        
        self.selectedTemplate = nil
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
    }
    
    // MARK: - Helpers
    
    private func extractVariables(from content: String) -> [String] {
        let pattern = "\\{\\{([^{}]+)\\}\\}"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex?.matches(in: content, options: [], range: nsRange) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
    }
    
    private func loadSampleTemplates() {
        templates = [
            PromptTemplate(
                id: UUID(),
                title: "Professional Email",
                description: "Template for writing professional business emails",
                content: "Subject: {{subject}}\n\nDear {{recipient}},\n\nI hope this email finds you well. I am writing regarding {{purpose}}.\n\n{{details}}\n\nThank you for your attention to this matter. I look forward to your response.\n\nBest regards,\n{{your_name}}\n{{your_position}}",
                category: .business,
                isPremium: false,
                usageCount: 12
            ),
            PromptTemplate(
                id: UUID(),
                title: "Code Documentation",
                description: "Generate documentation for code",
                content: "Please generate comprehensive documentation for the following {{language}} code:\n\n```{{language}}\n{{code}}\n```\n\nInclude:\n1. Function descriptions\n2. Parameter explanations\n3. Return value details\n4. Usage examples\n5. Any potential edge cases or limitations",
                category: .coding,
                isPremium: true,
                usageCount: 8
            ),
            PromptTemplate(
                id: UUID(),
                title: "Academic Research Summary",
                description: "Summarize academic papers with key information",
                content: "Please provide a concise academic summary of the following research paper:\n\nTitle: {{title}}\nAuthors: {{authors}}\nJournal/Conference: {{publication}}\nYear: {{year}}\n\nThe summary should include:\n- Key research questions\n- Methodology\n- Main findings\n- Limitations\n- Implications for the field",
                category: .academic,
                isPremium: true,
                usageCount: 5
            ),
            PromptTemplate(
                id: UUID(),
                title: "Product Description",
                description: "Create compelling product descriptions for marketing",
                content: "Create a compelling product description for {{product_name}}, which is a {{product_type}}.\n\nKey features to highlight:\n- {{feature_1}}\n- {{feature_2}}\n- {{feature_3}}\n\nTarget audience: {{target_audience}}\nPrice point: {{price_point}}\nTone: Persuasive and professional",
                category: .marketing,
                isPremium: false,
                usageCount: 21
            ),
            PromptTemplate(
                id: UUID(),
                title: "Meeting Agenda",
                description: "Create a structured meeting agenda",
                content: "# Meeting Agenda\n\n**Meeting Title:** {{meeting_title}}\n**Date:** {{date}}\n**Time:** {{time}}\n**Location:** {{location}}\n**Meeting Chair:** {{chair}}\n\n## Attendees\n{{attendees}}\n\n## Meeting Objectives\n1. {{objective_1}}\n2. {{objective_2}}\n3. {{objective_3}}\n\n## Agenda Items\n\n1. Welcome and Introduction (5 minutes)\n2. Review of Previous Meeting Minutes (10 minutes)\n3. {{agenda_item_1}} ({{duration_1}} minutes)\n4. {{agenda_item_2}} ({{duration_2}} minutes)\n5. {{agenda_item_3}} ({{duration_3}} minutes)\n6. Action Items and Next Steps (10 minutes)\n7. Any Other Business (5 minutes)\n\n## Additional Notes\n{{notes}}",
                category: .business,
                isPremium: false,
                usageCount: 15
            ),
            PromptTemplate(
                id: UUID(),
                title: "Bug Report Analysis",
                description: "Analyze software bug reports",
                content: "Please analyze the following bug report and provide suggestions for troubleshooting and resolution:\n\n**Bug Description**: {{bug_description}}\n**Environment**: {{environment}}\n**Steps to Reproduce**:\n{{steps_to_reproduce}}\n**Expected Behavior**: {{expected_behavior}}\n**Actual Behavior**: {{actual_behavior}}\n**Error Messages**: {{error_messages}}\n\nFocus on:\n1. Potential root causes\n2. Debugging strategies\n3. Possible fixes\n4. Prevention strategies for similar bugs in the future",
                category: .coding,
                isPremium: false,
                usageCount: 7
            ),
            PromptTemplate(
                id: UUID(),
                title: "Creative Story Starter",
                description: "Generate a creative story beginning",
                content: "Write the opening paragraphs for a {{genre}} story with the following elements:\n\n- Main character: {{character_name}}, who is {{character_description}}\n- Setting: {{setting}}\n- Central conflict: {{conflict}}\n- Tone: {{tone}}\n- Key theme: {{theme}}\n\nMake the opening compelling and engaging, ending with a hook that makes the reader want to continue.",
                category: .creative,
                isPremium: true,
                usageCount: 19
            )
        ]
    }
}

// MARK: - Variable Editor

struct PromptVariableEditorView: View {
    let template: PromptTemplate
    @State private var variableValues: [String: String] = [:]
    @State private var processedContent: String = ""
    @State private var showPreview: Bool = false
    @Binding var isPresented: Bool
    var onComplete: (String) -> Void
    
    init(template: PromptTemplate, isPresented: Binding<Bool>, onComplete: @escaping (String) -> Void) {
        self.template = template
        self._isPresented = isPresented
        self.onComplete = onComplete
        
        // Initialize variable values with empty strings
        let variables = extractVariables(from: template.content)
        var initialValues: [String: String] = [:]
        for variable in variables {
            initialValues[variable] = ""
        }
        _variableValues = State(initialValue: initialValues)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Variables")) {
                    if variableValues.isEmpty {
                        Text("This template has no variables to fill in.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(variableValues.keys.sorted()), id: \.self) { variable in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatVariableName(variable))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter value for \(formatVariableName(variable))", text: Binding(
                                    get: { variableValues[variable] ?? "" },
                                    set: { variableValues[variable] = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Preview")) {
                    Button(action: {
                        processedContent = fillTemplate()
                        showPreview = true
                    }) {
                        Label("Show Preview", systemImage: "eye")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(hasEmptyRequiredVariables())
                }
                
                Section {
                    Button(action: {
                        let filledTemplate = fillTemplate()
                        onComplete(filledTemplate)
                        isPresented = false
                    }) {
                        Text("Use Template")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(hasEmptyRequiredVariables() ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(hasEmptyRequiredVariables())
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Fill Template Variables")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                previewView
            }
        }
    }
    
    private var previewView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(processedContent)
                        .font(.body)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showPreview = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIPasteboard.general.string = processedContent
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
    
    private func hasEmptyRequiredVariables() -> Bool {
        for (_, value) in variableValues {
            if value.isEmpty {
                return true
            }
        }
        return false
    }
    
    private func fillTemplate() -> String {
        var result = template.content
        
        for (variable, value) in variableValues {
            result = result.replacingOccurrences(of: "{{\(variable)}}", with: value)
        }
        
        return result
    }
    
    private func formatVariableName(_ variable: String) -> String {
        let formatted = variable
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        
        return formatted
    }
    
    private func extractVariables(from content: String) -> [String] {
        let pattern = "\\{\\{([^{}]+)\\}\\}"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex?.matches(in: content, options: [], range: nsRange) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        }
    }
}

// MARK: - Models

struct PromptTemplate: Identifiable {
    var id: UUID
    var title: String
    var description: String
    var content: String
    var category: TemplateCategory
    var isPremium: Bool
    var usageCount: Int
}

enum TemplateCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case general = "General"
    case academic = "Academic"
    case business = "Business"
    case creative = "Creative"
    case coding = "Coding"
    case marketing = "Marketing"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .general: return .blue
        case .academic: return .purple
        case .business: return .green
        case .creative: return .orange
        case .coding: return .red
        case .marketing: return .pink
        }
    }
}

struct PromptTemplatesView_Previews: PreviewProvider {
    static var previews: some View {
        PromptTemplatesView()
    }
}
