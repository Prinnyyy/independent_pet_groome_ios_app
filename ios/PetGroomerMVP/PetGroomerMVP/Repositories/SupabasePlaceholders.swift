import Foundation

enum SupabasePlaceholderError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "Supabase is not configured in the MVP skeleton. Add project credentials and replace the placeholder repository implementation."
    }
}

struct SupabaseAuthRepository: AuthRepository {
    func currentUser() async throws -> UserProfile {
        throw SupabasePlaceholderError.notConfigured
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        throw SupabasePlaceholderError.notConfigured
    }
}

struct SupabasePetRepository: PetRepository {
    func pets(for userID: UUID) async throws -> [Pet] {
        throw SupabasePlaceholderError.notConfigured
    }

    func createPet(_ pet: Pet) async throws -> Pet {
        throw SupabasePlaceholderError.notConfigured
    }

    func updatePet(_ pet: Pet) async throws -> Pet {
        throw SupabasePlaceholderError.notConfigured
    }

    func deletePet(id: UUID) async throws {
        throw SupabasePlaceholderError.notConfigured
    }

    func uploadPetPhoto(_ photo: PetPhoto) async throws -> PetPhoto {
        throw SupabasePlaceholderError.notConfigured
    }
}

struct SupabaseGroomerRepository: GroomerRepository {
    func groomers() async throws -> [Groomer] {
        throw SupabasePlaceholderError.notConfigured
    }

    func groomer(id: UUID) async throws -> Groomer? {
        throw SupabasePlaceholderError.notConfigured
    }

    func portfolio(for groomerID: UUID) async throws -> [PortfolioItem] {
        throw SupabasePlaceholderError.notConfigured
    }
}

struct SupabaseReviewRepository: ReviewRepository {
    func reviews(for groomerID: UUID) async throws -> [Review] {
        throw SupabasePlaceholderError.notConfigured
    }

    func createReview(_ review: Review) async throws -> Review {
        throw SupabasePlaceholderError.notConfigured
    }

    func hideReview(id: UUID) async throws {
        throw SupabasePlaceholderError.notConfigured
    }
}

struct SupabaseFavoriteRepository: FavoriteRepository {
    func favorites(for userID: UUID) async throws -> [Favorite] {
        throw SupabasePlaceholderError.notConfigured
    }

    func addFavorite(_ favorite: Favorite) async throws -> Favorite {
        throw SupabasePlaceholderError.notConfigured
    }

    func removeFavorite(id: UUID) async throws {
        throw SupabasePlaceholderError.notConfigured
    }
}

struct SupabaseContactRepository: ContactRepository {
    func logContactEvent(_ event: ContactEvent) async throws -> ContactEvent {
        throw SupabasePlaceholderError.notConfigured
    }

    func submitQuoteRequest(_ request: QuoteRequest) async throws -> QuoteRequest {
        throw SupabasePlaceholderError.notConfigured
    }
}

struct SupabaseReportRepository: ReportRepository {
    func createReport(_ report: Report) async throws -> Report {
        throw SupabasePlaceholderError.notConfigured
    }

    func reports() async throws -> [Report] {
        throw SupabasePlaceholderError.notConfigured
    }

    func updateReportStatus(id: UUID, status: ReportStatus, notes: String?) async throws {
        throw SupabasePlaceholderError.notConfigured
    }
}
