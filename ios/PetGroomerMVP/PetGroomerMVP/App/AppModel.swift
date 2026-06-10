import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var activeRole: AppRole
    @Published var currentUser: UserProfile
    @Published var pets: [Pet]
    @Published var petPhotos: [PetPhoto]
    @Published var groomers: [Groomer]
    @Published var portfolioItems: [PortfolioItem]
    @Published var reviews: [Review]
    @Published var favorites: [Favorite]
    @Published var contactEvents: [ContactEvent]
    @Published var quoteRequests: [QuoteRequest]
    @Published var reports: [Report]
    @Published var featureFlags: [FeatureFlag]

    private let authRepository: AuthRepository
    private let petRepository: PetRepository
    private let groomerRepository: GroomerRepository
    private let reviewRepository: ReviewRepository
    private let favoriteRepository: FavoriteRepository
    private let contactRepository: ContactRepository
    private let reportRepository: ReportRepository
    let aiService: AIService

    init(
        authRepository: AuthRepository = MockAuthRepository(),
        petRepository: PetRepository = MockPetRepository(),
        groomerRepository: GroomerRepository = MockGroomerRepository(),
        reviewRepository: ReviewRepository = MockReviewRepository(),
        favoriteRepository: FavoriteRepository = MockFavoriteRepository(),
        contactRepository: ContactRepository = MockContactRepository(),
        reportRepository: ReportRepository = MockReportRepository(),
        aiService: AIService = DisabledAIService()
    ) {
        self.authRepository = authRepository
        self.petRepository = petRepository
        self.groomerRepository = groomerRepository
        self.reviewRepository = reviewRepository
        self.favoriteRepository = favoriteRepository
        self.contactRepository = contactRepository
        self.reportRepository = reportRepository
        self.aiService = aiService

        self.activeRole = .petOwner
        self.currentUser = MockData.currentUser
        self.pets = MockData.pets
        self.petPhotos = MockData.petPhotos
        self.groomers = MockData.groomers
        self.portfolioItems = MockData.portfolioItems
        self.reviews = MockData.reviews
        self.favorites = MockData.favorites
        self.contactEvents = []
        self.quoteRequests = MockData.quoteRequests
        self.reports = []
        self.featureFlags = MockData.featureFlags
    }

    var savedGroomers: [Groomer] {
        let savedIDs = Set(favorites.filter { $0.targetType == .groomer }.map(\.targetID))
        return groomers.filter { savedIDs.contains($0.id) }
    }

    var savedPortfolio: [PortfolioItem] {
        let savedIDs = Set(favorites.filter { $0.targetType == .portfolio }.map(\.targetID))
        return portfolioItems.filter { savedIDs.contains($0.id) }
    }

    var managedGroomer: Groomer? {
        groomers.first { $0.id == MockData.managedGroomerID }
    }

    var managedGroomerID: UUID {
        MockData.managedGroomerID
    }

    func photos(for pet: Pet) -> [PetPhoto] {
        petPhotos.filter { $0.petID == pet.id }
    }

    func portfolio(for groomer: Groomer) -> [PortfolioItem] {
        portfolioItems.filter { $0.groomerID == groomer.id }
    }

    func reviews(for groomer: Groomer) -> [Review] {
        reviews.filter { $0.groomerID == groomer.id && $0.status == .published }
    }

    func quoteRequests(for groomer: Groomer) -> [QuoteRequest] {
        quoteRequests.filter { $0.groomerID == groomer.id }
    }

    func contactEvents(for groomer: Groomer) -> [ContactEvent] {
        contactEvents.filter { $0.groomerID == groomer.id }
    }

    func filteredGroomers(query: String, city: String, verifiedOnly: Bool, acceptsCatsOnly: Bool) -> [Groomer] {
        groomers.filter { groomer in
            let queryMatch = query.isEmpty ||
                groomer.name.localizedCaseInsensitiveContains(query) ||
                groomer.specialties.joined(separator: " ").localizedCaseInsensitiveContains(query) ||
                groomer.serviceAreas.joined(separator: " ").localizedCaseInsensitiveContains(query)
            let cityMatch = city == "All" || groomer.city == city
            let verifiedMatch = !verifiedOnly || groomer.isVerified
            let catMatch = !acceptsCatsOnly || groomer.acceptsCats
            return queryMatch && cityMatch && verifiedMatch && catMatch
        }
    }

    func addPet(name: String, species: PetSpecies, breed: String, weight: Double?, coatType: String, temperament: [String]) {
        let pet = Pet(
            id: UUID(),
            userID: currentUser.id,
            name: name,
            species: species,
            breed: breed,
            breedNotes: nil,
            weight: weight,
            age: nil,
            sex: nil,
            coatType: coatType,
            coatCondition: "Normal",
            temperament: temperament,
            healthNotes: nil,
            groomingHistory: "Regular grooming",
            createdAt: Date(),
            updatedAt: Date(),
            aiDetectedBreed: nil,
            aiBreedConfidence: nil,
            aiDetectedCoatType: nil,
            aiDetectedSize: nil,
            aiRiskFlags: [],
            aiProfileSummary: nil,
            aiLastAnalyzedAt: nil
        )
        pets.insert(pet, at: 0)
    }

    func updatePet(_ pet: Pet) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        var updated = pet
        updated.updatedAt = Date()
        pets[index] = updated
    }

    func deletePet(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        petPhotos.removeAll { $0.petID == pet.id }
    }

    @discardableResult
    func addMockPhoto(to pet: Pet, type: PetPhotoType) -> Bool {
        guard photos(for: pet).count < 8 else { return false }
        let photo = PetPhoto(
            id: UUID(),
            petID: pet.id,
            userID: currentUser.id,
            imageURL: "mock://pet-photo-\(Int.random(in: 1000...9999))",
            photoType: type,
            isPrimary: photos(for: pet).isEmpty,
            createdAt: Date()
        )
        petPhotos.insert(photo, at: 0)
        return true
    }

    func isFavorite(targetType: FavoriteTargetType, targetID: UUID) -> Bool {
        favorites.contains { $0.targetType == targetType && $0.targetID == targetID }
    }

    func toggleFavorite(targetType: FavoriteTargetType, targetID: UUID) {
        if let index = favorites.firstIndex(where: { $0.targetType == targetType && $0.targetID == targetID }) {
            favorites.remove(at: index)
        } else {
            favorites.append(Favorite(id: UUID(), userID: currentUser.id, targetType: targetType, targetID: targetID, createdAt: Date()))
        }
    }

    func logContact(groomer: Groomer, pet: Pet?, method: ContactMethod) {
        contactEvents.append(
            ContactEvent(id: UUID(), userID: currentUser.id, groomerID: groomer.id, petID: pet?.id, contactMethod: method, createdAt: Date())
        )
    }

    func updateGroomer(_ groomer: Groomer) {
        guard let index = groomers.firstIndex(where: { $0.id == groomer.id }) else { return }
        var updated = groomer
        updated.updatedAt = Date()
        groomers[index] = updated
    }

    func addPortfolioItem(for groomer: Groomer, breed: String, serviceType: String, styleName: String, caption: String) {
        portfolioItems.insert(
            PortfolioItem(
                id: UUID(),
                groomerID: groomer.id,
                imageURL: "mock://portfolio-\(Int.random(in: 1000...9999))",
                beforeImageURL: nil,
                afterImageURL: nil,
                petSpecies: .dog,
                breed: breed,
                serviceType: serviceType,
                styleName: styleName,
                coatCondition: "Normal",
                caption: caption,
                createdAt: Date()
            ),
            at: 0
        )
    }

    func updateQuoteStatus(_ request: QuoteRequest, status: QuoteRequestStatus) {
        guard let index = quoteRequests.firstIndex(where: { $0.id == request.id }) else { return }
        quoteRequests[index].status = status
        quoteRequests[index].updatedAt = Date()
    }

    func submitQuote(groomer: Groomer, pet: Pet?, serviceType: String, preferredTime: String, notes: String, contactPreference: String) {
        quoteRequests.append(
            QuoteRequest(
                id: UUID(),
                userID: currentUser.id,
                groomerID: groomer.id,
                petID: pet?.id,
                serviceType: serviceType,
                preferredTime: preferredTime,
                notes: notes,
                contactPreference: contactPreference,
                status: .submitted,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
        logContact(groomer: groomer, pet: pet, method: .quoteRequest)
    }

    func submitReview(groomer: Groomer, pet: Pet?, rating: Double, serviceType: String, text: String, wouldRebook: Bool) {
        let review = Review(
            id: UUID(),
            userID: currentUser.id,
            groomerID: groomer.id,
            petID: pet?.id,
            overallRating: rating,
            groomingResultRating: rating,
            communicationRating: rating,
            patienceRating: rating,
            punctualityRating: rating,
            priceTransparencyRating: rating,
            wouldRebook: wouldRebook,
            serviceType: serviceType,
            reviewText: text,
            serviceDate: Date(),
            status: .published,
            createdAt: Date(),
            updatedAt: Date(),
            aiSentiment: nil,
            aiTopics: [],
            aiRiskFlag: false,
            aiSummary: nil
        )
        reviews.insert(review, at: 0)
    }

    func submitReport(targetType: ReportTargetType, targetID: UUID, reason: ReportReason, details: String) {
        reports.append(
            Report(
                id: UUID(),
                reporterUserID: currentUser.id,
                targetType: targetType,
                targetID: targetID,
                reason: reason,
                details: details,
                status: .open,
                adminNotes: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}
