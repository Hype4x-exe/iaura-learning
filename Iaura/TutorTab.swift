import SwiftUI

struct TutorTab: View {
    @State private var selectedSession: TutorSession?
    @State private var showingNewSession = false
    @State private var searchText = ""
    @State private var selectedMode: TutorMode = .socratic
    
    @EnvironmentObject var dataManager: DataManager
    
    private var filteredSessions: [TutorSession] {
        var sessions = dataManager.tutorSessions
        
        if !searchText.isEmpty {
            sessions = sessions.filter { session in
                session.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        return sessions.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private var recentSessions: [TutorSession] {
        Array(filteredSessions.prefix(5))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode Selection
                modeSelectionSection
                
                // Quick Actions
                quickActionsSection
                
                // Sessions List
                if filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("AI Tutor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NeumorphicButton(action: {
                        showingNewSession = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(NeumorphicColors.text)
                            .padding(8)
                    }
                }
            }
        }
        .sheet(item: $selectedSession) { session in
            TutorSessionView(session: session)
        }
        .sheet(isPresented: $showingNewSession) {
            NewSessionView(selectedMode: $selectedMode)
        }
    }
    
    private var modeSelectionSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Learning Style")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TutorMode.allCases, id: \.self) { mode in
                        ModeSelectionCard(
                            mode: mode,
                            isSelected: selectedMode == mode
                        ) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Start")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            HStack(spacing: 12) {
                QuickStartButton(
                    title: "General Help",
                    icon: "questionmark.bubble.fill",
                    color: .blue
                ) {
                    startGeneralSession()
                }
                
                QuickStartButton(
                    title: "Math Problem",
                    icon: "function",
                    color: .green
                ) {
                    startMathSession()
                }
                
                QuickStartButton(
                    title: "Exam Prep",
                    icon: "graduationcap.fill",
                    color: .orange
                ) {
                    startExamSession()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(NeumorphicColors.textSecondary)
            
            Text("Start a Learning Session")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(NeumorphicColors.text)
            
            Text("Connect with your AI tutor to get personalized help and guidance")
                .font(.subheadline)
                .foregroundColor(NeumorphicColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Start New Session") {
                showingNewSession = true
            }
            .foregroundColor(.white)
            .padding()
            .background(NeumorphicColors.accent)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private var sessionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(NeumorphicColors.text)
                
                Spacer()
                
                if !filteredSessions.isEmpty {
                    Text("\(filteredSessions.count) total")
                        .font(.caption)
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(recentSessions) { session in
                        SessionCard(session: session) {
                            selectedSession = session
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func startGeneralSession() {
        let session = TutorSession(mode: .socratic)
        dataManager.addTutorSession(session)
        selectedSession = session
    }
    
    private func startMathSession() {
        let session = TutorSession(mode: .mathHelp)
        dataManager.addTutorSession(session)
        selectedSession = session
    }
    
    private func startExamSession() {
        let session = TutorSession(mode: .examCoach)
        dataManager.addTutorSession(session)
        selectedSession = session
    }
}

struct ModeSelectionCard: View {
    let mode: TutorMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        NeumorphicButton(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: mode.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : NeumorphicColors.accent)
                
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : NeumorphicColors.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? NeumorphicColors.accent : NeumorphicColors.primary
            )
            .cornerRadius(12)
        }
    }
}

struct QuickStartButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        NeumorphicButton(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(NeumorphicColors.text)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}

struct SessionCard: View {
    let session: TutorSession
    let onTap: () -> Void
    @EnvironmentObject var dataManager: DataManager
    
    private var lastMessage: TutorMessage? {
        session.messages.last
    }
    
    private var materialTitle: String? {
        guard let materialId = session.materialId else { return nil }
        return dataManager.materials.first { $0.id == materialId }?.title
    }
    
    var body: some View {
        NeumorphicButton(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: session.mode.systemImage)
                        .font(.title3)
                        .foregroundColor(NeumorphicColors.accent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.mode.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(NeumorphicColors.text)
                        
                        if let materialTitle = materialTitle {
                            Text(materialTitle)
                                .font(.caption)
                                .foregroundColor(NeumorphicColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(session.messages.count) messages")
                            .font(.caption)
                            .foregroundColor(NeumorphicColors.textSecondary)
                        
                        Text(session.updatedAt, style: .relative)
                            .font(.caption2)
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                }
                
                if let lastMessage = lastMessage {
                    HStack {
                        Text(lastMessage.isFromUser ? "You: " : "Tutor: ")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(lastMessage.isFromUser ? NeumorphicColors.accent : NeumorphicColors.textSecondary)
                        
                        Text(lastMessage.content)
                            .font(.caption)
                            .foregroundColor(NeumorphicColors.text)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
        }
    }
}

struct TutorSessionView: View {
    @State private var session: TutorSession
    @State private var messageText = ""
    @State private var isTyping = false
    @State private var showingMaterialPicker = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiService: AIService
    
    init(session: TutorSession) {
        _session = State(initialValue: session)
    }
    
    private var material: Material? {
        guard let materialId = session.materialId else { return nil }
        return dataManager.materials.first { $0.id == materialId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Material Info Bar
                if let material = material {
                    materialInfoBar(material: material)
                }
                
                // Messages
                messagesView
                
                // Input Area
                inputArea
            }
            .navigationTitle(session.mode.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        saveSession()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Link Material", systemImage: "doc") {
                            showingMaterialPicker = true
                        }
                        Button("Clear History", systemImage: "trash") {
                            clearHistory()
                        }
                        Button("Export Chat", systemImage: "square.and.arrow.up") {
                            exportChat()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingMaterialPicker) {
            MaterialPickerView { selectedMaterial in
                session.materialId = selectedMaterial.id
                saveSession()
            }
        }
    }
    
    private func materialInfoBar(material: Material) -> some View {
        HStack {
            Image(systemName: material.type.systemImage)
                .foregroundColor(NeumorphicColors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Studying: \(material.title)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(NeumorphicColors.text)
                
                Text(material.type.displayName)
                    .font(.caption2)
                    .foregroundColor(NeumorphicColors.textSecondary)
            }
            
            Spacer()
            
            Button("Change") {
                showingMaterialPicker = true
            }
            .font(.caption)
            .foregroundColor(NeumorphicColors.accent)
        }
        .padding()
        .background(NeumorphicColors.primary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(NeumorphicColors.secondary.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(session.messages) { message in
                    MessageBubble(message: message)
                }
                
                if isTyping {
                    TypingIndicator()
                }
            }
            .padding()
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(NeumorphicColors.secondary.opacity(0.3))
            
            HStack(spacing: 12) {
                Button(action: {
                    // Quick actions
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(NeumorphicColors.accent)
                }
                
                TextField("Ask me anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(NeumorphicColors.primary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? NeumorphicColors.textSecondary : NeumorphicColors.accent)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .background(NeumorphicColors.background)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = TutorMessage(
            content: messageText,
            isFromUser: true
        )
        
        session.messages.append(userMessage)
        messageText = ""
        isTyping = true
        saveSession()
        
        Task {
            let response = await aiService.generateTutorResponse(
                for: userMessage.content,
                in: session,
                material: material
            )
            
            await MainActor.run {
                let tutorMessage = TutorMessage(
                    content: response,
                    isFromUser: false,
                    source: material?.title
                )
                
                session.messages.append(tutorMessage)
                isTyping = false
                saveSession()
            }
        }
    }
    
    private func saveSession() {
        session.updatedAt = Date()
        dataManager.updateTutorSession(session)
    }
    
    private func clearHistory() {
        session.messages.removeAll()
        saveSession()
    }
    
    private func exportChat() {
        // Export chat functionality
    }
}

struct MessageBubble: View {
    let message: TutorMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isFromUser ? .white : NeumorphicColors.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isFromUser ? NeumorphicColors.accent : NeumorphicColors.primary
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                message.isFromUser ? Color.clear : LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                HStack(spacing: 4) {
                    if !message.isFromUser {
                        Image(systemName: "person.circle.fill")
                            .font(.caption2)
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(NeumorphicColors.textSecondary)
                    
                    if message.isFromUser {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(NeumorphicColors.textSecondary)
                    }
                }
                
                if let source = message.source {
                    Text("Source: \(source)")
                        .font(.caption2)
                        .foregroundColor(NeumorphicColors.textSecondary)
                }
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(NeumorphicColors.textSecondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6).repeatForever(),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(NeumorphicColors.primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct NewSessionView: View {
    @Binding var selectedMode: TutorMode
    @State private var selectedMaterial: Material?
    @State private var initialMessage = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("New Learning Session")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(NeumorphicColors.text)
                    
                    Text("Start a conversation with your AI tutor tailored to your learning needs")
                        .font(.subheadline)
                        .foregroundColor(NeumorphicColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tutoring Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(NeumorphicColors.text)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(TutorMode.allCases, id: \.self) { mode in
                            ModeSelectionCard(
                                mode: mode,
                                isSelected: selectedMode == mode
                            ) {
                                selectedMode = mode
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Study Material (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(NeumorphicColors.text)
                    
                    if dataManager.materials.isEmpty {
                        Text("No materials available. Upload some in the Learn tab first.")
                            .font(.caption)
                            .foregroundColor(NeumorphicColors.textSecondary)
                            .padding()
                            .neumorphic(cornerRadius: 12)
                    } else {
                        Picker("Select Material", selection: $selectedMaterial) {
                            Text("None").tag(nil as Material?)
                            ForEach(dataManager.materials) { material in
                                Text(material.title).tag(material as Material?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .neumorphic(cornerRadius: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Initial Question (Optional)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(NeumorphicColors.text)
                    
                    TextField("What would you like to learn about?", text: $initialMessage, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(3...6)
                        .padding()
                        .neumorphic(cornerRadius: 12)
                }
                
                Spacer()
                
                Button("Start Session") {
                    startSession()
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(NeumorphicColors.accent)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startSession() {
        let session = TutorSession(
            materialId: selectedMaterial?.id,
            mode: selectedMode
        )
        
        if !initialMessage.isEmpty {
            let message = TutorMessage(content: initialMessage, isFromUser: true)
            session.messages.append(message)
        }
        
        dataManager.addTutorSession(session)
        dismiss()
    }
}

struct MaterialPickerView: View {
    let onMaterialSelected: (Material) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            List(dataManager.materials) { material in
                Button(action: {
                    onMaterialSelected(material)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: material.type.systemImage)
                            .foregroundColor(NeumorphicColors.accent)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(material.title)
                                .font(.body)
                                .foregroundColor(NeumorphicColors.text)
                            
                            Text(material.type.displayName)
                                .font(.caption)
                                .foregroundColor(NeumorphicColors.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Material")
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
}

#Preview {
    TutorTab()
        .environmentObject(DataManager())
        .environmentObject(AIService())
}