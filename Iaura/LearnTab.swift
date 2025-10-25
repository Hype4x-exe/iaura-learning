import SwiftUI
import UniformTypeIdentifiers

struct LearnTab: View {
    @Binding var selectedTab: Int
    @State private var showingFilePicker = false
    @State private var showingTopicInput = false
    @State private var topicText = ""
    @State private var selectedMaterial: Material?
    @State private var showingMaterialDetail = false
    @State private var draggedItem: Material?
    
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiService: AIService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if aiService.isProcessing {
                    ProcessingOverlay()
                }
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        uploadSection
                        
                        if !dataManager.materials.isEmpty {
                            recentMaterialsSection
                        }
                        
                        quickActionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker { url in
                handleFileUpload(url)
            }
        }
        .sheet(isPresented: $showingTopicInput) {
            TopicInputSheet(topicText: $topicText) { topic in
                handleTopicInput(topic)
            }
        }
        .sheet(item: $selectedMaterial) { material in
            MaterialDetailView(material: material)
        }
    }
    
    private var uploadSection: some View {
        VStack(spacing: 16) {
            Text("Drop your file or paste a topic")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(NeumorphicColors.text)
            
            HStack(spacing: 12) {
                NeumorphicButton(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                        Text("Upload File")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(NeumorphicColors.text)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                
                NeumorphicButton(action: {
                    showingTopicInput = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                            .font(.title2)
                        Text("Type Topic")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(NeumorphicColors.text)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .neumorphic(cornerRadius: 20)
    }
    
    private var recentMaterialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Materials")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(dataManager.materials.suffix(4)) { material in
                    MaterialCard(material: material) {
                        selectedMaterial = material
                    }
                    .onDrag {
                        draggedItem = material
                        return NSItemProvider(object: material.id.uuidString as NSString)
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Scan Document",
                    icon: "viewfinder",
                    color: .blue
                ) {
                    // Handle document scanning
                }
                
                QuickActionCard(
                    title: "YouTube Link",
                    icon: "play.rectangle",
                    color: .red
                ) {
                    // Handle YouTube link
                }
                
                QuickActionCard(
                    title: "Voice Note",
                    icon: "mic.fill",
                    color: .green
                ) {
                    // Handle voice note
                }
                
                QuickActionCard(
                    title: "Web Clipper",
                    icon: "globe",
                    color: .orange
                ) {
                    // Handle web clipping
                }
            }
        }
    }
    
    private func handleFileUpload(_ url: URL) {
        // Simulate file processing
        let material = Material(
            title: url.lastPathComponent,
            content: "Content from \(url.lastPathComponent)",
            type: .pdf,
            sourceURL: url.absoluteString,
            tags: ["Uploaded"]
        )
        
        dataManager.addMaterial(material)
        
        Task {
            await aiService.processMaterial(material)
        }
    }
    
    private func handleTopicInput(_ topic: String) {
        guard !topic.isEmpty else { return }
        
        let material = Material(
            title: topic,
            content: "Study material about \(topic)",
            type: .text,
            tags: ["Topic"]
        )
        
        dataManager.addMaterial(material)
        
        Task {
            await aiService.processMaterial(material)
        }
    }
}

struct ProcessingOverlay: View {
    @EnvironmentObject var aiService: AIService
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(NeumorphicColors.secondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: aiService.processingProgress)
                        .stroke(
                            LinearGradient(
                                colors: [NeumorphicColors.accent, NeumorphicColors.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: aiService.processingProgress)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(NeumorphicColors.accent)
                }
                
                Text(aiService.processingMessage)
                    .font(.headline)
                    .foregroundColor(NeumorphicColors.text)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(aiService.processingProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(NeumorphicColors.accent)
            }
            .padding(24)
            .neumorphic(cornerRadius: 20)
            
            Spacer()
        }
        .background(NeumorphicColors.background.opacity(0.9))
    }
}

struct MaterialCard: View {
    let material: Material
    let onTap: () -> Void
    
    var body: some View {
        NeumorphicButton(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: material.type.systemImage)
                        .font(.title2)
                        .foregroundColor(NeumorphicColors.accent)
                    
                    Spacer()
                    
                    Text(material.type.displayName)
                        .font(.caption)
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
                
                Text(material.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(NeumorphicColors.text)
                    .lineLimit(2)
                
                HStack {
                    Text(material.uploadedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(NeumorphicColors.textSecondary)
                    
                    Spacer()
                    
                    if material.isProcessed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(12)
            .frame(height: 100)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        NeumorphicButton(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(NeumorphicColors.text)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(height: 80)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .pdf,
            .text,
            .plainText,
            .image,
            .audiovisualContent
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

struct TopicInputSheet: View {
    @Binding var topicText: String
    let onTopicSubmitted: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("What would you like to learn about?")
                    .font(.headline)
                    .foregroundColor(NeumorphicColors.text)
                
                NeumorphicTextField(placeholder: "Enter a topic or question", text: $topicText)
                    .frame(height: 120)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(NeumorphicColors.textSecondary)
                    .padding()
                    .neumorphic(cornerRadius: 12)
                    
                    Button("Generate") {
                        onTopicSubmitted(topicText)
                        topicText = ""
                        dismiss()
                    }
                    .disabled(topicText.isEmpty)
                    .opacity(topicText.isEmpty ? 0.6 : 1.0)
                    .foregroundColor(.white)
                    .padding()
                    .background(NeumorphicColors.accent)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(NeumorphicColors.background)
            .navigationTitle("New Topic")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MaterialDetailView: View {
    let material: Material
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiService: AIService
    
    private var questions: [Question] {
        dataManager.questions.filter { $0.materialId == material.id }
    }
    
    private var flashcards: [Flashcard] {
        dataManager.flashcards.filter { $0.materialId == material.id }
    }
    
    private var notes: [Note] {
        dataManager.notes.filter { $0.materialId == material.id }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                materialInfoSection
                
                TabView(selection: $selectedTab) {
                    QuestionsView(questions: questions)
                        .tabItem {
                            Image(systemName: "questionmark.circle.fill")
                            Text("Questions")
                        }
                        .tag(0)
                    
                    FlashcardsView(flashcards: flashcards)
                        .tabItem {
                            Image(systemName: "rectangle.stack.fill")
                            Text("Flashcards")
                        }
                        .tag(1)
                    
                    NotesView(notes: notes)
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("Notes")
                        }
                        .tag(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(material.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var materialInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: material.type.systemImage)
                    .font(.title2)
                    .foregroundColor(NeumorphicColors.accent)
                
                VStack(alignment: .leading) {
                    Text(material.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(NeumorphicColors.text)
                    
                    Text(material.type.displayName)
                        .font(.caption)
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
                
                Spacer()
                
                if material.isProcessed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if !material.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(material.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(NeumorphicColors.secondary.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundColor(NeumorphicColors.text)
                        }
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
        .padding(.horizontal)
        .padding(.top)
    }
}

struct QuestionsView: View {
    let questions: [Question]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(questions) { question in
                    QuestionCard(question: question)
                }
            }
            .padding()
        }
    }
}

struct QuestionCard: View {
    let question: Question
    @State private var showAnswer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NeumorphicColors.accent.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(NeumorphicColors.accent)
                
                Spacer()
                
                Text(question.difficulty.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(difficultyColor)
            }
            
            Text(question.question)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(NeumorphicColors.text)
            
            if question.type == .multipleChoice, let options = question.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        HStack {
                            Circle()
                                .fill(option == question.correctAnswer && showAnswer ? NeumorphicColors.accent : NeumorphicColors.secondary)
                                .frame(width: 8, height: 8)
                            
                            Text(option)
                                .font(.caption)
                                .foregroundColor(NeumorphicColors.text)
                        }
                    }
                }
            }
            
            if showAnswer {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Answer:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(NeumorphicColors.textSecondary)
                    
                    Text(question.correctAnswer)
                        .font(.subheadline)
                        .foregroundColor(NeumorphicColors.text)
                    
                    if !question.explanation.isEmpty {
                        Text("Explanation:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(NeumorphicColors.textSecondary)
                            .padding(.top, 4)
                        
                        Text(question.explanation)
                            .font(.caption)
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                    
                    if let source = question.source {
                        Text("Source: \(source)")
                            .font(.caption)
                            .foregroundColor(NeumorphicColors.textSecondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showAnswer.toggle()
            }
        }
    }
    
    private var difficultyColor: Color {
        switch question.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

struct FlashcardsView: View {
    let flashcards: [Flashcard]
    @State private var currentIndex = 0
    @State private var isFlipped = false
    
    var body: some View {
        VStack {
            if flashcards.isEmpty {
                Text("No flashcards available")
                    .foregroundColor(NeumorphicColors.textSecondary)
                    .padding()
            } else {
                VStack {
                    flashcardCard
                        .padding()
                    
                    HStack {
                        Button("Previous") {
                            withAnimation {
                                currentIndex = max(0, currentIndex - 1)
                                isFlipped = false
                            }
                        }
                        .disabled(currentIndex == 0)
                        .opacity(currentIndex == 0 ? 0.5 : 1.0)
                        .padding()
                        .neumorphic(cornerRadius: 12)
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(flashcards.count)")
                            .foregroundColor(NeumorphicColors.textSecondary)
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation {
                                currentIndex = min(flashcards.count - 1, currentIndex + 1)
                                isFlipped = false
                            }
                        }
                        .disabled(currentIndex == flashcards.count - 1)
                        .opacity(currentIndex == flashcards.count - 1 ? 0.5 : 1.0)
                        .padding()
                        .neumorphic(cornerRadius: 12)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var flashcardCard: some View {
        let card = flashcards[currentIndex]
        
        return VStack {
            Group {
                if isFlipped {
                    VStack {
                        Text("Answer")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(NeumorphicColors.textSecondary)
                        
                        Text(card.back)
                            .font(.body)
                            .foregroundColor(NeumorphicColors.text)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    VStack {
                        Text("Question")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(NeumorphicColors.textSecondary)
                        
                        Text(card.front)
                            .font(.body)
                            .foregroundColor(NeumorphicColors.text)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .frame(minHeight: 200)
            .padding()
            .neumorphic(cornerRadius: 20)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isFlipped.toggle()
                }
            }
        }
    }
}

struct NotesView: View {
    let notes: [Note]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notes) { note in
                    NoteCard(note: note)
                }
            }
            .padding()
        }
    }
}

struct NoteCard: View {
    let note: Note
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(note.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(NeumorphicColors.text)
                
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
            
            if !note.summary.isEmpty {
                Text(note.summary)
                    .font(.subheadline)
                    .foregroundColor(NeumorphicColors.textSecondary)
                    .lineLimit(isExpanded ? nil : 3)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !note.keyConcepts.isEmpty {
                        Text("Key Concepts:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(NeumorphicColors.textSecondary)
                        
                        ForEach(note.keyConcepts, id: \.self) { concept in
                            HStack {
                                Circle()
                                    .fill(NeumorphicColors.accent)
                                    .frame(width: 4, height: 4)
                                Text(concept)
                                    .font(.caption)
                                    .foregroundColor(NeumorphicColors.text)
                            }
                        }
                    }
                    
                    if !note.examples.isEmpty {
                        Text("Examples:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(NeumorphicColors.textSecondary)
                            .padding(.top, 4)
                        
                        ForEach(note.examples, id: \.self) { example in
                            HStack {
                                Circle()
                                    .fill(NeumorphicColors.secondary)
                                    .frame(width: 4, height: 4)
                                Text(example)
                                    .font(.caption)
                                    .foregroundColor(NeumorphicColors.text)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .neumorphic(cornerRadius: 16)
    }
}

#Preview {
    LearnTab(selectedTab: .constant(0))
        .environmentObject(DataManager())
        .environmentObject(AIService())
}