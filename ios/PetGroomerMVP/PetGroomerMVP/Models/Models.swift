import Foundation

enum AppRole: String, Codable, CaseIterable, Identifiable {
    case petOwner = "Pet owner"
    case groomer = "Groomer"

    var id: String { rawValue }
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var email: String?
    var appleUserID: String?
    var displayName: String
    var avatarURL: String?
    var city: String
    var zipCode: String
    var languagePreference: String
    var createdAt: Date
    var updatedAt: Date
}

enum PetSpecies: String, Codable, CaseIterable, Identifiable {
    case dog = "Dog"
    case cat = "Cat"

    var id: String { rawValue }
}

struct Pet: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var name: String
    var species: PetSpecies
    var breed: String
    var breedNotes: String?
    var weight: Double?
    var age: Double?
    var sex: String?
    var coatType: String
    var coatCondition: String
    var temperament: [String]
    var healthNotes: String?
    var groomingHistory: String?
    var createdAt: Date
    var updatedAt: Date
    var aiDetectedBreed: [String: Double]?
    var aiBreedConfidence: Double?
    var aiDetectedCoatType: String?
    var aiDetectedSize: String?
    var aiRiskFlags: [String]
    var aiProfileSummary: String?
    var aiLastAnalyzedAt: Date?
}

enum PetPhotoType: String, Codable, CaseIterable, Identifiable {
    case front = "Front"
    case side = "Side"
    case fullBody = "Full body"
    case coatCloseUp = "Coat close-up"
    case mattedArea = "Matted area"
    case styleReference = "Style reference"
    case other = "Other"

    var id: String { rawValue }
}

struct PetPhoto: Identifiable, Codable, Hashable {
    let id: UUID
    var petID: UUID
    var userID: UUID
    var imageURL: String
    var photoType: PetPhotoType
    var isPrimary: Bool
    var createdAt: Date
}

struct Groomer: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var profilePhotoURL: String?
    var bio: String
    var city: String
    var zipCode: String
    var serviceRadius: Double
    var serviceAreas: [String]
    var languages: [String]
    var yearsExperience: Double
    var serviceMethods: [String]
    var acceptsDogs: Bool
    var acceptsCats: Bool
    var sizeAccepted: [String]
    var specialties: [String]
    var priceMin: Double
    var priceMax: Double
    var phone: String?
    var smsNumber: String?
    var instagramURL: String?
    var wechatID: String?
    var websiteURL: String?
    var email: String?
    var isVerified: Bool
    var status: PublishStatus
    var rating: Double
    var reviewCount: Int
    var createdAt: Date
    var updatedAt: Date
    var aiSummary: String?
    var aiSkillTags: [String]
    var aiReviewSummary: String?
    var aiLastProcessedAt: Date?
}

struct PortfolioItem: Identifiable, Codable, Hashable {
    let id: UUID
    var groomerID: UUID
    var imageURL: String
    var beforeImageURL: String?
    var afterImageURL: String?
    var petSpecies: PetSpecies
    var breed: String
    var serviceType: String
    var styleName: String
    var coatCondition: String
    var caption: String
    var createdAt: Date
}

struct Review: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID?
    var groomerID: UUID
    var petID: UUID?
    var overallRating: Double
    var groomingResultRating: Double?
    var communicationRating: Double?
    var patienceRating: Double?
    var punctualityRating: Double?
    var priceTransparencyRating: Double?
    var wouldRebook: Bool?
    var serviceType: String
    var reviewText: String
    var serviceDate: Date?
    var status: ModerationStatus
    var createdAt: Date
    var updatedAt: Date
    var aiSentiment: String?
    var aiTopics: [String]
    var aiRiskFlag: Bool
    var aiSummary: String?
}

enum FavoriteTargetType: String, Codable, CaseIterable, Identifiable {
    case groomer
    case portfolio
    case review

    var id: String { rawValue }
}

struct Favorite: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var targetType: FavoriteTargetType
    var targetID: UUID
    var createdAt: Date
}

enum ContactMethod: String, Codable, CaseIterable, Identifiable {
    case phone
    case sms
    case instagram
    case wechat
    case website
    case email
    case quoteRequest = "quote_request"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .phone: "Call"
        case .sms: "SMS"
        case .instagram: "Instagram"
        case .wechat: "WeChat"
        case .website: "Website"
        case .email: "Email"
        case .quoteRequest: "Quote"
        }
    }
}

struct ContactEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID?
    var groomerID: UUID
    var petID: UUID?
    var contactMethod: ContactMethod
    var createdAt: Date
}

enum QuoteRequestStatus: String, Codable, CaseIterable, Identifiable {
    case submitted
    case viewed
    case closed

    var id: String { rawValue }
}

struct QuoteRequest: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID?
    var groomerID: UUID
    var petID: UUID?
    var serviceType: String
    var preferredTime: String
    var notes: String
    var contactPreference: String
    var status: QuoteRequestStatus
    var createdAt: Date
    var updatedAt: Date
}

enum ReportTargetType: String, Codable, CaseIterable, Identifiable {
    case groomer
    case review
    case portfolio
    case user
    case other

    var id: String { rawValue }
}

enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case fakeProfile = "Fake profile"
    case scam = "Scam"
    case inaccurateInformation = "Inaccurate information"
    case inappropriateImage = "Inappropriate image"
    case harassment = "Harassment"
    case fakeReview = "Fake review"
    case dangerousService = "Dangerous service"
    case other = "Other"

    var id: String { rawValue }
}

enum ReportStatus: String, Codable, CaseIterable, Identifiable {
    case open
    case reviewing
    case resolved
    case dismissed

    var id: String { rawValue }
}

struct Report: Identifiable, Codable, Hashable {
    let id: UUID
    var reporterUserID: UUID?
    var targetType: ReportTargetType
    var targetID: UUID
    var reason: ReportReason
    var details: String
    var status: ReportStatus
    var adminNotes: String?
    var createdAt: Date
    var updatedAt: Date
}

enum PublishStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case published
    case hidden

    var id: String { rawValue }
}

enum ModerationStatus: String, Codable, CaseIterable, Identifiable {
    case published
    case hidden
    case flagged
    case deleted

    var id: String { rawValue }
}

struct FeatureFlag: Identifiable, Codable, Hashable {
    var id: String { key }
    var key: String
    var isEnabled: Bool
    var description: String
}
