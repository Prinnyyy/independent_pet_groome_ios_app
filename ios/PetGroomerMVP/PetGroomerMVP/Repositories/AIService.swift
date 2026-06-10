import Foundation

struct AnalyzePetPhotoInput: Codable, Hashable {
    var petID: UUID
    var imageURL: String
}

struct AnalyzePetPhotoResult: Codable, Hashable {
    var breedCandidates: [String]
    var coatType: String?
    var riskFlags: [String]
}

struct SuggestPetProfileInput: Codable, Hashable {
    var petID: UUID
}

struct SuggestPetProfileResult: Codable, Hashable {
    var summary: String
    var suggestedFields: [String: String]
}

struct RecommendGroomersInput: Codable, Hashable {
    var petID: UUID
    var city: String
}

struct RecommendGroomersResult: Codable, Hashable {
    var groomerIDs: [UUID]
    var explanation: String
}

struct GenerateInquiryMessageInput: Codable, Hashable {
    var pet: Pet
    var groomer: Groomer
    var serviceType: String
}

struct GenerateInquiryMessageResult: Codable, Hashable {
    var message: String
}

struct SummarizeReviewsInput: Codable, Hashable {
    var groomerID: UUID
}

struct SummarizeReviewsResult: Codable, Hashable {
    var summary: String
    var highlights: [String]
}

struct SuggestGroomingStyleInput: Codable, Hashable {
    var petID: UUID
}

struct SuggestGroomingStyleResult: Codable, Hashable {
    var styles: [String]
}

struct GenerateStylePreviewInput: Codable, Hashable {
    var petPhotoURL: String
    var styleName: String
}

struct GenerateStylePreviewResult: Codable, Hashable {
    var previewURL: String?
}

enum AIServiceError: LocalizedError {
    case disabled

    var errorDescription: String? {
        "AI features are disabled for the MVP skeleton."
    }
}

protocol AIService {
    func analyzePetPhoto(input: AnalyzePetPhotoInput) async throws -> AnalyzePetPhotoResult
    func suggestPetProfile(input: SuggestPetProfileInput) async throws -> SuggestPetProfileResult
    func recommendGroomers(input: RecommendGroomersInput) async throws -> RecommendGroomersResult
    func generateInquiryMessage(input: GenerateInquiryMessageInput) async throws -> GenerateInquiryMessageResult
    func summarizeReviews(input: SummarizeReviewsInput) async throws -> SummarizeReviewsResult
    func suggestGroomingStyle(input: SuggestGroomingStyleInput) async throws -> SuggestGroomingStyleResult
    func generateStylePreview(input: GenerateStylePreviewInput) async throws -> GenerateStylePreviewResult
}

struct DisabledAIService: AIService {
    func analyzePetPhoto(input: AnalyzePetPhotoInput) async throws -> AnalyzePetPhotoResult {
        throw AIServiceError.disabled
    }

    func suggestPetProfile(input: SuggestPetProfileInput) async throws -> SuggestPetProfileResult {
        throw AIServiceError.disabled
    }

    func recommendGroomers(input: RecommendGroomersInput) async throws -> RecommendGroomersResult {
        throw AIServiceError.disabled
    }

    func generateInquiryMessage(input: GenerateInquiryMessageInput) async throws -> GenerateInquiryMessageResult {
        GenerateInquiryMessageResult(
            message: "Hi \(input.groomer.name), I have a \(input.pet.weight.map { "\(Int($0)) lb " } ?? "")\(input.pet.breed) looking for \(input.serviceType.lowercased()). Could you share your estimate and availability?"
        )
    }

    func summarizeReviews(input: SummarizeReviewsInput) async throws -> SummarizeReviewsResult {
        throw AIServiceError.disabled
    }

    func suggestGroomingStyle(input: SuggestGroomingStyleInput) async throws -> SuggestGroomingStyleResult {
        throw AIServiceError.disabled
    }

    func generateStylePreview(input: GenerateStylePreviewInput) async throws -> GenerateStylePreviewResult {
        throw AIServiceError.disabled
    }
}
