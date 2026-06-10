import Foundation

struct MockAuthRepository: AuthRepository {
    func currentUser() async throws -> UserProfile {
        MockData.currentUser
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        profile
    }
}

struct MockPetRepository: PetRepository {
    func pets(for userID: UUID) async throws -> [Pet] {
        MockData.pets.filter { $0.userID == userID }
    }

    func createPet(_ pet: Pet) async throws -> Pet {
        pet
    }

    func updatePet(_ pet: Pet) async throws -> Pet {
        pet
    }

    func deletePet(id: UUID) async throws {}

    func uploadPetPhoto(_ photo: PetPhoto) async throws -> PetPhoto {
        photo
    }
}

struct MockGroomerRepository: GroomerRepository {
    func groomers() async throws -> [Groomer] {
        MockData.groomers
    }

    func groomer(id: UUID) async throws -> Groomer? {
        MockData.groomers.first { $0.id == id }
    }

    func portfolio(for groomerID: UUID) async throws -> [PortfolioItem] {
        MockData.portfolioItems.filter { $0.groomerID == groomerID }
    }
}

struct MockReviewRepository: ReviewRepository {
    func reviews(for groomerID: UUID) async throws -> [Review] {
        MockData.reviews.filter { $0.groomerID == groomerID }
    }

    func createReview(_ review: Review) async throws -> Review {
        review
    }

    func hideReview(id: UUID) async throws {}
}

struct MockFavoriteRepository: FavoriteRepository {
    func favorites(for userID: UUID) async throws -> [Favorite] {
        MockData.favorites.filter { $0.userID == userID }
    }

    func addFavorite(_ favorite: Favorite) async throws -> Favorite {
        favorite
    }

    func removeFavorite(id: UUID) async throws {}
}

struct MockContactRepository: ContactRepository {
    func logContactEvent(_ event: ContactEvent) async throws -> ContactEvent {
        event
    }

    func submitQuoteRequest(_ request: QuoteRequest) async throws -> QuoteRequest {
        request
    }
}

struct MockReportRepository: ReportRepository {
    func createReport(_ report: Report) async throws -> Report {
        report
    }

    func reports() async throws -> [Report] {
        []
    }

    func updateReportStatus(id: UUID, status: ReportStatus, notes: String?) async throws {}
}
