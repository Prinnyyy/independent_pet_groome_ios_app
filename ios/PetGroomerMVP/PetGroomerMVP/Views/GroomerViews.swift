import SwiftUI
import UIKit

struct GroomerProfileView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var showReview = false
    @State private var showReport = false

    let groomer: Groomer

    var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                profileHero

                taskCardActionPanel

                profileSection(title: "Service fit", icon: "checklist.checked") {
                    WrapChips(
                        items: groomer.serviceMethods + groomer.sizeAccepted + [groomer.acceptsCats ? "Cats accepted" : "Dogs only"],
                        color: PetTheme.mint
                    )
                }

                profileSection(title: "Specialties", icon: "sparkles") {
                    WrapChips(items: groomer.specialties, color: PetTheme.apricot)
                }

                profileSection(title: "Area and language", icon: "mappin.and.ellipse") {
                    WrapChips(items: groomer.serviceAreas + groomer.languages, color: PetTheme.sky)
                }

                portfolioSection

                if !contactMethods.isEmpty {
                    profileSection(title: "Profile links", icon: "link") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                            ForEach(contactMethods, id: \.self) { method in
                                Button {
                                    openContact(method)
                                } label: {
                                    Label(method.label, systemImage: icon(for: method))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(QuietButtonStyle())
                            }
                        }
                    }
                }

                reviewsSection

                Button {
                    showReport = true
                } label: {
                    Label("Report profile", systemImage: "flag")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle())
                .padding(.horizontal, 18)
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .sheet(isPresented: $showReview) {
            WriteReviewView(groomer: groomer)
                .environmentObject(model)
        }
        .sheet(isPresented: $showReport) {
            ReportContentView(targetType: .groomer, targetID: groomer.id, title: "Report \(groomer.name)")
                .environmentObject(model)
        }
    }

    private var profileHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                MockPhotoBlock(title: initials, systemImage: "scissors", height: 92)
                    .frame(width: 92)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(groomer.name)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(PetTheme.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            HStack(spacing: 7) {
                                Label(groomer.city, systemImage: "mappin.and.ellipse")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PetTheme.muted)
                                if groomer.isVerified {
                                    VerifiedBadge()
                                }
                            }
                        }

                        Spacer(minLength: 6)

                        Button {
                            model.toggleFavorite(targetType: .groomer, targetID: groomer.id)
                        } label: {
                            Image(systemName: model.isFavorite(targetType: .groomer, targetID: groomer.id) ? "heart.fill" : "heart")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(model.isFavorite(targetType: .groomer, targetID: groomer.id) ? PetTheme.coral : PetTheme.muted)
                                .frame(width: 38, height: 38)
                                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(model.isFavorite(targetType: .groomer, targetID: groomer.id) ? "Remove saved groomer" : "Save groomer")
                    }

                    RatingPill(rating: groomer.rating, count: groomer.reviewCount)
                }
            }

            Text(groomer.bio)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PetTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    profileMetric(title: "Experience", value: "\(Int(groomer.yearsExperience)) years", icon: "rosette")
                    profileMetric(title: "Price", value: "$\(Int(groomer.priceMin))-$\(Int(groomer.priceMax))", icon: "tag.fill")
                }
                GridRow {
                    profileMetric(title: "Range", value: "\(Int(groomer.serviceRadius)) mi", icon: "scope")
                    profileMetric(title: "Portfolio", value: "\(model.portfolio(for: groomer).count) looks", icon: "photo.stack.fill")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.24)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.055), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.78), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    private var taskCardActionPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shippingbox.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PetTheme.coral)
                    .frame(width: 34, height: 34)
                    .background(PetTheme.apricot.opacity(0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Task card exchange")
                        .font(.headline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                    Text(taskActionHint)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if let status = currentTaskSubmission?.status {
                    Chip(text: status.label, color: statusColor(status))
                }
            }

            taskCardActionButton
        }
        .padding(12)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.55), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var taskCardActionButton: some View {
        if taskActionIsQuiet {
            Button {
                sendOrRevokeCurrentTask()
            } label: {
                Label(taskActionTitle, systemImage: taskActionIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuietButtonStyle())
            .disabled(taskActionIsDisabled)
            .opacity(taskActionIsDisabled ? 0.56 : 1)
        } else {
            Button {
                sendOrRevokeCurrentTask()
            } label: {
                Label(taskActionTitle, systemImage: taskActionIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CoralButtonStyle())
            .disabled(taskActionIsDisabled)
            .opacity(taskActionIsDisabled ? 0.56 : 1)
        }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Portfolio", systemImage: "photo.stack.fill")
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                Spacer()
                Text("\(model.portfolio(for: groomer).count) looks")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(model.portfolio(for: groomer)) { item in
                    NavigationLink {
                        PortfolioDetailView(item: item)
                    } label: {
                        MockPhotoBlock(
                            title: item.styleName,
                            systemImage: item.petSpecies == .cat ? "cat.fill" : "dog.fill",
                            height: 132
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(PetTheme.porcelain, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.72), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Reviews", systemImage: "star.fill")
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                Spacer()
                Button("Write") {
                    showReview = true
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.coralDark)
            }

            let reviews = model.reviews(for: groomer)
            if reviews.isEmpty {
                EmptyState(title: "No reviews yet", message: "Reviews will appear after completed task cards.", systemImage: "star")
            } else {
                ForEach(reviews) { review in
                    ReviewRow(review: review)
                }
            }
        }
        .padding(14)
        .background(PetTheme.porcelain, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.72), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    private var contactMethods: [ContactMethod] {
        var methods: [ContactMethod] = []
        if groomer.phone != nil { methods.append(.phone) }
        if groomer.instagramURL != nil { methods.append(.instagram) }
        if groomer.wechatID != nil { methods.append(.wechat) }
        if groomer.websiteURL != nil { methods.append(.website) }
        if groomer.email != nil { methods.append(.email) }
        return methods
    }

    private var currentTaskSubmission: GroomingTaskSubmission? {
        guard let task = model.currentGroomingTask else { return nil }
        return model.taskSubmission(for: task, groomer: groomer)
    }

    private var taskActionTitle: String {
        guard model.currentGroomingTask != nil else { return "Create Task First" }
        switch currentTaskSubmission?.status {
        case .sent:
            return "Revoke Card"
        case .accepted:
            return "Accepted"
        case .completed:
            return "Completed"
        default:
            return "Send Card"
        }
    }

    private var taskActionIcon: String {
        guard model.currentGroomingTask != nil else { return "doc.badge.plus" }
        switch currentTaskSubmission?.status {
        case .sent:
            return "arrow.uturn.backward.circle.fill"
        case .accepted:
            return "checkmark.seal.fill"
        case .completed:
            return "checkmark.circle.fill"
        default:
            return "paperplane.fill"
        }
    }

    private var taskActionHint: String {
        guard let task = model.currentGroomingTask else {
            return "Create a task card on Home before sending a request to this groomer."
        }
        if let submission = currentTaskSubmission {
            switch submission.status {
            case .sent:
                return "Your \(task.service.rawValue.lowercased()) card is waiting for a reply."
            case .accepted:
                return "This groomer accepted your current task card."
            case .declined:
                return "This groomer declined the last request. You can send an updated card."
            case .completed:
                return "This task card was completed."
            case .cancelled:
                return "The previous request was canceled. You can send again."
            }
        }
        return "Send your current \(task.service.rawValue.lowercased()) card to start the exchange."
    }

    private var taskActionIsDisabled: Bool {
        guard model.currentGroomingTask != nil else { return true }
        return currentTaskSubmission?.status == .accepted || currentTaskSubmission?.status == .completed
    }

    private var taskActionIsQuiet: Bool {
        currentTaskSubmission?.status == .sent
    }

    private var initials: String {
        groomer.name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }

    private func sendOrRevokeCurrentTask() {
        guard model.currentGroomingTask != nil else { return }
        if let submission = currentTaskSubmission, submission.status == .sent {
            model.revokeTaskSubmission(id: submission.id)
        } else {
            model.sendCurrentTask(to: groomer)
        }
    }

    private func profileSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(PetTheme.porcelain, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.72), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    private func profileMetric(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.coral)
                .frame(width: 22, height: 22)
                .background(PetTheme.apricot.opacity(0.32), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.caption.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
        )
    }

    private func statusColor(_ status: GroomingTaskSubmissionStatus) -> Color {
        switch status {
        case .sent:
            return PetTheme.apricot
        case .accepted, .completed:
            return PetTheme.mint
        case .declined, .cancelled:
            return Color.gray.opacity(0.24)
        }
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
            break
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
            break
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
