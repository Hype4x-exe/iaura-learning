import Foundation
import SwiftUI

class AIService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage = ""
    
    private let systemPrompt = """
    You are iaura — a calm, intelligent, and Socratic AI study coach. Use only the learner's provided materials. Guide them to understand, not memorize. Ask before explaining. Always cite sources or mark as 'no source'. Encourage mastery and curiosity.
    """
    
    func processMaterial(_ material: Material) async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            processingMessage = "Extracting content..."
        }
        
        await simulateProgress(0.2, "Analyzing content structure...")
        
        let questions = await generateQuestions(for: material)
        
        await simulateProgress(0.4, "Creating flashcards...")
        
        let flashcards = await generateFlashcards(for: material)
        
        await simulateProgress(0.6, "Generating notes...")
        
        let notes = await generateNotes(for: material)
        
        await simulateProgress(0.8, "Preparing tutor session...")
        
        await simulateProgress(1.0, "Complete!")
        
        await MainActor.run {
            isProcessing = false
            processingProgress = 0.0
            processingMessage = ""
        }
    }
    
    private func simulateProgress(_ progress: Double, _ message: String) async {
        await MainActor.run {
            processingProgress = progress
            processingMessage = message
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    func generateQuestions(for material: Material) async -> [Question] {
        let questionTypes = [QuestionType.multipleChoice, .shortAnswer, .trueFalse]
        var questions: [Question] = []
        
        for (index, type) in questionTypes.enumerated() {
            let question = await generateSingleQuestion(for: material, type: type)
            questions.append(question)
            
            await simulateProgress(
                Double(index + 1) / Double(questionTypes.count) * 0.3 + 0.1,
                "Generating questions..."
            )
        }
        
        return questions
    }
    
    private func generateSingleQuestion(for material: Material, type: QuestionType) async -> Question {
        switch type {
        case .multipleChoice:
            return Question(
                materialId: material.id,
                question: "What is the primary goal of \(material.title)?",
                type: .multipleChoice,
                options: [
                    "To understand core concepts",
                    "To memorize facts",
                    "To complete assignments",
                    "To pass exams"
                ],
                correctAnswer: "To understand core concepts",
                explanation: "The primary goal is to understand core concepts rather than just memorization.",
                difficulty: .medium,
                source: material.title
            )
        case .shortAnswer:
            return Question(
                materialId: material.id,
                question: "Explain the key principles covered in \(material.title).",
                type: .shortAnswer,
                correctAnswer: "The key principles involve understanding fundamental concepts and their applications.",
                explanation: "Understanding fundamental principles helps in applying knowledge to various scenarios.",
                difficulty: .medium,
                source: material.title
            )
        case .trueFalse:
            return Question(
                materialId: material.id,
                question: "\(material.title) covers advanced topics suitable for experts.",
                type: .trueFalse,
                correctAnswer: "False",
                explanation: "The material covers fundamental concepts suitable for learners at various levels.",
                difficulty: .easy,
                source: material.title
            )
        default:
            return Question(
                materialId: material.id,
                question: "What did you learn from \(material.title)?",
                type: .shortAnswer,
                correctAnswer: "Varies by individual experience",
                explanation: "Learning outcomes depend on individual engagement and prior knowledge.",
                difficulty: .medium,
                source: material.title
            )
        }
    }
    
    func generateFlashcards(for material: Material) async -> [Flashcard] {
        let flashcardCount = 3
        var flashcards: [Flashcard] = []
        
        for i in 0..<flashcardCount {
            let flashcard = await generateSingleFlashcard(for: material, index: i)
            flashcards.append(flashcard)
            
            await simulateProgress(
                Double(i + 1) / Double(flashcardCount) * 0.3 + 0.4,
                "Creating flashcards..."
            )
        }
        
        return flashcards
    }
    
    private func generateSingleFlashcard(for material: Material, index: Int) async -> Flashcard {
        let concepts = [
            ("What is the main topic of this material?", "This material focuses on the core principles and applications of the subject."),
            ("Define the key terminology used", "Key terminology refers to the specialized vocabulary essential for understanding the subject matter."),
            ("What are the practical applications?", "Practical applications involve applying theoretical knowledge to real-world scenarios.")
        ]
        
        let (front, back) = concepts[index % concepts.count]
        
        return Flashcard(
            materialId: material.id,
            front: front,
            back: back,
            tags: material.tags + ["Generated"],
            source: material.title
        )
    }
    
    func generateNotes(for material: Material) async -> Note {
        await simulateProgress(0.7, "Analyzing content for notes...")
        
        var note = Note(
            materialId: material.id,
            title: "Study Notes: \(material.title)",
            content: material.content,
            tags: material.tags + ["Notes"],
            source: material.title
        )
        
        note.summary = "This material covers essential concepts and principles related to \(material.title). The content provides a comprehensive overview suitable for learning and reference."
        
        note.keyConcepts = [
            "Fundamental principles",
            "Core terminology",
            "Practical applications",
            "Theoretical framework"
        ]
        
        note.examples = [
            "Real-world applications of concepts",
            "Case studies demonstrating principles",
            "Practical exercises for understanding"
        ]
        
        note.misconceptions = [
            "Confusing correlation with causation",
            "Overlooking context in applications",
            "Misinterpreting technical terminology"
        ]
        
        note.quizQuestions = await generateQuestions(for: material)
        
        return note
    }
    
    func generateTutorResponse(for message: String, in session: TutorSession, material: Material?) async -> String {
        await simulateProgress(0.5, "Thinking...")
        
        switch session.mode {
        case .socratic:
            return "That's an interesting question. Before I give you the answer, what do you think the key concept might be? Consider what you've learned so far."
        case .explanation:
            return "Let me explain this concept. The key idea is to break it down into smaller, more manageable parts that build upon each other."
        case .mathHelp:
            return "I'd be happy to help with this math problem. Can you show me what you've tried so far? This will help me understand where you might be getting stuck."
        case .examCoach:
            return "Great question for exam preparation! Let's think about how to approach this systematically. What would be your first step?"
        }
    }
    
    func generateOCR(from image: Data) async -> String? {
        await simulateProgress(0.8, "Extracting text from image...")
        return "Extracted text from image (simulated OCR result)"
    }
    
    func generateYouTubeTranscript(from url: String) async -> String? {
        await simulateProgress(0.9, "Transcribing video content...")
        return "YouTube video transcript (simulated)"
    }
    
    func generateLatexMath(from text: String) async -> String {
        await simulateProgress(0.6, "Processing mathematical content...")
        return "\\(\\text{Processed LaTeX: }\\)" + text
    }
}