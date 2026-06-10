import Foundation

enum MockData {
    static let userID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let petMochiID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let petLunaID = UUID(uuidString: "22222222-2222-2222-2222-222222222223")!
    static let groomerAvaID = UUID(uuidString: "33333333-3333-3333-3333-333333333331")!
    static let groomerMiaID = UUID(uuidString: "33333333-3333-3333-3333-333333333332")!
    static let groomerLeoID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let portfolioOneID = UUID(uuidString: "44444444-4444-4444-4444-444444444441")!
    static let portfolioTwoID = UUID(uuidString: "44444444-4444-4444-4444-444444444442")!
    static let portfolioThreeID = UUID(uuidString: "44444444-4444-4444-4444-444444444443")!
    static let managedGroomerID = groomerAvaID

    static let currentUser = UserProfile(
        id: userID,
        email: "demo@petgroomer.local",
        appleUserID: nil,
        displayName: "Taylor Chen",
        avatarURL: nil,
        city: "Fullerton",
        zipCode: "92832",
        languagePreference: "en",
        createdAt: .now,
        updatedAt: .now
    )

    static let pets: [Pet] = [
        Pet(
            id: petMochiID,
            userID: userID,
            name: "Mochi",
            species: .dog,
            breed: "Maltipoo",
            breedNotes: "Curly coat, compact body",
            weight: 15,
            age: 4,
            sex: "Male",
            coatType: "Curly",
            coatCondition: "Light matting",
            temperament: ["Anxious", "Afraid of dryers"],
            healthNotes: "Sensitive around ears",
            groomingHistory: "Regular grooming",
            createdAt: .now,
            updatedAt: .now,
            aiDetectedBreed: nil,
            aiBreedConfidence: nil,
            aiDetectedCoatType: nil,
            aiDetectedSize: nil,
            aiRiskFlags: [],
            aiProfileSummary: nil,
            aiLastAnalyzedAt: nil
        ),
        Pet(
            id: petLunaID,
            userID: userID,
            name: "Luna",
            species: .cat,
            breed: "Domestic longhair",
            breedNotes: nil,
            weight: 10,
            age: 7,
            sex: "Female",
            coatType: "Long hair",
            coatCondition: "Shedding",
            temperament: ["Calm", "Senior pet"],
            healthNotes: nil,
            groomingHistory: "Previous bad experience",
            createdAt: .now,
            updatedAt: .now,
            aiDetectedBreed: nil,
            aiBreedConfidence: nil,
            aiDetectedCoatType: nil,
            aiDetectedSize: nil,
            aiRiskFlags: [],
            aiProfileSummary: nil,
            aiLastAnalyzedAt: nil
        )
    ]

    static let petPhotos: [PetPhoto] = [
        PetPhoto(id: UUID(), petID: petMochiID, userID: userID, imageURL: "mock://mochi-front", photoType: .front, isPrimary: true, createdAt: .now),
        PetPhoto(id: UUID(), petID: petMochiID, userID: userID, imageURL: "mock://mochi-coat", photoType: .coatCloseUp, isPrimary: false, createdAt: .now),
        PetPhoto(id: UUID(), petID: petLunaID, userID: userID, imageURL: "mock://luna-side", photoType: .side, isPrimary: true, createdAt: .now)
    ]

    static let groomers: [Groomer] = [
        Groomer(
            id: groomerAvaID,
            name: "Ava Park",
            profilePhotoURL: nil,
            bio: "Independent stylist focused on doodles, poodles, and calm one-on-one sessions for nervous dogs.",
            city: "Fullerton",
            zipCode: "92832",
            serviceRadius: 12,
            serviceAreas: ["Fullerton", "Brea", "Anaheim"],
            languages: ["English", "Korean"],
            yearsExperience: 8,
            serviceMethods: ["Home studio", "Mobile grooming"],
            acceptsDogs: true,
            acceptsCats: false,
            sizeAccepted: ["Small", "Medium"],
            specialties: ["Doodle", "Poodle", "Teddy cut", "Anxious pets"],
            priceMin: 85,
            priceMax: 165,
            phone: "7145550124",
            smsNumber: "7145550124",
            instagramURL: "https://instagram.com/example",
            wechatID: nil,
            websiteURL: "https://example.com",
            email: "ava@example.com",
            isVerified: true,
            status: .published,
            rating: 4.9,
            reviewCount: 42,
            createdAt: .now,
            updatedAt: .now,
            aiSummary: nil,
            aiSkillTags: [],
            aiReviewSummary: nil,
            aiLastProcessedAt: nil
        ),
        Groomer(
            id: groomerMiaID,
            name: "Mia Santos",
            profilePhotoURL: nil,
            bio: "Gentle cat and senior pet grooming with clear price ranges and low-stress handling.",
            city: "Irvine",
            zipCode: "92612",
            serviceRadius: 15,
            serviceAreas: ["Irvine", "Tustin", "Costa Mesa"],
            languages: ["English", "Spanish"],
            yearsExperience: 6,
            serviceMethods: ["In-home grooming"],
            acceptsDogs: true,
            acceptsCats: true,
            sizeAccepted: ["Small", "Medium", "Cats"],
            specialties: ["Cats", "Senior pets", "De-matting", "Sensitive skin"],
            priceMin: 95,
            priceMax: 180,
            phone: "9495550199",
            smsNumber: "9495550199",
            instagramURL: nil,
            wechatID: nil,
            websiteURL: nil,
            email: "mia@example.com",
            isVerified: true,
            status: .published,
            rating: 4.8,
            reviewCount: 31,
            createdAt: .now,
            updatedAt: .now,
            aiSummary: nil,
            aiSkillTags: [],
            aiReviewSummary: nil,
            aiLastProcessedAt: nil
        ),
        Groomer(
            id: groomerLeoID,
            name: "Leo Wu",
            profilePhotoURL: nil,
            bio: "Asian fusion styling and compact mobile appointments for small breeds across the San Gabriel Valley.",
            city: "Arcadia",
            zipCode: "91007",
            serviceRadius: 18,
            serviceAreas: ["Arcadia", "Pasadena", "Alhambra"],
            languages: ["English", "Mandarin"],
            yearsExperience: 10,
            serviceMethods: ["Mobile grooming", "Partner grooming station"],
            acceptsDogs: true,
            acceptsCats: false,
            sizeAccepted: ["Small"],
            specialties: ["Asian fusion style", "Bichon", "Maltipoo", "Small dogs"],
            priceMin: 105,
            priceMax: 210,
            phone: nil,
            smsNumber: "6265550188",
            instagramURL: "https://instagram.com/example",
            wechatID: "leogrooms",
            websiteURL: nil,
            email: "leo@example.com",
            isVerified: false,
            status: .published,
            rating: 4.7,
            reviewCount: 26,
            createdAt: .now,
            updatedAt: .now,
            aiSummary: nil,
            aiSkillTags: [],
            aiReviewSummary: nil,
            aiLastProcessedAt: nil
        )
    ]

    static let portfolioItems: [PortfolioItem] = [
        PortfolioItem(
            id: portfolioOneID,
            groomerID: groomerAvaID,
            imageURL: "mock://portfolio-doodle-teddy",
            beforeImageURL: nil,
            afterImageURL: "mock://portfolio-doodle-teddy-after",
            petSpecies: .dog,
            breed: "Mini Goldendoodle",
            serviceType: "Full groom",
            styleName: "Teddy cut",
            coatCondition: "Light matting",
            caption: "Soft teddy face with practical body length for a curly coat.",
            createdAt: .now
        ),
        PortfolioItem(
            id: portfolioTwoID,
            groomerID: groomerMiaID,
            imageURL: "mock://portfolio-cat-sanitary",
            beforeImageURL: nil,
            afterImageURL: "mock://portfolio-cat-sanitary-after",
            petSpecies: .cat,
            breed: "Domestic longhair",
            serviceType: "Cat grooming",
            styleName: "Sanitary trim",
            coatCondition: "Shedding",
            caption: "Low-stress comb-out and sanitary trim for an older longhair cat.",
            createdAt: .now
        ),
        PortfolioItem(
            id: portfolioThreeID,
            groomerID: groomerLeoID,
            imageURL: "mock://portfolio-bichon-round",
            beforeImageURL: nil,
            afterImageURL: "mock://portfolio-bichon-round-after",
            petSpecies: .dog,
            breed: "Bichon",
            serviceType: "Haircut",
            styleName: "Bichon round head",
            coatCondition: "Normal",
            caption: "Round head and balanced legs for a clean Asian fusion profile.",
            createdAt: .now
        )
    ]

    static let reviews: [Review] = [
        Review(
            id: UUID(),
            userID: userID,
            groomerID: groomerAvaID,
            petID: petMochiID,
            overallRating: 5,
            groomingResultRating: 5,
            communicationRating: 5,
            patienceRating: 5,
            punctualityRating: 5,
            priceTransparencyRating: 5,
            wouldRebook: true,
            serviceType: "Full groom",
            reviewText: "Ava explained every step and Mochi came home calm with the exact teddy face I asked for.",
            serviceDate: .now,
            status: .published,
            createdAt: .now,
            updatedAt: .now,
            aiSentiment: nil,
            aiTopics: [],
            aiRiskFlag: false,
            aiSummary: nil
        ),
        Review(
            id: UUID(),
            userID: userID,
            groomerID: groomerMiaID,
            petID: petLunaID,
            overallRating: 4.8,
            groomingResultRating: 5,
            communicationRating: 5,
            patienceRating: 5,
            punctualityRating: 4,
            priceTransparencyRating: 5,
            wouldRebook: true,
            serviceType: "Cat grooming",
            reviewText: "Clear pricing, quiet setup, and a patient approach for Luna.",
            serviceDate: .now,
            status: .published,
            createdAt: .now,
            updatedAt: .now,
            aiSentiment: nil,
            aiTopics: [],
            aiRiskFlag: false,
            aiSummary: nil
        )
    ]

    static let favorites: [Favorite] = [
        Favorite(id: UUID(), userID: userID, targetType: .groomer, targetID: groomerAvaID, createdAt: .now),
        Favorite(id: UUID(), userID: userID, targetType: .portfolio, targetID: portfolioOneID, createdAt: .now)
    ]

    static let quoteRequests: [QuoteRequest] = [
        QuoteRequest(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555551")!,
            userID: userID,
            groomerID: groomerAvaID,
            petID: petMochiID,
            serviceType: "Full groom",
            preferredTime: "This weekend",
            notes: "Mochi has light matting around the ears and gets nervous around dryers.",
            contactPreference: "SMS",
            status: .submitted,
            createdAt: .now,
            updatedAt: .now
        ),
        QuoteRequest(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555552")!,
            userID: userID,
            groomerID: groomerAvaID,
            petID: nil,
            serviceType: "Face trim",
            preferredTime: "Next week",
            notes: "Looking for a quick cleanup before family photos.",
            contactPreference: "Email",
            status: .viewed,
            createdAt: .now,
            updatedAt: .now
        )
    ]

    static let featureFlags: [FeatureFlag] = [
        FeatureFlag(key: "ai_pet_photo_analysis", isEnabled: false, description: "Analyze pet photos for breed, coat, and risk hints."),
        FeatureFlag(key: "ai_pet_profile_suggestion", isEnabled: false, description: "Suggest pet profile fields from photos and notes."),
        FeatureFlag(key: "ai_groomer_recommendation", isEnabled: false, description: "Explain groomer matches after database filtering."),
        FeatureFlag(key: "ai_inquiry_message", isEnabled: false, description: "Draft quote/contact messages from pet context."),
        FeatureFlag(key: "ai_review_summary", isEnabled: false, description: "Summarize public review themes."),
        FeatureFlag(key: "ai_style_suggestion", isEnabled: false, description: "Suggest grooming styles."),
        FeatureFlag(key: "ai_style_preview_generation", isEnabled: false, description: "Generate preview images. Out of MVP scope.")
    ]
}
