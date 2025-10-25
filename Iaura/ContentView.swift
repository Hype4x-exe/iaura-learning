import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var aiService: AIService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LearnTab(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Learn")
                }
                .tag(0)
            
            FlashcardsTab()
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Flashcards")
                }
                .tag(1)
            
            NotesTab()
                .tabItem {
                    Image(systemName: "note.text")
                    Text("Notes")
                }
                .tag(2)
            
            TutorTab()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Tutor")
                }
                .tag(3)
        }
        .background(NeumorphicColors.background)
        .onAppear {
            setupApp()
        }
    }
    
    private func setupApp() {
        dataManager.loadSampleData()
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
        .environmentObject(AIService())
}