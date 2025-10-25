import SwiftUI
import PDFKit

struct NotesTab: View {
    @State private var selectedNote: Note?
    @State private var showingNoteCreation = false
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var sortOption: SortOption = .dateDescending
    
    @EnvironmentObject var dataManager: DataManager
    
    private var filteredNotes: [Note] {
        var notes = dataManager.notes
        
        // Filter by search text
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.summary.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by tag
        if let tag = selectedTag {
            notes = notes.filter { $0.tags.contains(tag) }
        }
        
        // Sort
        switch sortOption {
        case .dateDescending:
            notes = notes.sorted { $0.updatedAt > $1.updatedAt }
        case .dateAscending:
            notes = notes.sorted { $0.updatedAt < $1.updatedAt }
        case .titleAscending:
            notes = notes.sorted { $0.title < $1.title }
        case .titleDescending:
            notes = notes.sorted { $0.title > $1.title }
        }
        
        return notes
    }
    
    private var allTags: [String] {
        Set(dataManager.notes.flatMap { $0.tags }).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Section
                searchAndFilterSection
                
                // Notes Grid/List
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("New Note", systemImage: "square.and.pencil") {
                            showingNoteCreation = true
                        }
                        Button("Import from Material", systemImage: "doc.text") {
                            // Handle import
                        }
                        Button("Export All", systemImage: "square.and.arrow.up") {
                            exportAllNotes()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note)
        }
        .sheet(isPresented: $showingNoteCreation) {
            CreateNoteView()
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(NeumorphicColors.textSecondary)
                
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                }
            }
            .padding()
            .background(NeumorphicColors.primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            
            // Filter Tags
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            FilterTagButton(
                                tag: tag,
                                isSelected: selectedTag == tag
                            ) {
                                selectedTag = selectedTag == tag ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Sort Options
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundColor(NeumorphicColors.textSecondary)
                
                Picker("Sort", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(NeumorphicColors.text)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(NeumorphicColors.textSecondary)
            
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            Text("Create your first note or generate one from study materials")
                .font(.subheadline)
                .foregroundColor(NeumorphicColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Create Note") {
                showingNoteCreation = true
            }
            .foregroundColor(.white)
            .padding()
            .background(NeumorphicColors.accent)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredNotes) { note in
                    NoteCard(note: note) {
                        selectedNote = note
                    }
                }
            }
            .padding()
        }
    }
}

enum SortOption: CaseIterable {
    case dateDescending
    case dateAscending
    case titleAscending
    case titleDescending
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .titleAscending: return "Title A-Z"
        case .titleDescending: return "Title Z-A"
        }
    }
}

struct FilterTagButton: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? NeumorphicColors.accent : NeumorphicColors.secondary.opacity(0.3)
                )
                .foregroundColor(isSelected ? .white : NeumorphicColors.text)
                .cornerRadius(16)
        }
    }
}

struct NoteCard: View {
    let note: Note
    let onTap: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        NeumorphicButton(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(NeumorphicColors.text)
                            .lineLimit(2)
                        
                        Text(note.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                }
                
                // Summary
                if !note.summary.isEmpty {
                    Text(note.summary)
                        .font(.subheadline)
                        .foregroundColor(NeumorphicColors.textSecondary)
                        .lineLimit(isExpanded ? nil : 3)
                }
                
                // Tags
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(NeumorphicColors.secondary.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(NeumorphicColors.textSecondary)
                            }
                        }
                    }
                }
                
                // Expanded Content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        
                        // Key Concepts
                        if !note.keyConcepts.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Key Concepts")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(NeumorphicColors.textSecondary)
                                
                                ForEach(note.keyConcepts, id: \.self) { concept in
                                    HStack(alignment: .top, spacing: 6) {
                                        Circle()
                                            .fill(NeumorphicColors.accent)
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 6)
                                        
                                        Text(concept)
                                            .font(.caption)
                                            .foregroundColor(NeumorphicColors.text)
                                    }
                                }
                            }
                        }
                        
                        // Examples
                        if !note.examples.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Examples")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(NeumorphicColors.textSecondary)
                                    .padding(.top, 8)
                                
                                ForEach(note.examples, id: \.self) { example in
                                    HStack(alignment: .top, spacing: 6) {
                                        Circle()
                                            .fill(NeumorphicColors.secondary)
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 6)
                                        
                                        Text(example)
                                            .font(.caption)
                                            .foregroundColor(NeumorphicColors.text)
                                    }
                                }
                            }
                        }
                        
                        // Quiz Questions
                        if !note.quizQuestions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quiz Questions")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(NeumorphicColors.textSecondary)
                                    .padding(.top, 8)
                                
                                Text("\(note.quizQuestions.count) questions available")
                                    .font(.caption)
                                    .foregroundColor(NeumorphicColors.accent)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct NoteDetailView: View {
    @State private var note: Note
    @State private var isEditing = false
    @State private var showingExportOptions = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    init(note: Note) {
        _note = State(initialValue: note)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Section
                    titleSection
                    
                    // Content Section
                    contentSection
                    
                    // Key Concepts Section
                    if !note.keyConcepts.isEmpty {
                        keyConceptsSection
                    }
                    
                    // Examples Section
                    if !note.examples.isEmpty {
                        examplesSection
                    }
                    
                    // Misconceptions Section
                    if !note.misconceptions.isEmpty {
                        misconceptionsSection
                    }
                    
                    // Quiz Section
                    if !note.quizQuestions.isEmpty {
                        quizSection
                    }
                    
                    // Tags Section
                    if !note.tags.isEmpty {
                        tagsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Note Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        saveNote()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit", systemImage: "pencil") {
                            isEditing = true
                        }
                        Button("Export", systemImage: "square.and.arrow.up") {
                            showingExportOptions = true
                        }
                        Button("Share", systemImage: "square.and.arrow.up") {
                            shareNote()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditNoteView(note: $note) { updatedNote in
                note = updatedNote
                saveNote()
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(note: note)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(NeumorphicColors.text)
            
            HStack {
                Text("Created: \(note.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(NeumorphicColors.textSecondary)
                
                Spacer()
                
                Text("Updated: \(note.updatedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(NeumorphicColors.textSecondary)
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            Text(note.content)
                .font(.body)
                .foregroundColor(NeumorphicColors.text)
                .lineSpacing(4)
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private var keyConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Concepts")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(note.keyConcepts, id: \.self) { concept in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(NeumorphicColors.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(concept)
                            .font(.body)
                            .foregroundColor(NeumorphicColors.text)
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Examples")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(note.examples, id: \.self) { example in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(NeumorphicColors.secondary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(example)
                            .font(.body)
                            .foregroundColor(NeumorphicColors.text)
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private var misconceptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Misconceptions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(note.misconceptions, id: \.self) { misconception in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(misconception)
                            .font(.body)
                            .foregroundColor(NeumorphicColors.text)
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Quiz")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            Text("\(note.quizQuestions.count) questions available to test your understanding")
                .font(.subheadline)
                .foregroundColor(NeumorphicColors.textSecondary)
            
            Button("Start Quiz") {
                // Start quiz
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(NeumorphicColors.accent)
            .cornerRadius(12)
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(note.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(NeumorphicColors.secondary.opacity(0.3))
                            .cornerRadius(16)
                            .foregroundColor(NeumorphicColors.text)
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
    
    private func saveNote() {
        dataManager.updateNote(note)
    }
    
    private func shareNote() {
        // Implement sharing functionality
    }
}

struct EditNoteView: View {
    @Binding var note: Note
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedTags: String
    @State private var editedKeyConcepts: String
    @State private var editedExamples: String
    @State private var editedMisconceptions: String
    let onSave: (Note) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(note: Binding<Note>, onSave: @escaping (Note) -> Void) {
        _note = note
        self.onSave = onSave
        
        let currentNote = note.wrappedValue
        _editedTitle = State(initialValue: currentNote.title)
        _editedContent = State(initialValue: currentNote.content)
        _editedTags = State(initialValue: currentNote.tags.joined(separator: ", "))
        _editedKeyConcepts = State(initialValue: currentNote.keyConcepts.joined(separator: "\n"))
        _editedExamples = State(initialValue: currentNote.examples.joined(separator: "\n"))
        _editedMisconceptions = State(initialValue: currentNote.misconceptions.joined(separator: "\n"))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Title", text: $editedTitle)
                    TextEditor(text: $editedContent)
                        .frame(height: 200)
                }
                
                Section(header: Text("Tags")) {
                    TextField("Enter tags separated by commas", text: $editedTags)
                }
                
                Section(header: Text("Key Concepts")) {
                    TextEditor(text: $editedKeyConcepts)
                        .frame(height: 120)
                }
                
                Section(header: Text("Examples")) {
                    TextEditor(text: $editedExamples)
                        .frame(height: 120)
                }
                
                Section(header: Text("Common Misconceptions")) {
                    TextEditor(text: $editedMisconceptions)
                        .frame(height: 120)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(editedTitle.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedNote = note
        updatedNote.title = editedTitle
        updatedNote.content = editedContent
        updatedNote.tags = editedTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        updatedNote.keyConcepts = editedKeyConcepts.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        updatedNote.examples = editedExamples.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        updatedNote.misconceptions = editedMisconceptions.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        updatedNote.updatedAt = Date()
        
        onSave(updatedNote)
    }
}

struct CreateNoteView: View {
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var selectedMaterial: Material?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
                
                Section(header: Text("Tags")) {
                    TextField("Enter tags separated by commas", text: $tags)
                }
                
                Section(header: Text("Material")) {
                    if !dataManager.materials.isEmpty {
                        Picker("Link to Material", selection: $selectedMaterial) {
                            Text("None").tag(nil as Material?)
                            ForEach(dataManager.materials) { material in
                                Text(material.title).tag(material as Material?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createNote()
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private func createNote() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let note = Note(
            materialId: selectedMaterial?.id ?? UUID(),
            title: title,
            content: content,
            tags: tagArray,
            source: selectedMaterial?.title
        )
        
        dataManager.addNote(note)
    }
}

struct ExportOptionsView: View {
    let note: Note
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Options")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(NeumorphicColors.text)
                
                VStack(spacing: 12) {
                    ExportOptionButton(
                        title: "Export as PDF",
                        icon: "doc.fill",
                        color: .red
                    ) {
                        exportAsPDF()
                        dismiss()
                    }
                    
                    ExportOptionButton(
                        title: "Export as Markdown",
                        icon: "doc.text.fill",
                        color: .blue
                    ) {
                        exportAsMarkdown()
                        dismiss()
                    }
                    
                    ExportOptionButton(
                        title: "Export as Plain Text",
                        icon: "doc.plaintext.fill",
                        color: .green
                    ) {
                        exportAsPlainText()
                        dismiss()
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportAsPDF() {
        // Implement PDF export
    }
    
    private func exportAsMarkdown() {
        // Implement Markdown export
    }
    
    private func exportAsPlainText() {
        // Implement plain text export
    }
}

struct ExportOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(NeumorphicColors.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(NeumorphicColors.textSecondary)
            }
            .padding()
            .neumorphic(cornerRadius: 12)
        }
    }
}

#Preview {
    NotesTab()
        .environmentObject(DataManager())
}