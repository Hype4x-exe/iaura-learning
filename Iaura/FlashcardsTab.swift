import SwiftUI

struct FlashcardsTab: View {
    @State private var selectedDeck: Deck?
    @State private var showingStudySession = false
    @State private var showingDeckCreation = false
    @State private var searchText = ""
    
    @EnvironmentObject var dataManager: DataManager
    
    private var filteredFlashcards: [Flashcard] {
        if searchText.isEmpty {
            return dataManager.flashcards
        } else {
            return dataManager.flashcards.filter { 
                $0.front.localizedCaseInsensitiveContains(searchText) ||
                $0.back.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private var dueFlashcards: [Flashcard] {
        dataManager.getFlashcardsForReview()
    }
    
    private var decks: [Deck] {
        // Group flashcards by tags to create decks
        let tagGroups = Dictionary(grouping: filteredFlashcards) { flashcard in
            flashcard.tags.first ?? "General"
        }
        
        return tagGroups.map { (tagName, flashcards) in
            Deck(
                id: tagName,
                name: tagName,
                flashcards: flashcards,
                dueCount: flashcards.filter { $0.nextReviewDate <= Date() }.count
            )
        }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats Section
                statsSection
                
                // Search Bar
                searchBar
                
                // Decks Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(decks) { deck in
                            DeckCard(deck: deck) {
                                selectedDeck = deck
                                showingStudySession = true
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NeumorphicButton(action: {
                        showingDeckCreation = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(NeumorphicColors.text)
                            .padding(8)
                    }
                }
            }
        }
        .sheet(item: $selectedDeck) { deck in
            StudySessionView(deck: deck)
        }
        .sheet(isPresented: $showingDeckCreation) {
            CreateFlashcardView()
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Due Today",
                value: "\(dueFlashcards.count)",
                color: .orange,
                icon: "clock.fill"
            )
            
            StatCard(
                title: "Total Cards",
                value: "\(filteredFlashcards.count)",
                color: .blue,
                icon: "rectangle.stack.fill"
            )
            
            StatCard(
                title: "Mastered",
                value: "\(filteredFlashcards.filter { $0.repetitions >= 3 }.count)",
                color: .green,
                icon: "checkmark.circle.fill"
            )
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(NeumorphicColors.textSecondary)
            
            TextField("Search flashcards...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
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
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(NeumorphicColors.text)
            
            Text(title)
                .font(.caption)
                .foregroundColor(NeumorphicColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .neumorphic(cornerRadius: 16)
    }
}

struct Deck: Identifiable {
    let id: String
    let name: String
    let flashcards: [Flashcard]
    let dueCount: Int
}

struct DeckCard: View {
    let deck: Deck
    let onTap: () -> Void
    
    var body: some View {
        NeumorphicButton(action: onTap) {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("\(deck.dueCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(deck.dueCount > 0 ? .orange : NeumorphicColors.text)
                    
                    Text("due")
                        .font(.caption)
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
                
                Divider()
                
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title2)
                        .foregroundColor(NeumorphicColors.accent)
                    
                    Text(deck.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(NeumorphicColors.text)
                        .lineLimit(1)
                    
                    Text("\(deck.flashcards.count) cards")
                        .font(.caption)
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
            }
            .padding(16)
            .frame(height: 140)
        }
    }
}

struct StudySessionView: View {
    let deck: Deck
    @State private var currentCardIndex = 0
    @State private var isFlipped = false
    @State private var studyMode: StudyMode = .review
    @State private var sessionStats = SessionStats()
    @State private var showingSessionComplete = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    private var currentCard: Flashcard? {
        guard currentCardIndex < deck.flashcards.count else { return nil }
        return deck.flashcards[currentCardIndex]
    }
    
    private var progress: Double {
        Double(currentCardIndex) / Double(deck.flashcards.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: NeumorphicColors.accent))
                    .padding(.horizontal)
                
                // Stats Bar
                statsBar
                
                // Flashcard
                if let card = currentCard {
                    flashcardView(card: card)
                } else {
                    Text("No cards to study")
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
                
                // Study Controls
                studyControls
                
                Spacer()
            }
            .padding()
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Review Mode", systemImage: "arrow.triangle.2.circlepath") {
                            studyMode = .review
                        }
                        Button("Learning Mode", systemImage: "brain.head.profile") {
                            studyMode = .learning
                        }
                        Button("Test Mode", systemImage: "checkmark.square") {
                            studyMode = .test
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSessionComplete) {
            SessionCompleteView(stats: sessionStats) {
                dismiss()
            }
        }
    }
    
    private var statsBar: some View {
        HStack {
            Label("\(currentCardIndex + 1)", systemImage: "rectangle.stack")
                .font(.caption)
                .foregroundColor(NeumorphicColors.textSecondary)
            
            Spacer()
            
            Label("\(sessionStats.correct)", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Spacer()
            
            Label("\(sessionStats.incorrect)", systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Label("\(sessionStats.remaining)", systemImage: "hourglass")
                .font(.caption)
                .foregroundColor(NeumorphicColors.textSecondary)
        }
        .padding()
        .neumorphic(cornerRadius: 12)
    }
    
    private func flashcardView(card: Flashcard) -> some View {
        VStack(spacing: 20) {
            // Card
            VStack {
                Group {
                    if isFlipped {
                        VStack(spacing: 16) {
                            Text("Answer")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(NeumorphicColors.textSecondary)
                            
                            Text(card.back)
                                .font(.body)
                                .foregroundColor(NeumorphicColors.text)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            if !card.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(card.tags, id: \.self) { tag in
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
                    } else {
                        VStack(spacing: 16) {
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
                .frame(minHeight: 300)
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
            
            // Quality Buttons (shown when flipped)
            if isFlipped && studyMode == .review {
                qualityButtons
            }
        }
    }
    
    private var qualityButtons: some View {
        VStack(spacing: 12) {
            Text("How well did you know this?")
                .font(.subheadline)
                .foregroundColor(NeumorphicColors.textSecondary)
            
            HStack(spacing: 12) {
                ForEach(0..<4) { quality in
                    Button(action: {
                        handleQualityRating(quality)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: qualityIcon(for: quality))
                                .font(.title2)
                            Text(qualityLabel(for: quality))
                                .font(.caption)
                        }
                        .foregroundColor(qualityColor(for: quality))
                        .padding()
                        .neumorphic(cornerRadius: 12)
                    }
                }
            }
        }
    }
    
    private var studyControls: some View {
        HStack(spacing: 16) {
            NeumorphicButton(action: previousCard) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .foregroundColor(NeumorphicColors.text)
                .padding()
            }
            .disabled(currentCardIndex == 0)
            .opacity(currentCardIndex == 0 ? 0.5 : 1.0)
            
            NeumorphicButton(action: skipCard) {
                Text("Skip")
                    .foregroundColor(NeumorphicColors.textSecondary)
                    .padding()
            }
            
            NeumorphicButton(action: nextCard) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(NeumorphicColors.text)
                .padding()
            }
            .disabled(currentCardIndex >= deck.flashcards.count - 1)
            .opacity(currentCardIndex >= deck.flashcards.count - 1 ? 0.5 : 1.0)
        }
    }
    
    private func handleQualityRating(_ quality: Int) {
        guard let card = currentCard else { return }
        
        var updatedCard = card
        updatedCard.updateReview(quality: quality)
        dataManager.updateFlashcard(updatedCard)
        
        if quality >= 3 {
            sessionStats.correct += 1
        } else {
            sessionStats.incorrect += 1
        }
        
        nextCard()
    }
    
    private func nextCard() {
        if currentCardIndex < deck.flashcards.count - 1 {
            withAnimation {
                currentCardIndex += 1
                isFlipped = false
                sessionStats.remaining = deck.flashcards.count - currentCardIndex - 1
            }
        } else {
            showingSessionComplete = true
        }
    }
    
    private func previousCard() {
        if currentCardIndex > 0 {
            withAnimation {
                currentCardIndex -= 1
                isFlipped = false
                sessionStats.remaining = deck.flashcards.count - currentCardIndex - 1
            }
        }
    }
    
    private func skipCard() {
        sessionStats.skipped += 1
        nextCard()
    }
    
    private func qualityIcon(for quality: Int) -> String {
        switch quality {
        case 0: return "xmark.circle.fill"
        case 1: return "minus.circle.fill"
        case 2: return "equal.circle.fill"
        case 3: return "plus.circle.fill"
        default: return "star.circle.fill"
        }
    }
    
    private func qualityLabel(for quality: Int) -> String {
        switch quality {
        case 0: return "Again"
        case 1: return "Hard"
        case 2: return "Good"
        case 3: return "Easy"
        default: return "Perfect"
        }
    }
    
    private func qualityColor(for quality: Int) -> Color {
        switch quality {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .blue
        }
    }
}

enum StudyMode {
    case review
    case learning
    case test
}

struct SessionStats {
    var correct: Int = 0
    var incorrect: Int = 0
    var skipped: Int = 0
    var remaining: Int = 0
}

struct SessionCompleteView: View {
    let stats: SessionStats
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(NeumorphicColors.text)
                }
                
                VStack(spacing: 16) {
                    StatRow(title: "Correct", value: "\(stats.correct)", color: .green)
                    StatRow(title: "Incorrect", value: "\(stats.incorrect)", color: .red)
                    StatRow(title: "Skipped", value: "\(stats.skipped)", color: .orange)
                    
                    Divider()
                    
                    StatRow(
                        title: "Accuracy",
                        value: accuracyPercentage,
                        color: stats.correct >= stats.incorrect ? .green : .orange
                    )
                }
                .padding()
                .neumorphic(cornerRadius: 16)
                
                VStack(spacing: 12) {
                    Button("Continue Studying") {
                        dismiss()
                    }
                    .foregroundColor(NeumorphicColors.text)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .neumorphic(cornerRadius: 12)
                    
                    Button("Finish") {
                        onComplete()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NeumorphicColors.accent)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                }
            }
        }
    }
    
    private var accuracyPercentage: String {
        let total = stats.correct + stats.incorrect
        if total == 0 { return "0%" }
        return "\(Int((Double(stats.correct) / Double(total)) * 100))%"
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(NeumorphicColors.text)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct CreateFlashcardView: View {
    @State private var front = ""
    @State private var back = ""
    @State private var tags = ""
    @State private var selectedMaterial: Material?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Content")) {
                    NeumorphicTextField(placeholder: "Front of card", text: $front)
                        .frame(height: 80)
                    
                    NeumorphicTextField(placeholder: "Back of card", text: $back)
                        .frame(height: 80)
                }
                
                Section(header: Text("Tags")) {
                    NeumorphicTextField(placeholder: "Enter tags separated by commas", text: $tags)
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
            .navigationTitle("Create Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFlashcard()
                        dismiss()
                    }
                    .disabled(front.isEmpty || back.isEmpty)
                }
            }
        }
    }
    
    private func createFlashcard() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let flashcard = Flashcard(
            materialId: selectedMaterial?.id ?? UUID(),
            front: front,
            back: back,
            tags: tagArray,
            source: selectedMaterial?.title
        )
        
        dataManager.addFlashcard(flashcard)
    }
}

#Preview {
    FlashcardsTab()
        .environmentObject(DataManager())
}