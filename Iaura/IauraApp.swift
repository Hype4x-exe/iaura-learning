import SwiftUI

@main
struct IauraApp: App {
    @StateObject private var dataManager = DataManager()
    @StateObject private var aiService = AIService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(aiService)
                .preferredColorScheme(.light)
        }
    }
}