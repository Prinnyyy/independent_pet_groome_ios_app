import SwiftUI
import UIKit

struct GroomerProfileView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var showQuote = false
    @State private var showReview = false
    @State private var showReport = false

    let groomer: Groomer

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        MockPhotoBlock(title: groomer.name, systemImage: "scissors", height: 96)
                            .frame(width: 96)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(groomer.name)
                                    .font(.largeTitle.weight(.bold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(PetTheme.ink)
                                Spacer()
                                Button {
                                    model.toggleFavorite(targetType: .groomer, targetID: groomer.id)
                                } label: {
                                    Image(systemName: model.isFavorite(targetType: .groomer, targetID: groomer.id) ? "heart.fill" : "heart")
                                        .font(.title2)
                                        .foregroundStyle(PetTheme.coral)
                                        .frame(width: 40, height: 40)
                                }
                            }
                            HStack {
                                Text(groomer.city)
                                    .foregroundStyle(PetTheme.muted)
                                if groomer.isVerified {
                                    VerifiedBadge()
                                }
                            }
                            RatingPill(rating: groomer.rating, count: groomer.reviewCount)
                        }
                    }

                    Text(groomer.bio)
                        .font(.body)
                        .foregroundStyle(PetTheme.muted)

                    HStack(spacing: 8) {
                        Chip(text: "\(Int(groomer.yearsExperience)) years")
                        Chip(text: "$\(Int(groomer.priceMin))-$\(Int(groomer.priceMax))")
                        Chip(text: "\(Int(groomer.serviceRadius)) mi", color: PetTheme.sky)
                    }
                }
                .taskCard()
                .padding(.horizontal, 18)
                .padding(.top, 12)

                VStack(spacing: 10) {
                    Button {
                        showQuote = true
                    } label: {
                        Label("Request quote", systemImage: "text.bubble.fill")
                    }
                    .buttonStyle(CoralButtonStyle())

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(contactMethods, id: \.self) { method in
                            Button {
                                openContact(method)
                            } label: {
                                Label(method.label, systemImage: icon(for: method))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(QuietButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 18)

                profileSection(title: "Service area") {
                    WrapChips(items: groomer.serviceAreas + groomer.serviceMethods, color: PetTheme.sky)
                }

                profileSection(title: "Specialties") {
                    WrapChips(items: groomer.specialties, color: PetTheme.apricot)
                }

                profileSection(title: "Languages and pet fit") {
                    WrapChips(items: groomer.languages + groomer.sizeAccepted + [groomer.acceptsCats ? "Cats accepted" : "Dogs only"], color: PetTheme.mint)
                }

                SectionHeader(title: "Portfolio")
                ForEach(model.portfolio(for: groomer)) { item in
                    NavigationLink {
                        PortfolioDetailView(item: item)
                    } label: {
                        PortfolioCard(
                            item: item,
                            isSaved: model.isFavorite(targetType: .portfolio, targetID: item.id),
                            onSave: { model.toggleFavorite(targetType: .portfolio, targetID: item.id) }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                }

                SectionHeader(title: "Reviews", actionTitle: "Write") {
                    showReview = true
                }

                let reviews = model.reviews(for: groomer)
                if reviews.isEmpty {
                    EmptyState(title: "No reviews yet", message: "Be the first to write a structured review.", systemImage: "star")
                } else {
                    ForEach(reviews) { review in
                        ReviewRow(review: review)
                            .padding(.horizontal, 18)
                    }
                }

                Button {
                    showReport = true
                } label: {
                    Label("Report profile", systemImage: "flag")
                }
                .buttonStyle(QuietButtonStyle())
                .padding(.horizontal, 18)
            }
            .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .sheet(isPresented: $showQuote) {
            QuoteRequestView(groomer: groomer)
                .environmentObject(model)
        }
        .sheet(isPresented: $showReview) {
            WriteReviewView(groomer: groomer)
                .environmentObject(model)
        }
        .sheet(isPresented: $showReport) {
            ReportContentView(targetType: .groomer, targetID: groomer.id, title: "Report \(groomer.name)")
                .environmentObject(model)
        }
    }

    private var contactMethods: [ContactMethod] {
        var methods: [ContactMethod] = []
        if groomer.phone != nil { methods.append(.phone) }
        if groomer.smsNumber != nil { methods.append(.sms) }
        if groomer.instagramURL != nil { methods.append(.instagram) }
        if groomer.wechatID != nil { methods.append(.wechat) }
        if groomer.websiteURL != nil { methods.append(.website) }
        if groomer.email != nil { methods.append(.email) }
        return methods
    }

    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .taskCard()
        .padding(.horizontal, 18)
    }

    private func icon(for method: ContactMethod) -> String {
        switch method {
        case .phone: "phone.fill"
        case .sms: "message.fill"
        case .instagram: "camera.fill"
        case .wechat: "doc.on.doc.fill"
        case .website: "safari.fill"
        case .email: "envelope.fill"
        case .quoteRequest: "text.bubble.fill"
        }
    }

    private func openContact(_ method: ContactMethod) {
        model.logContact(groomer: groomer, pet: model.pets.first, method: method)
        switch method {
        case .phone:
            if let phone = groomer.phone, let url = URL(string: "tel://\(phone)") {
                openURL(url)
            }
        case .sms:
            if let sms = groomer.smsNumber, let url = URL(string: "sms:\(sms)") {
                openURL(url)
            }
        case .instagram:
            if let instagram = groomer.instagramURL, let url = URL(string: instagram) {
                openURL(url)
            }
        case .wechat:
            UIPasteboard.general.string = groomer.wechatID
        case .website:
            if let website = groomer.websiteURL, let url = URL(string: website) {
                openURL(url)
            }
        case .email:
            if let email = groomer.email, let url = URL(string: "mailto:\(email)") {
                openURL(url)
            }
        case .quoteRequest:
            showQuote = true
        }
    }
}

struct WrapChips: View {
    let items: [String]
    var color: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 7)], alignment: .leading, spacing: 7) {
            ForEach(items, id: \.self) { item in
                Chip(text: item, color: color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct PortfolioDetailView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showReport = false

    let item: PortfolioItem

    private var groomer: Groomer? {
        model.groomers.first { $0.id == item.groomerID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MockPhotoBlock(title: item.styleName, systemImage: item.petSpecies == .cat ? "cat.fill" : "dog.fill", height: 300)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.styleName)
                                .font(.title.weight(.bold))
                                .fontDesign(.rounded)
                            Text("\(item.breed) · \(item.serviceType)")
                                .font(.subheadline)
                                .foregroundStyle(PetTheme.muted)
                        }
                        Spacer()
                        Button {
                            model.toggleFavorite(targetType: .portfolio, targetID: item.id)
                        } label: {
                            Image(systemName: model.isFavorite(targetType: .portfolio, targetID: item.id) ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundStyle(PetTheme.coral)
                                .frame(width: 40, height: 40)
                        }
                    }

                    Text(item.caption)
                        .foregroundStyle(PetTheme.muted)

                    WrapChips(items: [item.petSpecies.rawValue, item.coatCondition, item.serviceType], color: PetTheme.mint)

                    if let groomer {
                        NavigationLink {
                            GroomerProfileView(groomer: groomer)
                        } label: {
                            Label("View \(groomer.name)", systemImage: "person.crop.circle")
                        }
                        .buttonStyle(CoralButtonStyle())
                    }
                }
                .taskCard()
                .padding(.horizontal, 18)

                Button {
                    showReport = true
                } label: {
                    Label("Report portfolio image", systemImage: "flag")
                }
                .buttonStyle(QuietButtonStyle())
                .padding(.horizontal, 18)
            }
            .padding(.bottom, 28)
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .sheet(isPresented: $showReport) {
            ReportContentView(targetType: .portfolio, targetID: item.id, title: "Report portfolio")
                .environmentObject(model)
        }
    }
}

struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(review.overallRating, specifier: "%.1f")", systemImage: "star.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PetTheme.coralDark)
                Spacer()
                if review.wouldRebook == true {
                    Chip(text: "Would rebook", color: PetTheme.mint)
                }
            }
            Text(review.reviewText)
                .font(.subheadline)
                .foregroundStyle(PetTheme.muted)
            WrapChips(items: [review.serviceType, "Communication \(Int(review.communicationRating ?? review.overallRating))/5", "Patience \(Int(review.patienceRating ?? review.overallRating))/5"], color: PetTheme.sky)
        }
        .taskCard()
    }
}

struct QuoteRequestView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let groomer: Groomer
    @State private var selectedPetIndex = 0
    @State private var serviceType = "Full groom"
    @State private var preferredTime = "This week"
    @State private var notes = ""
    @State private var contactPreference = "SMS"

    private var selectedPet: Pet? {
        guard selectedPetIndex > 0, model.pets.indices.contains(selectedPetIndex - 1) else { return nil }
        return model.pets[selectedPetIndex - 1]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Request details") {
                    Picker("Pet", selection: $selectedPetIndex) {
                        Text("No pet selected").tag(0)
                        ForEach(Array(model.pets.enumerated()), id: \.element.id) { index, pet in
                            Text(pet.name).tag(index + 1)
                        }
                    }
                    TextField("Service type", text: $serviceType)
                    TextField("Preferred timing", text: $preferredTime)
                    TextField("Contact preference", text: $contactPreference)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Quote request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        model.submitQuote(
                            groomer: groomer,
                            pet: selectedPet,
                            serviceType: serviceType,
                            preferredTime: preferredTime,
                            notes: notes,
                            contactPreference: contactPreference
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WriteReviewView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let groomer: Groomer
    @State private var selectedPetIndex = 0
    @State private var rating = 5.0
    @State private var serviceType = "Full groom"
    @State private var reviewText = ""
    @State private var wouldRebook = true

    private var selectedPet: Pet? {
        guard selectedPetIndex > 0, model.pets.indices.contains(selectedPetIndex - 1) else { return nil }
        return model.pets[selectedPetIndex - 1]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Review") {
                    Picker("Pet", selection: $selectedPetIndex) {
                        Text("No pet selected").tag(0)
                        ForEach(Array(model.pets.enumerated()), id: \.element.id) { index, pet in
                            Text(pet.name).tag(index + 1)
                        }
                    }
                    Slider(value: $rating, in: 1...5, step: 0.5) {
                        Text("Rating")
                    }
                    Text("\(rating, specifier: "%.1f") stars")
                    TextField("Service type", text: $serviceType)
                    Toggle("Would rebook", isOn: $wouldRebook)
                    TextField("Review text", text: $reviewText, axis: .vertical)
                }
            }
            .navigationTitle("Write review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        model.submitReview(
                            groomer: groomer,
                            pet: selectedPet,
                            rating: rating,
                            serviceType: serviceType,
                            text: reviewText.isEmpty ? "Helpful, clear, and patient service." : reviewText,
                            wouldRebook: wouldRebook
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReportContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let targetType: ReportTargetType
    let targetID: UUID
    let title: String

    @State private var reason: ReportReason = .inaccurateInformation
    @State private var details = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Reason", selection: $reason) {
                        ForEach(ReportReason.allCases) { reason in
                            Text(reason.rawValue).tag(reason)
                        }
                    }
                    TextField("Details", text: $details, axis: .vertical)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        model.submitReport(targetType: targetType, targetID: targetID, reason: reason, details: details)
                        dismiss()
                    }
                }
            }
        }
    }
}
