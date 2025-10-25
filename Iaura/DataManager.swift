import Foundation
import SwiftUI

class DataManager: ObservableObject {
    @Published var materials: [Material] = []
    @Published var questions: [Question] = []
    @Published var flashcards: [Flashcard] = []
    @Published var notes: [Note] = []
    @Published var tutorSessions: [TutorSession] = []
    @Published var currentUser: User = User()
    
    private let userDefaults = UserDefaults.standard
    private let materialsKey = "materials"
    private let questionsKey = "questions"
    private let flashcardsKey = "flashcards"
    private let notesKey = "notes"
    private let tutorSessionsKey = "tutorSessions"
    private let userKey = "currentUser"
    
    init() {
        loadData()
    }
    
    func loadData() {
        if let materialsData = userDefaults.data(forKey: materialsKey),
           let decodedMaterials = try? JSONDecoder().decode([Material].self, from: materialsData) {
            materials = decodedMaterials
        }
        
        if let questionsData = userDefaults.data(forKey: questionsKey),
           let decodedQuestions = try? JSONDecoder().decode([Question].self, from: questionsData) {
            questions = decodedQuestions
        }
        
        if let flashcardsData = userDefaults.data(forKey: flashcardsKey),
           let decodedFlashcards = try? JSONDecoder().decode([Flashcard].self, from: flashcardsData) {
            flashcards = decodedFlashcards
        }
        
        if let notesData = userDefaults.data(forKey: notesKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: notesData) {
            notes = decodedNotes
        }
        
        if let sessionsData = userDefaults.data(forKey: tutorSessionsKey),
           let decodedSessions = try? JSONDecoder().decode([TutorSession].self, from: sessionsData) {
            tutorSessions = decodedSessions
        }
        
        if let userData = userDefaults.data(forKey: userKey),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = decodedUser
        }
    }
    
    func saveData() {
        if let materialsData = try? JSONEncoder().encode(materials) {
            userDefaults.set(materialsData, forKey: materialsKey)
        }
        
        if let questionsData = try? JSONEncoder().encode(questions) {
            userDefaults.set(questionsData, forKey: questionsKey)
        }
        
        if let flashcardsData = try? JSONEncoder().encode(flashcards) {
            userDefaults.set(flashcardsData, forKey: flashcardsKey)
        }
        
        if let notesData = try? JSONEncoder().encode(notes) {
            userDefaults.set(notesData, forKey: notesKey)
        }
        
        if let sessionsData = try? JSONEncoder().encode(tutorSessions) {
            userDefaults.set(sessionsData, forKey: tutorSessionsKey)
        }
        
        if let userData = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    func addMaterial(_ material: Material) {
        materials.append(material)
        saveData()
    }
    
    func addQuestion(_ question: Question) {
        questions.append(question)
        saveData()
    }
    
    func addFlashcard(_ flashcard: Flashcard) {
        flashcards.append(flashcard)
        saveData()
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
        saveData()
    }
    
    func addTutorSession(_ session: TutorSession) {
        tutorSessions.append(session)
        saveData()
    }
    
    func updateFlashcard(_ flashcard: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            flashcards[index] = flashcard
            saveData()
        }
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveData()
        }
    }
    
    func updateTutorSession(_ session: TutorSession) {
        if let index = tutorSessions.firstIndex(where: { $0.id == session.id }) {
            tutorSessions[index] = session
            saveData()
        }
    }
    
    func deleteMaterial(_ material: Material) {
        materials.removeAll { $0.id == material.id }
        questions.removeAll { $0.materialId == material.id }
        flashcards.removeAll { $0.materialId == material.id }
        notes.removeAll { $0.materialId == material.id }
        tutorSessions.removeAll { $0.materialId == material.id }
        saveData()
    }
    
    func getFlashcardsForReview() -> [Flashcard] {
        let now = Date()
        return flashcards.filter { $0.nextReviewDate <= now }
    }
    
    func getDueFlashcardsCount() -> Int {
        getFlashcardsForReview().count
    }
    
    func loadSampleData() {
        guard materials.isEmpty else { return }
        
        let sampleMaterial = Material(
            title: "Introduction to Machine Learning",
            content: "Machine learning is a subset of artificial intelligence that focuses on the development of algorithms and statistical models that enable computer systems to improve their performance on a specific task through experience. The main types of machine learning are supervised learning, unsupervised learning, and reinforcement learning. In supervised learning, the algorithm learns from labeled training data, making predictions or decisions based on that data. Unsupervised learning involves training on unlabeled data, allowing the algorithm to find patterns and relationships on its own. Reinforcement learning is about training agents to make a sequence of decisions in an environment to maximize some cumulative reward.",
            type: .text,
            tags: ["AI", "Machine Learning", "Computer Science"]
        )
        
        addMaterial(sampleMaterial)
        
        let sampleQuestion = Question(
            materialId: sampleMaterial.id,
            question: "What are the three main types of machine learning?",
            type: .multipleChoice,
            options: ["Supervised, Unsupervised, Reinforcement", "Classification, Regression, Clustering", "Training, Testing, Validation"],
            correctAnswer: "Supervised, Unsupervised, Reinforcement",
            explanation: "The three main types of machine learning are supervised learning (learning from labeled data), unsupervised learning (finding patterns in unlabeled data), and reinforcement learning (learning through interaction with an environment).",
            difficulty: .medium,
            source: "Introduction to Machine Learning"
        )
        
        addQuestion(sampleQuestion)
        
        let sampleFlashcard = Flashcard(
            materialId: sampleMaterial.id,
            front: "What is machine learning?",
            back: "Machine learning is a subset of artificial intelligence that focuses on developing algorithms and statistical models that enable computer systems to improve performance through experience.",
            tags: ["AI", "Machine Learning"],
            source: "Introduction to Machine Learning"
        )
        
        addFlashcard(sampleFlashcard)
        
        let sampleNote = Note(
            materialId: sampleMaterial.id,
            title: "Machine Learning Fundamentals",
            content: "Machine learning is a revolutionary field that has transformed how we approach complex problems. At its core, machine learning is about teaching computers to learn from data without being explicitly programmed for every possible scenario.",
            tags: ["AI", "Machine Learning", "Fundamentals"],
            source: "Introduction to Machine Learning"
        )
        
        addNote(sampleNote)
        
        let sampleSession = TutorSession(
            materialId: sampleMaterial.id,
            mode: .socratic
        )
        
        addTutorSession(sampleSession)
    }
}