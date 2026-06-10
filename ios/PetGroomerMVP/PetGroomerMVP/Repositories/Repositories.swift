import Foundation

protocol AuthRepository {
    func currentUser() async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
}

protocol PetRepository {
    func pets(for userID: UUID) async throws -> [Pet]
    func createPet(_ pet: Pet) async throws -> Pet
    func updatePet(_ pet: Pet) async throws -> Pet
    func deletePet(id: UUID) async throws
    func uploadPetPhoto(_ photo: PetPhoto) async throws -> PetPhoto
}

protocol GroomerRepository {
    func groomers() async throws -> [Groomer]
    func groomer(id: UUID) async throws -> Groomer?
    func portfolio(for groomerID: UUID) async throws -> [PortfolioItem]
}

protocol ReviewRepository {
    func reviews(for groomerID: UUID) async throws -> [Review]
    func createReview(_ review: Review) async throws -> Review
    func hideReview(id: UUID) async throws
}

protocol FavoriteRepository {
    func favorites(for userID: UUID) async throws -> [Favorite]
    func addFavorite(_ favorite: Favorite) async throws -> Favorite
    func removeFavorite(id: UUID) async throws
}

protocol ContactRepository {
    func logContactEvent(_ event: ContactEvent) async throws -> ContactEvent
    func submitQuoteRequest(_ request: QuoteRequest) async throws -> QuoteRequest
}

protocol ReportRepository {
    func createReport(_ report: Report) async throws -> Report
    func reports() async throws -> [Report]
    func updateReportStatus(id: UUID, status: ReportStatus, notes: String?) async throws
}
