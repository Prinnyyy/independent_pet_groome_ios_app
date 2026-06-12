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

enum GroomingTaskService: String, Codable, CaseIterable, Identifiable {
    case bath = "Bath"
    case fullGroom = "Full groom"
    case haircut = "Haircut"
    case nailTrim = "Nail trim"
    case dematting = "De-matting"
    case catGrooming = "Cat grooming"
    case faceTrim = "Face trim"
    case sanitaryTrim = "Sanitary trim"

    var id: String { rawValue }
}

enum GroomingTaskTimeWindow: String, Codable, CaseIterable, Identifiable {
    case before8AM = "before_8_am"
    case eightAM = "8_am"
    case nineAM = "9_am"
    case tenAM = "10_am"
    case elevenAM = "11_am"
    case noon = "12_pm"
    case onePM = "1_pm"
    case twoPM = "2_pm"
    case threePM = "3_pm"
    case fourPM = "4_pm"
    case fivePM = "5_pm"
    case after5PM = "after_5_pm"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .before8AM: "Before 8:00 AM"
        case .eightAM: "8:00 AM"
        case .nineAM: "9:00 AM"
        case .tenAM: "10:00 AM"
        case .elevenAM: "11:00 AM"
        case .noon: "12:00 PM"
        case .onePM: "1:00 PM"
        case .twoPM: "2:00 PM"
        case .threePM: "3:00 PM"
        case .fourPM: "4:00 PM"
        case .fivePM: "5:00 PM"
        case .after5PM: "After 5:00 PM"
        }
    }
}

enum GroomingTaskStyleReferenceSource: String, Codable, CaseIterable, Identifiable, Hashable {
    case camera = "camera"
    case photoLibrary = "photo_library"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .camera: "Camera style photo attached"
        case .photoLibrary: "Uploaded style photo attached"
        }
    }

    var iconName: String {
        switch self {
        case .camera: "camera.fill"
        case .photoLibrary: "photo.fill.on.rectangle.fill"
        }
    }
}

struct GroomingTaskReferenceImageSlot: Codable, Hashable {
    static let maxByteSize = 5 * 1024 * 1024

    var source: GroomingTaskStyleReferenceSource?
    var localReference: String?
    var storagePath: String?
    var fileName: String?
    var mimeType: String
    var byteSize: Int?
    var maxByteSize: Int

    var hasImage: Bool {
        source != nil
    }

    var isWithinSizeLimit: Bool {
        guard let byteSize else { return true }
        return byteSize <= maxByteSize
    }

    var displayTitle: String {
        guard let source else { return "Reference image slot · max 5 MB" }
        return "\(source.displayTitle) · max 5 MB"
    }

    static func reserved(source: GroomingTaskStyleReferenceSource?, sequenceCode: String) -> GroomingTaskReferenceImageSlot {
        GroomingTaskReferenceImageSlot(
            source: source,
            localReference: source == nil ? nil : "mock://task-reference-\(sequenceCode.lowercased())",
            storagePath: source == nil ? nil : "task-reference-images/\(sequenceCode.lowercased()).jpg",
            fileName: source == nil ? nil : "\(sequenceCode.lowercased())-style-reference.jpg",
            mimeType: "image/jpeg",
            byteSize: source == nil ? nil : 1_250_000,
            maxByteSize: Self.maxByteSize
        )
    }
}

struct GroomingTaskOwnerHiddenScore: Codable, Hashable {
    var value: Double
    var source: String
    var lastEvaluatedAt: Date?

    var displayValue: String {
        String(format: "%.1f", value)
    }
}

struct GroomingTaskSearchArea: Codable, Hashable {
    var label: String
    var city: String
    var zipCode: String
    var radiusMiles: Int
    var usesCurrentLocation: Bool
    var latitude: Double?
    var longitude: Double?

    var locationTitle: String {
        [city, zipCode].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var rangeTitle: String {
        "Within \(radiusMiles) mi"
    }
}

struct GroomingTaskCardData: Identifiable, Codable, Hashable {
    let id: UUID
    var sequenceCode: String
    var userID: UUID
    var petID: UUID
    var petSnapshot: Pet
    var petPhotoSnapshots: [PetPhoto]
    var service: GroomingTaskService
    var targetDate: Date
    var timeWindow: GroomingTaskTimeWindow
    var searchArea: GroomingTaskSearchArea
    var styleGoal: String
    var specialNotes: String
    var styleReferenceSource: GroomingTaskStyleReferenceSource?
    var referenceImageSlot: GroomingTaskReferenceImageSlot
    var ownerHiddenScore: GroomingTaskOwnerHiddenScore
    var createdAt: Date
}

typealias GroomingTask = GroomingTaskCardData

enum GroomingTaskSubmissionStatus: String, Codable, CaseIterable, Identifiable {
    case sent
    case accepted
    case declined
    case completed
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sent: "Sent"
        case .accepted: "Accepted"
        case .declined: "Declined"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    var customerActionTitle: String {
        switch self {
        case .sent: "Task Card Sent"
        case .accepted: "Task Accepted"
        case .declined: "Task Declined"
        case .completed: "Task Completed"
        case .cancelled: "Task Cancelled"
        }
    }
}

struct GroomingTaskSubmission: Identifiable, Codable, Hashable {
    let id: UUID
    var taskID: UUID
    var sequenceCode: String
    var userID: UUID
    var groomerID: UUID
    var taskSnapshot: GroomingTask
    var status: GroomingTaskSubmissionStatus
    var sentAt: Date
    var updatedAt: Date
}

struct TaskChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var submissionID: UUID
    var senderRole: AppRole
    var senderName: String
    var body: String
    var imageURL: String?
    var createdAt: Date
}

struct TaskChatConversation: Identifiable, Hashable {
    let id: UUID
    var submission: GroomingTaskSubmission
    var counterpartName: String
    var counterpartSubtitle: String
    var lastMessage: TaskChatMessage?
    var lastActivityAt: Date
}

struct GroomingTaskTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var userID: UUID
    var name: String
    var petID: UUID
    var service: GroomingTaskService
    var timeWindow: GroomingTaskTimeWindow
    var searchArea: GroomingTaskSearchArea
    var styleGoal: String
    var specialNotes: String
    var styleReferenceSource: GroomingTaskStyleReferenceSource?
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
