import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            if model.activeRole == .petOwner {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }

                NavigationStack {
                    SearchView()
                }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

                NavigationStack {
                    PetsView()
                }
                .tabItem { Label("Pets", systemImage: "pawprint.fill") }

                NavigationStack {
                    SavedView()
                }
                .tabItem { Label("Saved", systemImage: "heart.fill") }
            } else {
                NavigationStack {
                    GroomerTodayView()
                }
                .tabItem { Label("Today", systemImage: "chart.line.uptrend.xyaxis") }

                NavigationStack {
                    MyGroomerProfileView()
                }
                .tabItem { Label("Profile", systemImage: "person.text.rectangle.fill") }

                NavigationStack {
                    GroomerInboxView()
                }
                .tabItem { Label("Inbox", systemImage: "tray.fill") }

                NavigationStack {
                    GroomerPortfolioManagerView()
                }
                .tabItem { Label("Portfolio", systemImage: "photo.stack.fill") }
            }

            NavigationStack {
                AccountView()
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle.fill") }
        }
        .tint(PetTheme.coral)
    }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showNewPet = false
    @State private var selectedPetIndex = 0
    @State private var selectedService: GroomingTaskService = .bath
    @State private var selectedDate = Date()
    @State private var selectedTimeWindow: GroomingTaskTimeWindow = .eightAM
    @State private var styleGoal = ""
    @State private var specialNotes = ""
    @State private var styleReferenceSource: GroomingTaskStyleReferenceSource?
    @State private var isEditingTask = true
    @State private var templateSaved = false
    @State private var showStyleReferenceOptions = false
    @State private var showTemplatePicker = false
    @State private var showNoTemplatesAlert = false
    @State private var showTemplateSavedAlert = false

    private var selectedPet: Pet? {
        guard model.pets.indices.contains(selectedPetIndex) else { return model.pets.first }
        return model.pets[selectedPetIndex]
    }

    private var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var validTaskDateRange: ClosedRange<Date> {
        todayStart...Date.distantFuture
    }

    private var groomerResults: [Groomer] {
        if let task = model.currentGroomingTask {
            return model.recommendedGroomers(for: task)
        }
        return Array(model.groomers.prefix(2))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(
                    title: "Find the actual groomer",
                    subtitle: "Compare real portfolios, pet-fit details, price ranges, and direct contact options."
                )

                groomingTaskBuilder

                SectionHeader(title: model.currentGroomingTask == nil ? "Nearby groomers" : "Recommended for this task")
                VStack(spacing: 14) {
                    ForEach(groomerResults) { groomer in
                        NavigationLink {
                            GroomerProfileView(groomer: groomer)
                        } label: {
                            GroomerCard(
                                groomer: groomer,
                                portfolio: model.portfolio(for: groomer),
                                isSaved: model.isFavorite(targetType: .groomer, targetID: groomer.id),
                                onSave: { model.toggleFavorite(targetType: .groomer, targetID: groomer.id) },
                                onContact: { model.logContact(groomer: groomer, pet: model.pets.first, method: .quoteRequest) }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                }

                SectionHeader(title: "Popular portfolio")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(model.portfolioItems) { item in
                            NavigationLink {
                                PortfolioDetailView(item: item)
                            } label: {
                                PortfolioCard(
                                    item: item,
                                    isSaved: model.isFavorite(targetType: .portfolio, targetID: item.id),
                                    onSave: { model.toggleFavorite(targetType: .portfolio, targetID: item.id) }
                                )
                                .frame(width: 250)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .sheet(isPresented: $showNewPet) {
            PetEditorView(mode: .create)
                .environmentObject(model)
        }
        .onChange(of: model.pets.count) { _, _ in
            if selectedPetIndex >= model.pets.count {
                selectedPetIndex = max(0, model.pets.count - 1)
            }
        }
        .onAppear {
            if selectedDate < todayStart {
                selectedDate = todayStart
            }
        }
    }

    @ViewBuilder
    private var groomingTaskBuilder: some View {
        Group {
            if let task = model.currentGroomingTask, let pet = model.pet(for: task), !isEditingTask {
                GroomingTaskCard(
                    task: task,
                    pet: pet,
                    recommendedCount: model.recommendedGroomers(for: task).count,
                    isTemplateSaved: templateSaved,
                    onSaveTemplate: {
                        model.saveCurrentGroomingTaskAsTemplate()
                        templateSaved = true
                        showTemplateSavedAlert = true
                    },
                    onEdit: {
                        populateDraft(from: task)
                        isEditingTask = true
                    },
                    onCancel: {
                        clearTaskDraft()
                        model.cancelGroomingTask()
                        isEditingTask = true
                        templateSaved = false
                    }
                )
                .padding(.horizontal, 18)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "clipboard.badge.plus")
                            .foregroundStyle(PetTheme.coral)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Build today’s grooming task")
                                .font(.headline.weight(.semibold))
                                .fontDesign(.rounded)
                            Text("Create a clear task card before choosing a groomer.")
                                .font(.caption)
                                .foregroundStyle(PetTheme.muted)
                        }
                        Spacer()
                        Button {
                            if model.savedGroomingTaskTemplates.isEmpty {
                                showNoTemplatesAlert = true
                            } else {
                                showTemplatePicker = true
                            }
                        } label: {
                            Label("Templates", systemImage: "bookmark")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .accessibilityLabel("Choose a saved task template")
                    }

                    if model.pets.isEmpty {
                        Text("Create a pet profile first so this task can use your pet list.")
                            .font(.subheadline)
                            .foregroundStyle(PetTheme.muted)
                        Button {
                            showNewPet = true
                        } label: {
                            Label("Create pet profile", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(CoralButtonStyle())
                    } else {
                        taskForm
                    }
                }
                .taskCard()
                .padding(.horizontal, 18)
            }
        }
        .confirmationDialog("Add style reference", isPresented: $showStyleReferenceOptions, titleVisibility: .visible) {
            Button("Take Photo") {
                styleReferenceSource = .camera
            }
            Button("Upload from Photos") {
                styleReferenceSource = .photoLibrary
            }
            if styleReferenceSource != nil {
                Button("Remove Reference", role: .destructive) {
                    styleReferenceSource = nil
                }
            }
        } message: {
            Text("Attach a style you like so the groomer can understand the look.")
        }
        .confirmationDialog("Saved task templates", isPresented: $showTemplatePicker, titleVisibility: .visible) {
            ForEach(model.savedGroomingTaskTemplates) { template in
                Button(templateOptionTitle(for: template)) {
                    applyTemplate(template)
                }
            }
        } message: {
            Text("Choosing a template fills the task details but leaves the date as today.")
        }
        .alert("No saved templates yet", isPresented: $showNoTemplatesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Generate a task card, then tap the bookmark to save it as a reusable template.")
        }
        .alert("Saved as task card template", isPresented: $showTemplateSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can reuse this task setup from Templates next time. The date will reset for each new request.")
        }
    }

    private var taskForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                taskField(title: "Pet") {
                    Picker("Pet", selection: $selectedPetIndex) {
                        ForEach(Array(model.pets.enumerated()), id: \.element.id) { index, pet in
                            Text(pet.name).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

                taskField(title: "Service") {
                    Picker("Service", selection: $selectedService) {
                        ForEach(GroomingTaskService.allCases) { service in
                            Text(service.rawValue).tag(service)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            HStack(spacing: 10) {
                taskField(title: "Date") {
                    DatePicker("Date", selection: $selectedDate, in: validTaskDateRange, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }

                taskField(title: "Time") {
                    Picker("Time", selection: $selectedTimeWindow) {
                        ForEach(GroomingTaskTimeWindow.allCases) { window in
                            Text(window.displayTitle).tag(window)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    TextField("Style goal, e.g. bath only, teddy face, summer cut", text: $styleGoal, axis: .vertical)
                        .lineLimit(1...3)
                    Button {
                        showStyleReferenceOptions = true
                    } label: {
                        Image(systemName: styleReferenceSource == nil ? "plus.circle.fill" : "photo.badge.checkmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(styleReferenceSource == nil ? PetTheme.coral : PetTheme.sage)
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("Add style reference photo")
                }

                if let styleReferenceSource {
                    Label(styleReferenceSource.displayTitle, systemImage: styleReferenceSource.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.sage)
                }
            }
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            TextField("Special notes, e.g. matting, sensitive skin, afraid of dryers", text: $specialNotes, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                generateTaskCard()
            } label: {
                Label(model.currentGroomingTask == nil ? "Generate task card" : "Update task card", systemImage: "wand.and.stars")
            }
            .buttonStyle(CoralButtonStyle())
        }
    }

    private func taskField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func defaultStyleGoal(for service: GroomingTaskService) -> String {
        switch service {
        case .bath: "Clean coat, bath, dry, and brush-out"
        case .fullGroom: "Full groom with tidy, practical finish"
        case .haircut: "Haircut with a style that fits coat condition"
        case .nailTrim: "Nail trim and basic paw cleanup"
        case .dematting: "De-matting assessment and safe coat plan"
        case .catGrooming: "Low-stress cat grooming"
        case .faceTrim: "Face trim and eye area cleanup"
        case .sanitaryTrim: "Sanitary trim and hygiene cleanup"
        }
    }

    private func generateTaskCard() {
        guard let selectedPet else { return }
        let safeDate = selectedDate < todayStart ? todayStart : selectedDate
        selectedDate = safeDate
        let cleanedStyleGoal = cleaned(styleGoal)

        model.saveGroomingTask(
            pet: selectedPet,
            service: selectedService,
            targetDate: safeDate,
            timeWindow: selectedTimeWindow,
            styleGoal: cleanedStyleGoal.isEmpty ? defaultStyleGoal(for: selectedService) : cleanedStyleGoal,
            specialNotes: cleaned(specialNotes),
            styleReferenceSource: styleReferenceSource
        )
        isEditingTask = false
        templateSaved = false
    }

    private func populateDraft(from task: GroomingTask) {
        if let petIndex = model.pets.firstIndex(where: { $0.id == task.petID }) {
            selectedPetIndex = petIndex
        }
        selectedService = task.service
        selectedDate = task.targetDate < todayStart ? todayStart : task.targetDate
        selectedTimeWindow = task.timeWindow
        styleGoal = task.styleGoal
        specialNotes = task.specialNotes
        styleReferenceSource = task.styleReferenceSource
    }

    private func clearTaskDraft() {
        selectedPetIndex = 0
        selectedService = .bath
        selectedDate = todayStart
        selectedTimeWindow = .eightAM
        styleGoal = ""
        specialNotes = ""
        styleReferenceSource = nil
    }

    private func applyTemplate(_ template: GroomingTaskTemplate) {
        if let petIndex = model.pets.firstIndex(where: { $0.id == template.petID }) {
            selectedPetIndex = petIndex
        }
        selectedService = template.service
        selectedDate = todayStart
        selectedTimeWindow = template.timeWindow
        styleGoal = template.styleGoal
        specialNotes = template.specialNotes
        styleReferenceSource = template.styleReferenceSource
        model.cancelGroomingTask()
        isEditingTask = true
        templateSaved = false
    }

    private func templateOptionTitle(for template: GroomingTaskTemplate) -> String {
        let petName = model.pets.first { $0.id == template.petID }?.name ?? "Pet"
        return "\(petName) · \(template.service.rawValue) · \(template.timeWindow.displayTitle)"
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct GroomingTaskCard: View {
    let task: GroomingTask
    let pet: Pet
    let recommendedCount: Int
    let isTemplateSaved: Bool
    let onSaveTemplate: () -> Void
    let onEdit: () -> Void
    let onCancel: () -> Void

    private var dateText: String {
        task.targetDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var referenceTitle: String {
        task.referenceImageSlot.displayTitle
    }

    private var referenceIcon: String {
        task.styleReferenceSource?.iconName ?? "photo.badge.plus"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Grooming task")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PetTheme.coralDark)
                    Text(task.service.rawValue)
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(2)
                    Text("For \(pet.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }
                Spacer()
                Button(action: onSaveTemplate) {
                    Image(systemName: isTemplateSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isTemplateSaved ? PetTheme.coral : Color.gray.opacity(0.75))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isTemplateSaved ? "Task template saved" : "Save task template")
            }

            HStack(spacing: 8) {
                Chip(text: "\(recommendedCount) groomer matches", color: PetTheme.mint)
                Chip(text: task.referenceImageSlot.hasImage ? "Reference ready" : "Reference slot ready", color: PetTheme.sky)
            }

            Divider()
                .overlay(PetTheme.line.opacity(0.45))

            HStack(alignment: .top, spacing: 16) {
                GroomingTaskFact(iconName: "calendar", title: "Date", value: dateText)
                GroomingTaskFact(iconName: "clock", title: "Time", value: task.timeWindow.displayTitle)
            }

            VStack(alignment: .leading, spacing: 7) {
                Label("Style goal", systemImage: "scissors")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.coralDark)
                Text(task.styleGoal)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 7) {
                Label(referenceTitle, systemImage: referenceIcon)
                Label("\(task.petPhotoSnapshots.count) pet profile photos captured", systemImage: "photo.on.rectangle")
                if !task.specialNotes.isEmpty {
                    Label(task.specialNotes, systemImage: "exclamationmark.bubble")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(PetTheme.muted)

            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(QuietButtonStyle())

                Button(role: .destructive, action: onCancel) {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(QuietButtonStyle())

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PetTheme.porcelain)
                .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.8), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(PetTheme.coral)
                .frame(width: 4)
                .padding(.vertical, 14)
        }
    }
}

struct GroomingTaskFact: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.sage)
                .frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SearchView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var city = "All"
    @State private var verifiedOnly = false
    @State private var catsOnly = false

    private var cities: [String] {
        ["All"] + Array(Set(model.groomers.map(\.city))).sorted()
    }

    private var results: [Groomer] {
        model.filteredGroomers(query: query, city: city, verifiedOnly: verifiedOnly, acceptsCatsOnly: catsOnly)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Search groomers", subtitle: "Filter by location, pet type, verification, specialties, and portfolio fit.")

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(PetTheme.muted)
                        TextField("Breed, style, city, specialty", text: $query)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Picker("City", selection: $city) {
                        ForEach(cities, id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Toggle("Verified", isOn: $verifiedOnly)
                        Toggle("Cats", isOn: $catsOnly)
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(PetTheme.sage)
                }
                .taskCard()
                .padding(.horizontal, 18)

                if results.isEmpty {
                    EmptyState(title: "No groomers match", message: "Adjust filters or search a broader service area.", systemImage: "slider.horizontal.3")
                } else {
                    VStack(spacing: 14) {
                        ForEach(results) { groomer in
                            NavigationLink {
                                GroomerProfileView(groomer: groomer)
                            } label: {
                                GroomerCard(
                                    groomer: groomer,
                                    portfolio: model.portfolio(for: groomer),
                                    isSaved: model.isFavorite(targetType: .groomer, targetID: groomer.id),
                                    onSave: { model.toggleFavorite(targetType: .groomer, targetID: groomer.id) },
                                    onContact: { model.logContact(groomer: groomer, pet: model.pets.first, method: .quoteRequest) }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 18)
                        }
                    }
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
    }
}

struct SavedView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Saved", subtitle: "Keep groomers and portfolio references for your next quote request.")

                if model.savedGroomers.isEmpty && model.savedPortfolio.isEmpty {
                    EmptyState(title: "Nothing saved yet", message: "Save groomers or portfolio looks as you browse.", systemImage: "heart")
                }

                if !model.savedGroomers.isEmpty {
                    SectionHeader(title: "Groomers")
                    ForEach(model.savedGroomers) { groomer in
                        NavigationLink {
                            GroomerProfileView(groomer: groomer)
                        } label: {
                            GroomerCard(
                                groomer: groomer,
                                portfolio: model.portfolio(for: groomer),
                                isSaved: true,
                                onSave: { model.toggleFavorite(targetType: .groomer, targetID: groomer.id) },
                                onContact: { model.logContact(groomer: groomer, pet: model.pets.first, method: .quoteRequest) }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                }

                if !model.savedPortfolio.isEmpty {
                    SectionHeader(title: "Portfolio references")
                    ForEach(model.savedPortfolio) { item in
                        NavigationLink {
                            PortfolioDetailView(item: item)
                        } label: {
                            PortfolioCard(
                                item: item,
                                isSaved: true,
                                onSave: { model.toggleFavorite(targetType: .portfolio, targetID: item.id) }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
    }
}

struct AccountView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Account", subtitle: "Demo profile, settings, and MVP feature flags.")

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        MockPhotoBlock(title: "TC", systemImage: "person.fill", height: 74)
                            .frame(width: 74)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.currentUser.displayName)
                                .font(.title3.weight(.bold))
                                .fontDesign(.rounded)
                            Text("\(model.currentUser.city), \(model.currentUser.zipCode)")
                                .font(.subheadline)
                                .foregroundStyle(PetTheme.muted)
                            Text("Apple Sign In / Magic Link placeholder")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PetTheme.sage)
                        }
                    }
                    Divider()
                    Picker("Role", selection: $model.activeRole) {
                        ForEach(AppRole.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(model.activeRole == .petOwner ? "You are browsing as a pet owner. Switch to Groomer to manage the claimed Ava Park profile in this same app." : "You are using the groomer workspace for Ava Park. Switch back anytime to browse as a pet owner.")
                        .font(.caption)
                        .foregroundStyle(PetTheme.muted)

                    Divider()
                    Label("No platform payment, booking calendar, or real-time chat in MVP", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }
                .taskCard()
                .padding(.horizontal, 18)

                SectionHeader(title: "AI-ready flags")
                VStack(spacing: 10) {
                    ForEach(model.featureFlags) { flag in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: flag.isEnabled ? "togglepower" : "power")
                                .foregroundStyle(flag.isEnabled ? PetTheme.sage : PetTheme.muted)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(flag.key)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(PetTheme.ink)
                                Text(flag.description)
                                    .font(.caption)
                                    .foregroundStyle(PetTheme.muted)
                            }
                            Spacer()
                            Text(flag.isEnabled ? "ON" : "OFF")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(flag.isEnabled ? PetTheme.sage : PetTheme.muted)
                        }
                        .padding(12)
                        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.bottom, 28)
        }
        .appBackground()
    }
}
