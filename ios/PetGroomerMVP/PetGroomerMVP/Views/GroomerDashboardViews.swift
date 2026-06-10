import SwiftUI

struct GroomerTodayView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let groomer = model.managedGroomer {
                    ScreenTitle(
                        title: "Today",
                        subtitle: "Manage your independent groomer profile, portfolio, inquiries, and reviews in the same app customers use."
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            MockPhotoBlock(title: groomer.name, systemImage: "scissors", height: 82)
                                .frame(width: 82)
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(groomer.name)
                                        .font(.title2.weight(.bold))
                                        .fontDesign(.rounded)
                                    if groomer.isVerified {
                                        VerifiedBadge()
                                    }
                                }
                                Text("\(groomer.city) · \(groomer.serviceMethods.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundStyle(PetTheme.muted)
                                RatingPill(rating: groomer.rating, count: groomer.reviewCount)
                            }
                            Spacer()
                        }

                        Text("Your public profile is visible to pet owners. Keep specialties, pricing, service area, and portfolio fresh to improve contact conversion.")
                            .font(.subheadline)
                            .foregroundStyle(PetTheme.muted)
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        GroomerMetricCard(title: "Quote requests", value: "\(model.quoteRequests(for: groomer).count)", detail: "mock inbox")
                        GroomerMetricCard(title: "Portfolio", value: "\(model.portfolio(for: groomer).count)", detail: "published looks")
                        GroomerMetricCard(title: "Reviews", value: "\(model.reviews(for: groomer).count)", detail: String(format: "%.1f average", groomer.rating))
                        GroomerMetricCard(title: "Contacts", value: "\(model.contactEvents(for: groomer).count)", detail: "this session")
                    }
                    .padding(.horizontal, 18)

                    if let task = model.currentGroomingTask {
                        SectionHeader(title: "Task card lookup")
                        GroomerTaskDataCard(task: task)
                            .padding(.horizontal, 18)
                    }

                    SectionHeader(title: "Newest inquiries")
                    let requests = model.quoteRequests(for: groomer)
                    if requests.isEmpty {
                        EmptyState(title: "No inquiries yet", message: "Pet owners can request quotes from your public profile.", systemImage: "tray")
                    } else {
                        ForEach(requests.prefix(2)) { request in
                            QuoteRequestCard(request: request)
                                .padding(.horizontal, 18)
                        }
                    }

                    SectionHeader(title: "Public profile preview")
                    NavigationLink {
                        GroomerProfileView(groomer: groomer)
                    } label: {
                        GroomerCard(
                            groomer: groomer,
                            portfolio: model.portfolio(for: groomer),
                            isSaved: false,
                            onSave: {},
                            onContact: {}
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                } else {
                    EmptyState(title: "No groomer profile", message: "This demo account has no claimed groomer profile.", systemImage: "person.text.rectangle")
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
    }
}

struct MyGroomerProfileView: View {
    @EnvironmentObject private var model: AppModel
    @State private var draft: Groomer?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "My profile", subtitle: "Edit the profile pet owners see in search and on your public page.")

                if let draft {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile basics")
                            .font(.headline.weight(.semibold))
                            .fontDesign(.rounded)

                        TextField("Name", text: binding(\.name))
                            .textFieldStyle(.roundedBorder)
                        TextField("City", text: binding(\.city))
                            .textFieldStyle(.roundedBorder)
                        TextField("ZIP code", text: binding(\.zipCode))
                            .textFieldStyle(.roundedBorder)
                        TextField("Bio", text: binding(\.bio), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)

                        HStack(spacing: 10) {
                            numberField("Min price", value: bindingDouble(\.priceMin))
                            numberField("Max price", value: bindingDouble(\.priceMax))
                        }

                        Toggle("Published", isOn: Binding(
                            get: { self.draft?.status == .published },
                            set: { self.draft?.status = $0 ? .published : .draft }
                        ))
                        .tint(PetTheme.sage)

                        Toggle("Accept cats", isOn: bindingBool(\.acceptsCats))
                            .tint(PetTheme.sage)

                        Button {
                            if let currentDraft = self.draft {
                                model.updateGroomer(currentDraft)
                            }
                        } label: {
                            Label("Save profile changes", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(CoralButtonStyle())
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    profileArrayEditor(title: "Service areas", values: draft.serviceAreas, keyPath: \.serviceAreas)
                    profileArrayEditor(title: "Languages", values: draft.languages, keyPath: \.languages)
                    profileArrayEditor(title: "Specialties", values: draft.specialties, keyPath: \.specialties)
                    profileArrayEditor(title: "Service methods", values: draft.serviceMethods, keyPath: \.serviceMethods)
                } else {
                    EmptyState(title: "No claimed profile", message: "Switch to a demo groomer account or claim a profile after Supabase auth is connected.", systemImage: "person.badge.plus")
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .onAppear {
            draft = model.managedGroomer
        }
        .onChange(of: model.managedGroomer) { _, groomer in
            draft = groomer
        }
    }

    private func binding(_ keyPath: WritableKeyPath<Groomer, String>) -> Binding<String> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    private func bindingDouble(_ keyPath: WritableKeyPath<Groomer, Double>) -> Binding<String> {
        Binding(
            get: { draft.map { String(Int($0[keyPath: keyPath])) } ?? "" },
            set: { draft?[keyPath: keyPath] = Double($0) ?? 0 }
        )
    }

    private func bindingBool(_ keyPath: WritableKeyPath<Groomer, Bool>) -> Binding<Bool> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? false },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    private func numberField(_ title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PetTheme.muted)
            TextField(title, text: value)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func profileArrayEditor(title: String, values: [String], keyPath: WritableKeyPath<Groomer, [String]>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
            WrapChips(items: values, color: PetTheme.apricot)
            TextField(title, text: Binding(
                get: { draft?[keyPath: keyPath].joined(separator: ", ") ?? "" },
                set: { draft?[keyPath: keyPath] = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
        }
        .taskCard()
        .padding(.horizontal, 18)
    }
}

struct GroomerInboxView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Inquiry inbox", subtitle: "Task cards and quote requests from pet owners appear here before a full booking calendar exists.")

                if let groomer = model.managedGroomer {
                    let requests = model.quoteRequests(for: groomer)
                    let taskSubmissions = model.taskSubmissions(for: groomer)
                    if requests.isEmpty && taskSubmissions.isEmpty {
                        EmptyState(title: "No inquiries yet", message: "Pet owners can send task cards or request quotes from your profile.", systemImage: "tray")
                    }

                    if !taskSubmissions.isEmpty {
                        SectionHeader(title: "Task cards")
                        ForEach(taskSubmissions) { submission in
                            if submission.status == .declined {
                                GroomerTaskSubmissionCard(submission: submission)
                                    .padding(.horizontal, 18)
                            } else {
                                NavigationLink {
                                    GroomingTaskSubmissionDetailView(submissionID: submission.id)
                                } label: {
                                    GroomerTaskSubmissionCard(submission: submission)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 18)
                            }
                        }
                    }

                    if !requests.isEmpty {
                        SectionHeader(title: "Quote forms")
                        ForEach(requests) { request in
                            VStack(alignment: .leading, spacing: 12) {
                                QuoteRequestCard(request: request)
                                HStack(spacing: 10) {
                                    Button {
                                        model.updateQuoteStatus(request, status: .viewed)
                                    } label: {
                                        Label("Mark viewed", systemImage: "eye.fill")
                                    }
                                    .buttonStyle(QuietButtonStyle())

                                    Button {
                                        model.updateQuoteStatus(request, status: .closed)
                                    } label: {
                                        Label("Close", systemImage: "checkmark.circle.fill")
                                    }
                                    .buttonStyle(QuietButtonStyle())
                                }
                            }
                            .taskCard()
                            .padding(.horizontal, 18)
                        }
                    }
                } else {
                    EmptyState(title: "No groomer profile", message: "No inbox is available for this demo user.", systemImage: "tray")
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
    }
}

struct GroomerTaskSubmissionCard: View {
    let submission: GroomingTaskSubmission

    private var task: GroomingTask {
        submission.taskSnapshot
    }

    private var statusColor: Color {
        switch submission.status {
        case .sent: PetTheme.apricot
        case .accepted: PetTheme.coral
        case .declined: Color.gray.opacity(0.34)
        }
    }

    private var textColor: Color {
        submission.status == .declined ? PetTheme.muted : PetTheme.ink
    }

    private var dateText: String {
        task.targetDate.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.service.rawValue)
                        .font(.title3.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(textColor)
                    Text("\(task.petSnapshot.name) · \(dateText) · \(task.timeWindow.displayTitle)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }
                Spacer()
                Chip(text: submission.status.label, color: submission.status == .accepted ? PetTheme.mint : statusColor)
            }

            Text(task.styleGoal)
                .font(.subheadline)
                .foregroundStyle(PetTheme.muted)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label(task.referenceImageSlot.hasImage ? "Reference attached" : "No reference yet", systemImage: task.styleReferenceSource?.iconName ?? "photo")
                Label("Owner score \(task.ownerHiddenScore.displayValue)", systemImage: "lock.shield")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(submission.status == .declined ? PetTheme.muted : PetTheme.sage)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(submission.status == .declined ? Color.gray.opacity(0.14) : PetTheme.porcelain)
                .shadow(color: .black.opacity(submission.status == .accepted ? 0.11 : 0.05), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(statusColor.opacity(submission.status == .accepted ? 0.95 : 0.55), lineWidth: submission.status == .accepted ? 2 : 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 12)
        }
        .opacity(submission.status == .declined ? 0.72 : 1)
    }
}

struct GroomingTaskSubmissionDetailView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showChat = false

    let submissionID: UUID

    private var submission: GroomingTaskSubmission? {
        model.taskSubmission(id: submissionID)
    }

    var body: some View {
        ScrollView {
            if let submission {
                let task = submission.taskSnapshot
                VStack(spacing: 16) {
                    ScreenTitle(
                        title: "Task card",
                        subtitle: "Review the task details, message the owner, then accept or decline when the scope is clear."
                    )

                    VStack(alignment: .leading, spacing: 13) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.sequenceCode)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(PetTheme.coralDark)
                                Text(task.service.rawValue)
                                    .font(.title2.weight(.bold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(PetTheme.ink)
                            }
                            Spacer()
                            Chip(text: submission.status.label, color: statusChipColor(submission.status))
                        }

                        detailRow("Pet", value: petDetail(task.petSnapshot), icon: "pawprint.fill")
                        detailRow("Appointment", value: "\(task.targetDate.formatted(date: .abbreviated, time: .omitted)) · \(task.timeWindow.displayTitle)", icon: "calendar")
                        detailRow("Style goal", value: task.styleGoal, icon: "scissors")
                        if !task.specialNotes.isEmpty {
                            detailRow("Notes", value: task.specialNotes, icon: "exclamationmark.bubble")
                        }
                        detailRow("Reference", value: task.referenceImageSlot.displayTitle, icon: task.styleReferenceSource?.iconName ?? "photo")
                        detailRow("Owner score", value: "\(task.ownerHiddenScore.displayValue) · \(task.ownerHiddenScore.source)", icon: "lock.shield")
                        detailRow("Pet profile", value: "\(task.petPhotoSnapshots.count) photos captured with full profile snapshot", icon: "doc.text.magnifyingglass")
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    HStack(spacing: 10) {
                        Button {
                            model.updateTaskSubmissionStatus(id: submission.id, status: .accepted)
                        } label: {
                            Label("Accept Task", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(CoralButtonStyle())
                        .disabled(submission.status != .sent)
                        .opacity(submission.status == .sent ? 1 : 0.55)

                        Button(role: .destructive) {
                            model.updateTaskSubmissionStatus(id: submission.id, status: .declined)
                        } label: {
                            Label("Decline Task", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .disabled(submission.status != .sent)
                        .opacity(submission.status == .sent ? 1 : 0.55)
                    }
                    .padding(.horizontal, 18)

                    Button {
                        showChat = true
                    } label: {
                        Label("Message Owner", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .buttonStyle(QuietButtonStyle())
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 28)
                .sheet(isPresented: $showChat) {
                    TaskChatView(submissionID: submission.id)
                        .environmentObject(model)
                }
            } else {
                EmptyState(title: "Task not found", message: "This task card is no longer available.", systemImage: "tray")
            }
        }
        .appBackground()
        .navigationTitle("Task details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(PetTheme.sage)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func petDetail(_ pet: Pet) -> String {
        [
            pet.name,
            pet.breed,
            pet.coatType,
            pet.coatCondition,
            pet.weight.map { "\(Int($0)) lb" },
            pet.temperament.joined(separator: ", ")
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    private func statusChipColor(_ status: GroomingTaskSubmissionStatus) -> Color {
        switch status {
        case .sent: PetTheme.apricot
        case .accepted: PetTheme.mint
        case .declined: Color.gray.opacity(0.34)
        }
    }
}

struct TaskChatView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var senderRole: AppRole = .groomer

    let submissionID: UUID

    private var messages: [TaskChatMessage] {
        model.messages(for: submissionID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Sender", selection: $senderRole) {
                    Text("Groomer").tag(AppRole.groomer)
                    Text("Customer").tag(AppRole.petOwner)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 10) {
                        if messages.isEmpty {
                            EmptyState(title: "No messages yet", message: "Use this chat to align scope, timing, price, and pet handling details.", systemImage: "bubble.left.and.bubble.right")
                                .padding(.horizontal, 0)
                        } else {
                            ForEach(messages) { message in
                                chatBubble(message)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }

                HStack(spacing: 8) {
                    TextField("Write a message", text: $draft, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(11)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button {
                        model.sendTaskMessage(submissionID: submissionID, senderRole: senderRole, body: draft)
                        draft = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(PetTheme.coral, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
            .appBackground()
            .navigationTitle("Task Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func chatBubble(_ message: TaskChatMessage) -> some View {
        HStack {
            if message.senderRole == .groomer {
                Spacer(minLength: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(message.senderRole == .groomer ? .white.opacity(0.82) : PetTheme.muted)
                Text(message.body)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(message.senderRole == .groomer ? .white : PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(message.senderRole == .groomer ? PetTheme.coral : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(message.senderRole == .groomer ? Color.clear : PetTheme.line.opacity(0.65), lineWidth: 1)
            )

            if message.senderRole == .petOwner {
                Spacer(minLength: 44)
            }
        }
    }
}

struct GroomerPortfolioManagerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showAddPortfolio = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "My portfolio", subtitle: "Add and maintain grooming looks that help customers decide whether your style fits their pet.")

                if let groomer = model.managedGroomer {
                    Button {
                        showAddPortfolio = true
                    } label: {
                        Label("Add portfolio item", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(CoralButtonStyle())
                    .padding(.horizontal, 18)

                    ForEach(model.portfolio(for: groomer)) { item in
                        PortfolioCard(
                            item: item,
                            isSaved: false,
                            onSave: {}
                        )
                        .padding(.horizontal, 18)
                    }
                } else {
                    EmptyState(title: "No groomer profile", message: "Claim or create a groomer profile before adding portfolio work.", systemImage: "photo.stack")
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .sheet(isPresented: $showAddPortfolio) {
            if let groomer = model.managedGroomer {
                AddPortfolioItemView(groomer: groomer)
                    .environmentObject(model)
            }
        }
    }
}

struct AddPortfolioItemView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let groomer: Groomer
    @State private var breed = "Mini Goldendoodle"
    @State private var serviceType = "Full groom"
    @State private var styleName = "Teddy cut"
    @State private var caption = "Fresh portfolio item added from the groomer app demo."

    var body: some View {
        NavigationStack {
            Form {
                Section("Portfolio details") {
                    TextField("Breed", text: $breed)
                    TextField("Service type", text: $serviceType)
                    TextField("Style name", text: $styleName)
                    TextField("Caption", text: $caption, axis: .vertical)
                }
                Section("Photo") {
                    Label("Photo picker and Supabase upload are prepared for the next integration step. This demo creates a mock portfolio image.", systemImage: "photo")
                }
            }
            .navigationTitle("Add work")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        model.addPortfolioItem(for: groomer, breed: breed, serviceType: serviceType, styleName: styleName, caption: caption)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GroomerMetricCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            Text(value)
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
            Text(detail)
                .font(.caption)
                .foregroundStyle(PetTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .taskCard()
    }
}

struct GroomerTaskDataCard: View {
    let task: GroomingTask

    private var dateText: String {
        task.targetDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var petDetails: String {
        let pet = task.petSnapshot
        return [
            pet.name,
            pet.breed,
            pet.coatType,
            pet.coatCondition,
            pet.weight.map { "\(Int($0)) lb" }
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.sequenceCode)
                        .font(.title3.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                    Text("Generated task data container")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }
                Spacer()
                Chip(text: "Owner score \(task.ownerHiddenScore.displayValue)", color: PetTheme.mint)
            }

            Label("\(task.service.rawValue) · \(dateText) · \(task.timeWindow.displayTitle)", systemImage: "calendar")
            Label(petDetails, systemImage: "pawprint.fill")
            Label(task.styleGoal, systemImage: "scissors")
            Label(task.referenceImageSlot.displayTitle, systemImage: task.styleReferenceSource?.iconName ?? "photo.badge.plus")
            Label("Pet snapshot includes \(task.petPhotoSnapshots.count) profile photos and full profile fields.", systemImage: "doc.text.magnifyingglass")
            Label("Hidden score source: \(task.ownerHiddenScore.source)", systemImage: "lock.shield")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(PetTheme.muted)
        .taskCard()
    }
}

struct QuoteRequestCard: View {
    @EnvironmentObject private var model: AppModel
    let request: QuoteRequest

    private var petName: String {
        guard let petID = request.petID, let pet = model.pets.first(where: { $0.id == petID }) else {
            return "No pet selected"
        }
        return "\(pet.name) · \(pet.breed)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(request.serviceType)
                    .font(.headline.weight(.semibold))
                    .fontDesign(.rounded)
                Spacer()
                Chip(text: request.status.rawValue.capitalized, color: request.status == .submitted ? PetTheme.apricot : PetTheme.mint)
            }
            Label(petName, systemImage: "pawprint.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PetTheme.ink)
            Label(request.preferredTime, systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PetTheme.sage)
            Text(request.notes)
                .font(.subheadline)
                .foregroundStyle(PetTheme.muted)
            Text("Preferred contact: \(request.contactPreference)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.coralDark)
        }
    }
}
