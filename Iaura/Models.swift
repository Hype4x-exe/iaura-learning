import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
    var preferences: UserPreferences
    
    init(id: UUID = UUID(), name: String = "", email: String = "", preferences: UserPreferences = UserPreferences()) {
        self.id = id
        self.name = name
        self.email = email
        self.preferences = preferences
    }
}

struct UserPreferences: Codable {
    var darkMode: Bool
    var notificationsEnabled: Bool
    var studyReminders: Bool
    var spacedRepetitionInterval: TimeInterval
    
    init(darkMode: Bool = false, notificationsEnabled: Bool = true, studyReminders: Bool = true, spacedRepetitionInterval: TimeInterval = 86400) {
        self.darkMode = darkMode
        self.notificationsEnabled = notificationsEnabled
        self.studyReminders = studyReminders
        self.spacedRepetitionInterval = spacedRepetitionInterval
    }
}

struct Material: Codable, Identifiable {
    let id: UUID
    var title: String
    var content: String
    var type: MaterialType
    var sourceURL: String?
    var uploadedAt: Date
    var processedAt: Date?
    var tags: [String]
    var isProcessed: Bool
    
    init(id: UUID = UUID(), title: String, content: String, type: MaterialType, sourceURL: String? = nil, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.sourceURL = sourceURL
        self.uploadedAt = Date()
        self.processedAt = nil
        self.tags = tags
        self.isProcessed = false
    }
}

enum MaterialType: String, Codable, CaseIterable {
    case pdf = "pdf"
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case link = "link"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .text: return "Text"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .link: return "Link"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pdf: return "doc.fill"
        case .text: return "doc.text.fill"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "waveform"
        case .link: return "link"
        }
    }
}

struct Question: Codable, Identifiable {
    let id: UUID
    let materialId: UUID
    var question: String
    var type: QuestionType
    var options: [String]?
    var correctAnswer: String
    var explanation: String
    var difficulty: Difficulty
    var source: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), materialId: UUID, question: String, type: QuestionType, options: [String]? = nil, correctAnswer: String, explanation: String, difficulty: Difficulty = .medium, source: String? = nil) {
        self.id = id
        self.materialId = materialId
        self.question = question
        self.type = type
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.difficulty = difficulty
        self.source = source
        self.createdAt = Date()
    }
}

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "multiple_choice"
    case shortAnswer = "short_answer"
    case trueFalse = "true_false"
    case fillInBlank = "fill_in_blank"
    case essay = "essay"
    
    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .shortAnswer: return "Short Answer"
        case .trueFalse: return "True/False"
        case .fillInBlank: return "Fill in the Blank"
        case .essay: return "Essay"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

struct Flashcard: Codable, Identifiable {
    let id: UUID
    let materialId: UUID
    var front: String
    var back: String
    var tags: [String]
    var difficulty: Float
    var interval: TimeInterval
    var repetitions: Int
    var easeFactor: Float
    var nextReviewDate: Date
    var lastReviewDate: Date?
    var isStarred: Bool
    var createdAt: Date
    var source: String?
    
    init(id: UUID = UUID(), materialId: UUID, front: String, back: String, tags: [String] = [], source: String? = nil) {
        self.id = id
        self.materialId = materialId
        self.front = front
        self.back = back
        self.tags = tags
        self.difficulty = 0.0
        self.interval = 86400
        self.repetitions = 0
        self.easeFactor = 2.5
        self.nextReviewDate = Date().addingTimeInterval(86400)
        self.lastReviewDate = nil
        self.isStarred = false
        self.createdAt = Date()
        self.source = source
    }
    
    mutating func updateReview(quality: Int) {
        let quality = max(0, min(5, quality))
        
        if quality >= 3 {
            if repetitions == 0 {
                interval = 86400
            } else if repetitions == 1 {
                interval = 86400 * 6
            } else {
                interval = interval * easeFactor
            }
            repetitions += 1
        } else {
            repetitions = 0
            interval = 86400
        }
        
        easeFactor = max(1.3, easeFactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        difficulty = Float(5 - quality) / 5.0
        lastReviewDate = Date()
        nextReviewDate = Date().addingTimeInterval(interval)
    }
}

struct Note: Codable, Identifiable {
    let id: UUID
    let materialId: UUID
    var title: String
    var content: String
    var summary: String
    var keyConcepts: [String]
    var examples: [String]
    var misconceptions: [String]
    var tags: [String]
    var quizQuestions: [Question]
    var source: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), materialId: UUID, title: String, content: String, tags: [String] = [], source: String? = nil) {
        self.id = id
        self.materialId = materialId
        self.title = title
        self.content = content
        self.summary = ""
        self.keyConcepts = []
        self.examples = []
        self.misconceptions = []
        self.tags = tags
        self.quizQuestions = []
        self.source = source
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct TutorSession: Codable, Identifiable {
    let id: UUID
    let materialId: UUID?
    var messages: [TutorMessage]
    var mode: TutorMode
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), materialId: UUID? = nil, mode: TutorMode = .socratic) {
        self.id = id
        self.materialId = materialId
        self.messages = []
        self.mode = mode
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum TutorMode: String, Codable, CaseIterable {
    case socratic = "socratic"
    case explanation = "explanation"
    case mathHelp = "math_help"
    case examCoach = "exam_coach"
    
    var displayName: String {
        switch self {
        case .socratic: return "Socratic"
        case .explanation: return "Explanation"
        case .mathHelp: return "Math Help"
        case .examCoach: return "Exam Coach"
        }
    }
    
    var systemImage: String {
        switch self {
        case .socratic: return "questionmark.bubble.fill"
        case .explanation: return "lightbulb.fill"
        case .mathHelp: return "function"
        case .examCoach: return "graduationcap.fill"
        }
    }
}

struct TutorMessage: Codable, Identifiable {
    let id: UUID
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var source: String?
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, source: String? = nil) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.source = source
    }
}