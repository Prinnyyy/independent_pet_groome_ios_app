import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var activeRole: AppRole
    @Published var currentUser: UserProfile
    @Published var customerPersonalProfile: CustomerPersonalProfile
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
    @Published var savedGroomingTaskTemplates: [GroomingTaskTemplate]
    @Published var groomingTasks: [GroomingTask]
    @Published var groomingTaskSubmissions: [GroomingTaskSubmission]
    @Published var customerOrderRecords: [CardExchangeOrderRecord]
    @Published var groomerOrderRecords: [CardExchangeOrderRecord]
    @Published var petProfilePackages: [PetProfilePackage]
    @Published var taskChatMessages: [TaskChatMessage]
    @Published var currentGroomingTask: GroomingTask?

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
        self.customerPersonalProfile = CustomerPersonalProfile(
            id: UUID(),
            userID: MockData.currentUser.id,
            fullName: MockData.currentUser.displayName,
            gender: .notSpecified,
            address: ProfileAddress(
                streetLine1: "120 W Wilshire Ave",
                streetLine2: "",
                city: MockData.currentUser.city,
                state: "CA",
                postalCode: MockData.currentUser.zipCode,
                country: "United States"
            ),
            phone: "714-555-0190",
            email: MockData.currentUser.email ?? "taylor@example.com",
            updatedAt: Date()
        )
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
        self.savedGroomingTaskTemplates = []
        self.groomingTasks = []
        self.groomingTaskSubmissions = []
        self.customerOrderRecords = []
        self.groomerOrderRecords = []
        self.petProfilePackages = []
        self.taskChatMessages = []
        self.currentGroomingTask = nil
        refreshAllPetProfilePackages()
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

    func petProfilePackage(for petID: UUID) -> PetProfilePackage? {
        if let package = petProfilePackages.first(where: { $0.petID == petID }) {
            return package
        }
        guard let pet = pets.first(where: { $0.id == petID }) else { return nil }
        return makePetProfilePackage(for: pet, now: Date())
    }

    func petProfilePackage(for link: CardAccessLink) -> PetProfilePackage? {
        petProfilePackage(for: link.cardID)
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

    func updateCustomerPersonalProfile(_ profile: CustomerPersonalProfile) {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        customerPersonalProfile = updatedProfile

        currentUser.displayName = updatedProfile.fullName
        currentUser.email = updatedProfile.email
        currentUser.city = updatedProfile.address.city
        currentUser.zipCode = updatedProfile.address.postalCode
        currentUser.updatedAt = updatedProfile.updatedAt
    }

    func pet(for task: GroomingTask) -> Pet? {
        pets.first { $0.id == task.petID } ?? task.petSnapshot
    }

    func saveGroomingTask(
        pet: Pet,
        service: GroomingTaskService,
        targetDate: Date,
        timeWindow: GroomingTaskTimeWindow,
        searchArea: GroomingTaskSearchArea,
        styleGoal: String,
        specialNotes: String,
        styleReferenceSource: GroomingTaskStyleReferenceSource?,
        styleReferenceImageData: Data?
    ) {
        let sequenceCode = Self.makeTaskSequenceCode()
        let taskID = UUID()
        let now = Date()
        let petProfilePackage = refreshPetProfilePackage(for: pet)
        let localPackageLink = CardAccessLink(
            id: UUID(),
            cardKind: .customerTask,
            storageScope: .customerLocalPackage,
            ownerRole: .petOwner,
            ownerEntityID: currentUser.id,
            cardID: taskID,
            url: "local://customer/task-cards/\(taskID.uuidString)",
            version: 1,
            createdAt: now
        )
        let task = GroomingTask(
            id: taskID,
            sequenceCode: sequenceCode,
            userID: currentUser.id,
            petID: pet.id,
            petSnapshot: pet,
            petPhotoSnapshots: photos(for: pet),
            petProfileLink: petProfilePackage.serverProfileLink,
            service: service,
            targetDate: targetDate,
            timeWindow: timeWindow,
            searchArea: searchArea,
            styleGoal: styleGoal,
            specialNotes: specialNotes,
            styleReferenceSource: styleReferenceSource,
            localPackageLink: localPackageLink,
            referenceImageSlot: GroomingTaskReferenceImageSlot.reserved(source: styleReferenceSource, sequenceCode: sequenceCode, imageData: styleReferenceImageData),
            ownerHiddenScore: ownerHiddenScore(for: currentUser.id),
            createdAt: now
        )
        currentGroomingTask = task
        groomingTasks.insert(task, at: 0)
    }

    func cancelGroomingTask() {
        currentGroomingTask = nil
    }

    func groomingTask(sequenceCode: String) -> GroomingTask? {
        groomingTasks.first { $0.sequenceCode.caseInsensitiveCompare(sequenceCode) == .orderedSame }
    }

    func taskSubmissions(for groomer: Groomer) -> [GroomingTaskSubmission] {
        groomingTaskSubmissions
            .filter { $0.groomerID == groomer.id }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func scheduledTaskSubmissions(for groomer: Groomer) -> [GroomingTaskSubmission] {
        groomingTaskSubmissions
            .filter { submission in
                submission.groomerID == groomer.id &&
                    [.accepted, .completed, .cancelled].contains(submission.status)
            }
            .sorted {
                if $0.taskSnapshot.targetDate == $1.taskSnapshot.targetDate {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.taskSnapshot.targetDate < $1.taskSnapshot.targetDate
            }
    }

    func scheduledTaskSubmissions(for groomer: Groomer, on date: Date) -> [GroomingTaskSubmission] {
        scheduledTaskSubmissions(for: groomer)
            .filter { Calendar.current.isDate($0.taskSnapshot.targetDate, inSameDayAs: date) }
    }

    func taskSubmission(id: UUID) -> GroomingTaskSubmission? {
        groomingTaskSubmissions.first { $0.id == id }
    }

    func taskSubmission(for task: GroomingTask, groomer: Groomer) -> GroomingTaskSubmission? {
        groomingTaskSubmissions.first { $0.taskID == task.id && $0.groomerID == groomer.id }
    }

    func pendingTaskSubmission(for task: GroomingTask, groomer: Groomer) -> GroomingTaskSubmission? {
        groomingTaskSubmissions.first { $0.taskID == task.id && $0.groomerID == groomer.id && $0.status == .sent }
    }

    func acceptedTaskSubmission(for task: GroomingTask) -> GroomingTaskSubmission? {
        groomingTaskSubmissions.first { $0.taskID == task.id && $0.status == .accepted }
    }

    func orderRecords(for role: AppRole) -> [CardExchangeOrderRecord] {
        switch role {
        case .petOwner:
            customerOrderRecords.sorted { $0.updatedAt > $1.updatedAt }
        case .groomer:
            groomerOrderRecords.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func orderRecord(exchangeID: UUID, for role: AppRole) -> CardExchangeOrderRecord? {
        orderRecords(for: role).first { $0.exchangeID == exchangeID }
    }

    func taskSubmission(for order: CardExchangeOrderRecord) -> GroomingTaskSubmission? {
        groomingTaskSubmissions.first { $0.exchangeID == order.exchangeID }
    }

    func groomer(for order: CardExchangeOrderRecord) -> Groomer? {
        groomers.first { $0.id == order.groomerID }
    }

    @discardableResult
    func sendCurrentTask(to groomer: Groomer) -> GroomingTaskSubmission? {
        guard let task = currentGroomingTask else { return nil }
        if let existing = pendingTaskSubmission(for: task, groomer: groomer) {
            return existing
        }

        let exchangeID = UUID()
        let submissionID = UUID()
        let customerOrderID = UUID()
        let groomerOrderID = UUID()
        let now = Date()
        let groomerCardLink = publicGroomerCardLink(for: groomer)
        let groomerInboxLink = CardAccessLink(
            id: UUID(),
            cardKind: .customerTask,
            storageScope: .groomerInboxPackage,
            ownerRole: .groomer,
            ownerEntityID: groomer.id,
            cardID: task.id,
            url: "local://groomer/\(groomer.id.uuidString)/inbox/task-cards/\(task.id.uuidString)",
            version: task.localPackageLink.version,
            createdAt: now
        )
        let customerOrderRecord = makeOrderRecord(
            id: customerOrderID,
            exchangeID: exchangeID,
            storedForRole: .petOwner,
            localStoreScope: .customerOrderStore,
            customerID: task.userID,
            groomerID: groomer.id,
            taskCardLink: task.localPackageLink,
            groomerCardLink: groomerCardLink,
            now: now
        )
        let groomerOrderRecord = makeOrderRecord(
            id: groomerOrderID,
            exchangeID: exchangeID,
            storedForRole: .groomer,
            localStoreScope: .groomerOrderStore,
            customerID: task.userID,
            groomerID: groomer.id,
            taskCardLink: groomerInboxLink,
            groomerCardLink: groomerCardLink,
            now: now
        )
        let submission = GroomingTaskSubmission(
            id: submissionID,
            exchangeID: exchangeID,
            taskID: task.id,
            sequenceCode: task.sequenceCode,
            userID: task.userID,
            groomerID: groomer.id,
            taskSnapshot: task,
            taskCardLink: task.localPackageLink,
            groomerCardLink: groomerCardLink,
            groomerInboxLink: groomerInboxLink,
            customerOrderID: customerOrderID,
            groomerOrderID: groomerOrderID,
            status: .sent,
            sentAt: now,
            updatedAt: now
        )
        groomingTaskSubmissions.insert(submission, at: 0)
        customerOrderRecords.insert(customerOrderRecord, at: 0)
        groomerOrderRecords.insert(groomerOrderRecord, at: 0)
        logContact(groomer: groomer, pet: task.petSnapshot, method: .quoteRequest)
        return submission
    }

    func updateTaskSubmissionStatus(id: UUID, status: GroomingTaskSubmissionStatus) {
        guard let index = groomingTaskSubmissions.firstIndex(where: { $0.id == id }) else { return }
        groomingTaskSubmissions[index].status = status
        groomingTaskSubmissions[index].updatedAt = Date()
        updateOrderRecords(exchangeID: groomingTaskSubmissions[index].exchangeID, status: CardExchangeOrderStatus(submissionStatus: status))
        if status == .accepted {
            cancelCompetingSubmissions(for: groomingTaskSubmissions[index])
        }
    }

    func cancelTaskSubmission(id: UUID) {
        updateTaskSubmissionStatus(id: id, status: .cancelled)
    }

    func revokeTaskSubmission(id: UUID) {
        guard let submission = groomingTaskSubmissions.first(where: { $0.id == id }), submission.status == .sent else { return }
        updateTaskSubmissionStatus(id: id, status: .cancelled)
    }

    func messages(for submissionID: UUID) -> [TaskChatMessage] {
        taskChatMessages
            .filter { $0.submissionID == submissionID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func chatConversations(for viewerRole: AppRole) -> [TaskChatConversation] {
        groomingTaskSubmissions
            .filter { submission in
                switch viewerRole {
                case .petOwner:
                    submission.userID == currentUser.id
                case .groomer:
                    submission.groomerID == managedGroomerID
                }
            }
            .compactMap { submission in
                let conversationMessages = messages(for: submission.id)
                let lastMessage = conversationMessages.last
                return TaskChatConversation(
                    id: submission.id,
                    submission: submission,
                    counterpartName: counterpartName(for: submission, viewerRole: viewerRole),
                    counterpartSubtitle: "\(submission.taskSnapshot.petSnapshot.name) · \(submission.taskSnapshot.service.rawValue)",
                    lastMessage: lastMessage,
                    lastActivityAt: lastMessage?.createdAt ?? submission.updatedAt
                )
            }
            .sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    func sendTaskMessage(submissionID: UUID, senderRole: AppRole, body: String, imageURL: String? = nil) {
        let cleaned = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty || imageURL != nil else { return }

        let senderName: String
        switch senderRole {
        case .petOwner:
            senderName = currentUser.displayName
        case .groomer:
            senderName = managedGroomer?.name ?? "Groomer"
        }

        let message = TaskChatMessage(
            id: UUID(),
            submissionID: submissionID,
            senderRole: senderRole,
            senderName: senderName,
            body: cleaned,
            imageURL: imageURL,
            createdAt: Date()
        )
        taskChatMessages.append(message)

        if let index = groomingTaskSubmissions.firstIndex(where: { $0.id == submissionID }) {
            groomingTaskSubmissions[index].updatedAt = Date()
        }
    }

    func sendTaskImageMessage(submissionID: UUID, senderRole: AppRole) {
        sendTaskMessage(
            submissionID: submissionID,
            senderRole: senderRole,
            body: "",
            imageURL: "mock://chat-photo-\(Int.random(in: 1000...9999))"
        )
    }

    @discardableResult
    func saveCurrentGroomingTaskAsTemplate() -> GroomingTaskTemplate? {
        guard let task = currentGroomingTask, let pet = pet(for: task) else { return nil }

        let template = GroomingTaskTemplate(
            id: UUID(),
            userID: currentUser.id,
            name: "\(pet.name) · \(task.service.rawValue)",
            petID: task.petID,
            service: task.service,
            timeWindow: task.timeWindow,
            searchArea: task.searchArea,
            styleGoal: task.styleGoal,
            specialNotes: task.specialNotes,
            styleReferenceSource: task.styleReferenceSource,
            createdAt: Date()
        )

        savedGroomingTaskTemplates.removeAll { existing in
            existing.petID == template.petID &&
                existing.service == template.service &&
                existing.timeWindow == template.timeWindow &&
                existing.searchArea == template.searchArea &&
                existing.styleGoal == template.styleGoal &&
                existing.specialNotes == template.specialNotes &&
                existing.styleReferenceSource == template.styleReferenceSource
        }
        savedGroomingTaskTemplates.insert(template, at: 0)
        return template
    }

    func recommendedGroomers(for task: GroomingTask) -> [Groomer] {
        guard let pet = pet(for: task) else { return groomers }

        return groomers
            .filter { groomer in
                guard groomer.status == .published else { return false }
                let speciesMatch = pet.species == .cat ? groomer.acceptsCats : groomer.acceptsDogs
                let sizeMatch = pet.species == .cat || acceptedSize(for: pet).map { groomer.sizeAccepted.contains($0) } ?? true
                return speciesMatch && sizeMatch && locationMatches(groomer: groomer, searchArea: task.searchArea)
            }
            .sorted { lhs, rhs in
                recommendationScore(groomer: lhs, pet: pet, task: task) > recommendationScore(groomer: rhs, pet: pet, task: task)
            }
    }

    private func acceptedSize(for pet: Pet) -> String? {
        guard pet.species == .dog, let weight = pet.weight else { return nil }
        if weight <= 20 { return "Small" }
        if weight <= 50 { return "Medium" }
        return "Large"
    }

    private static func makeTaskSequenceCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let suffix = String((0..<6).compactMap { _ in alphabet.randomElement() })
        return "GT-\(suffix)"
    }

    private func ownerHiddenScore(for userID: UUID) -> GroomingTaskOwnerHiddenScore {
        let lastVisibleReview = reviews
            .filter { $0.userID == userID }
            .sorted { $0.createdAt > $1.createdAt }
            .first

        let score = min(5.0, max(1.0, (lastVisibleReview?.overallRating ?? 4.6) - 0.1))
        return GroomingTaskOwnerHiddenScore(
            value: score,
            source: "Last groomer client evaluation",
            lastEvaluatedAt: lastVisibleReview?.createdAt
        )
    }

    private func recommendationScore(groomer: Groomer, pet: Pet, task: GroomingTask) -> Double {
        var score = groomer.rating

        if groomer.city == task.searchArea.city || groomer.serviceAreas.contains(task.searchArea.city) {
            score += 3
        } else if task.searchArea.radiusMiles >= 25 {
            score += 0.8
        }
        if groomer.isVerified {
            score += 1.4
        }
        if serviceMatches(groomer: groomer, service: task.service) {
            score += 2.4
        }
        if groomer.specialties.contains(pet.breed) {
            score += 1.6
        }
        if pet.temperament.contains(where: { temperament in groomer.specialties.contains(temperament) }) {
            score += 1.2
        }
        if pet.coatCondition.localizedCaseInsensitiveContains("matting") && groomer.specialties.contains("De-matting") {
            score += 1.5
        }
        if !task.specialNotes.isEmpty {
            score += 0.2
        }

        return score
    }

    private func locationMatches(groomer: Groomer, searchArea: GroomingTaskSearchArea) -> Bool {
        if groomer.city == searchArea.city || groomer.serviceAreas.contains(searchArea.city) {
            return true
        }

        return searchArea.radiusMiles >= 25
    }

    private func serviceMatches(groomer: Groomer, service: GroomingTaskService) -> Bool {
        switch service {
        case .bath, .nailTrim, .sanitaryTrim:
            true
        case .fullGroom:
            groomer.serviceMethods.contains("Home studio") || groomer.serviceMethods.contains("Mobile grooming") || groomer.specialties.contains("Teddy cut")
        case .haircut, .faceTrim:
            groomer.specialties.contains("Teddy cut") || groomer.specialties.contains("Asian fusion style") || groomer.specialties.contains("Poodle")
        case .dematting:
            groomer.specialties.contains("De-matting")
        case .catGrooming:
            groomer.acceptsCats || groomer.specialties.contains("Cats")
        }
    }

    func addPet(
        name: String,
        species: PetSpecies,
        breed: String,
        weight: Double?,
        age: Double?,
        sex: String?,
        temperament: [String],
        healthNotes: String?
    ) {
        let pet = Pet(
            id: UUID(),
            userID: currentUser.id,
            name: name,
            species: species,
            breed: breed,
            breedNotes: nil,
            weight: weight,
            age: age,
            sex: sex,
            coatType: "",
            coatCondition: "Normal",
            temperament: temperament,
            healthNotes: healthNotes,
            groomingHistory: nil,
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
        refreshPetProfilePackage(for: pet)
    }

    func updatePet(_ pet: Pet) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        var updated = pet
        updated.updatedAt = Date()
        pets[index] = updated
        refreshPetProfilePackage(for: updated)
    }

    func deletePet(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        petPhotos.removeAll { $0.petID == pet.id }
        petProfilePackages.removeAll { $0.petID == pet.id }
    }

    @discardableResult
    func addMockPhoto(to pet: Pet, type: PetPhotoType) -> Bool {
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
        refreshPetProfilePackage(for: pet)
        return true
    }

    @discardableResult
    func savePetPhoto(to pet: Pet, type: PetPhotoType, imageData: Data?) -> Bool {
        let replacesExistingSlot = type != .other
        if replacesExistingSlot, let index = petPhotos.firstIndex(where: { $0.petID == pet.id && $0.photoType == type }) {
            petPhotos[index].imageURL = "local://pet-photo-\(UUID().uuidString)"
            petPhotos[index].imageData = imageData
            petPhotos[index].createdAt = Date()
            refreshPetProfilePackage(for: pet)
            return true
        }

        let photo = PetPhoto(
            id: UUID(),
            petID: pet.id,
            userID: currentUser.id,
            imageURL: "local://pet-photo-\(UUID().uuidString)",
            photoType: type,
            isPrimary: photos(for: pet).isEmpty,
            createdAt: Date(),
            imageData: imageData
        )
        petPhotos.insert(photo, at: 0)
        refreshPetProfilePackage(for: pet)
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

    func publicGroomerCardLink(for groomer: Groomer) -> CardAccessLink {
        CardAccessLink(
            id: groomer.id,
            cardKind: .groomerProfile,
            storageScope: .publicServerCard,
            ownerRole: .groomer,
            ownerEntityID: groomer.id,
            cardID: groomer.id,
            url: "https://pet-groomer.local/groomers/\(groomer.id.uuidString.lowercased())",
            version: 1,
            createdAt: groomer.updatedAt
        )
    }

    @discardableResult
    private func refreshPetProfilePackage(for pet: Pet) -> PetProfilePackage {
        let now = Date()
        let package = makePetProfilePackage(for: pet, now: now)
        if let packageIndex = petProfilePackages.firstIndex(where: { $0.petID == pet.id }) {
            petProfilePackages[packageIndex] = package
        } else {
            petProfilePackages.insert(package, at: 0)
        }
        if let petIndex = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[petIndex].localProfileLink = package.localProfileLink
            pets[petIndex].serverProfileLink = package.serverProfileLink
        }
        return package
    }

    private func refreshAllPetProfilePackages() {
        let currentPets = pets
        currentPets.forEach { refreshPetProfilePackage(for: $0) }
    }

    private func makePetProfilePackage(for pet: Pet, now: Date) -> PetProfilePackage {
        let localLink = CardAccessLink(
            id: UUID(),
            cardKind: .petProfile,
            storageScope: .customerPetProfileStore,
            ownerRole: .petOwner,
            ownerEntityID: pet.userID,
            cardID: pet.id,
            url: "local://customer/pet-profiles/\(pet.id.uuidString)",
            version: 1,
            createdAt: now
        )
        let serverLink = CardAccessLink(
            id: pet.id,
            cardKind: .petProfile,
            storageScope: .serverPetProfileStore,
            ownerRole: .petOwner,
            ownerEntityID: pet.userID,
            cardID: pet.id,
            url: "https://pet-groomer.local/pet-profiles/\(pet.id.uuidString.lowercased())",
            version: 1,
            createdAt: now
        )
        var snapshot = pet
        snapshot.localProfileLink = localLink
        snapshot.serverProfileLink = serverLink
        return PetProfilePackage(
            id: pet.id,
            petID: pet.id,
            userID: pet.userID,
            petSnapshot: snapshot,
            photoSnapshots: photos(for: pet),
            localProfileLink: localLink,
            serverProfileLink: serverLink,
            updatedAt: now
        )
    }

    private func makeOrderRecord(
        id: UUID,
        exchangeID: UUID,
        storedForRole: AppRole,
        localStoreScope: CardStorageScope,
        customerID: UUID,
        groomerID: UUID,
        taskCardLink: CardAccessLink,
        groomerCardLink: CardAccessLink,
        now: Date
    ) -> CardExchangeOrderRecord {
        CardExchangeOrderRecord(
            id: id,
            exchangeID: exchangeID,
            storedForRole: storedForRole,
            localStoreLink: CardAccessLink(
                id: UUID(),
                cardKind: .exchangeOrder,
                storageScope: localStoreScope,
                ownerRole: storedForRole,
                ownerEntityID: storedForRole == .petOwner ? customerID : groomerID,
                cardID: id,
                url: "local://\(localStoreScope.rawValue)/orders/\(id.uuidString)",
                version: 1,
                createdAt: now
            ),
            customerID: customerID,
            groomerID: groomerID,
            taskCardLink: taskCardLink,
            groomerCardLink: groomerCardLink,
            status: .waitingReply,
            createdAt: now,
            updatedAt: now
        )
    }

    private func updateOrderRecords(exchangeID: UUID, status: CardExchangeOrderStatus) {
        let now = Date()
        if let customerIndex = customerOrderRecords.firstIndex(where: { $0.exchangeID == exchangeID }) {
            customerOrderRecords[customerIndex].status = status
            customerOrderRecords[customerIndex].updatedAt = now
        }
        if let groomerIndex = groomerOrderRecords.firstIndex(where: { $0.exchangeID == exchangeID }) {
            groomerOrderRecords[groomerIndex].status = status
            groomerOrderRecords[groomerIndex].updatedAt = now
        }
    }

    private func cancelCompetingSubmissions(for acceptedSubmission: GroomingTaskSubmission) {
        let now = Date()
        let competingIndexes = groomingTaskSubmissions.indices.filter { index in
            let submission = groomingTaskSubmissions[index]
            return submission.taskID == acceptedSubmission.taskID &&
                submission.id != acceptedSubmission.id &&
                submission.status == .sent
        }

        for index in competingIndexes {
            groomingTaskSubmissions[index].status = .cancelled
            groomingTaskSubmissions[index].updatedAt = now
            updateOrderRecords(exchangeID: groomingTaskSubmissions[index].exchangeID, status: .cancelled)
        }
    }

    private func counterpartName(for submission: GroomingTaskSubmission, viewerRole: AppRole) -> String {
        switch viewerRole {
        case .petOwner:
            groomers.first { $0.id == submission.groomerID }?.name ?? "Groomer"
        case .groomer:
            currentUser.displayName
        }
    }
}
