import MapKit
import PhotosUI
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
                    OrdersView()
                }
                .tabItem { Label("Orders", systemImage: "doc.text.fill") }
            } else {
                NavigationStack {
                    GroomerTodayView()
                }
                .tabItem { Label("Today", systemImage: "chart.line.uptrend.xyaxis") }

                NavigationStack {
                    GroomerScheduleView()
                }
                .tabItem { Label("Schedule", systemImage: "calendar") }

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
    @State private var selectedSearchRadiusMiles = 10
    @State private var selectedAddressSource: GroomingTaskAddressSource = .currentLocation
    @State private var manualTaskAddress: ProfileAddress = .empty
    @State private var styleGoal = ""
    @State private var specialNotes = ""
    @State private var styleReferenceSource: GroomingTaskStyleReferenceSource?
    @State private var selectedStyleReferencePhoto: PhotosPickerItem?
    @State private var showStyleReferencePhotoPicker = false
    @State private var isEditingTask = true
    @State private var templateSaved = false
    @State private var showStyleReferenceOptions = false
    @State private var showTemplatePicker = false
    @State private var showNoTemplatesAlert = false
    @State private var showTemplateSavedAlert = false
    @State private var showAddressPicker = false
    @State private var selectedGroomerForDetails: Groomer?
    @State private var showChatInbox = false

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

    private var homeTransitionAnimation: Animation {
        .smooth(duration: 0.46)
    }

    private var searchRadiusOptions: [Int] {
        [3, 5, 10, 15, 25, 50]
    }

    private var currentLocationAddress: ProfileAddress {
        ProfileAddress(
            streetLine1: "",
            streetLine2: "",
            city: model.currentUser.city,
            state: "",
            postalCode: model.currentUser.zipCode,
            country: "United States"
        )
    }

    private var selectedTaskAddress: ProfileAddress {
        switch selectedAddressSource {
        case .currentLocation:
            currentLocationAddress
        case .savedProfileAddress:
            model.customerPersonalProfile.address.isEmpty ? currentLocationAddress : model.customerPersonalProfile.address
        case .manualEntry:
            manualTaskAddress.isEmpty ? currentLocationAddress : manualTaskAddress
        }
    }

    private var currentSearchArea: GroomingTaskSearchArea {
        let address = selectedTaskAddress
        return GroomingTaskSearchArea(
            label: selectedAddressSource.displayTitle,
            addressSource: selectedAddressSource,
            streetLine1: address.streetLine1,
            streetLine2: address.streetLine2,
            city: address.city.isEmpty ? model.currentUser.city : address.city,
            state: address.state,
            zipCode: address.postalCode.isEmpty ? model.currentUser.zipCode : address.postalCode,
            country: address.country,
            radiusMiles: selectedSearchRadiusMiles,
            usesCurrentLocation: selectedAddressSource == .currentLocation,
            latitude: nil,
            longitude: nil
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HomeHeroHeader(isCompact: model.currentGroomingTask != nil)

                groomingTaskBuilder

                if let task = model.currentGroomingTask {
                    SectionHeader(title: "Recommended for this task")
                    VStack(spacing: 14) {
                        ForEach(model.recommendedGroomers(for: task)) { groomer in
                            let submission = model.taskSubmission(for: task, groomer: groomer)
                            GroomerCard(
                                groomer: groomer,
                                portfolio: model.portfolio(for: groomer),
                                isSaved: model.isFavorite(targetType: .groomer, targetID: groomer.id),
                                onSave: { model.toggleFavorite(targetType: .groomer, targetID: groomer.id) },
                                onContact: { model.sendCurrentTask(to: groomer) },
                                contactTitle: submission?.status.customerActionTitle ?? "Send Task Card",
                                contactIcon: submission == nil ? "paperplane.fill" : "checkmark.seal.fill",
                                isContactDisabled: submission != nil,
                                secondaryTitle: "View Profile",
                                secondaryIcon: "person.text.rectangle",
                                onSecondaryAction: { selectedGroomerForDetails = groomer }
                            )
                            .padding(.horizontal, 18)
                        }
                    }
                }
            }
            .padding(.bottom, 28)
            .animation(homeTransitionAnimation, value: model.currentGroomingTask?.id)
        }
        .appBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ChatToolbarButton(
                    hasConversations: !model.chatConversations(for: .petOwner).isEmpty,
                    action: { showChatInbox = true }
                )
            }
        }
        .sheet(isPresented: $showNewPet) {
            PetEditorView(mode: .create)
                .environmentObject(model)
        }
        .sheet(isPresented: $showChatInbox) {
            TaskChatInboxView(viewerRole: .petOwner)
                .environmentObject(model)
        }
        .sheet(isPresented: $showAddressPicker) {
            TaskAddressPickerView(
                selectedSource: $selectedAddressSource,
                manualAddress: $manualTaskAddress
            )
            .environmentObject(model)
        }
        .navigationDestination(item: $selectedGroomerForDetails) { groomer in
            GroomerProfileView(groomer: groomer)
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
                        withAnimation(homeTransitionAnimation) {
                            clearTaskDraft()
                            model.cancelGroomingTask()
                            isEditingTask = true
                            templateSaved = false
                        }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showStyleReferencePhotoPicker = true
                }
            }
            if styleReferenceSource != nil {
                Button("Remove Reference", role: .destructive) {
                    styleReferenceSource = nil
                    selectedStyleReferencePhoto = nil
                }
            }
        } message: {
            Text("Attach a style you like so the groomer can understand the look.")
        }
        .photosPicker(isPresented: $showStyleReferencePhotoPicker, selection: $selectedStyleReferencePhoto, matching: .images)
        .onChange(of: selectedStyleReferencePhoto) { _, item in
            guard item != nil else { return }
            styleReferenceSource = .photoLibrary
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

            HStack(spacing: 10) {
                taskField(title: "Address") {
                    Button {
                        showAddressPicker = true
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: selectedAddressSource.iconName)
                            Text(currentSearchArea.locationTitle)
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.coral)
                    }
                    .buttonStyle(.plain)
                }

                taskField(title: "Search range") {
                    Picker("Search range", selection: $selectedSearchRadiusMiles) {
                        ForEach(searchRadiusOptions, id: \.self) { radius in
                            Text("Within \(radius) mi").tag(radius)
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

        withAnimation(homeTransitionAnimation) {
            model.saveGroomingTask(
                pet: selectedPet,
                service: selectedService,
                targetDate: safeDate,
                timeWindow: selectedTimeWindow,
                searchArea: currentSearchArea,
                styleGoal: cleanedStyleGoal.isEmpty ? defaultStyleGoal(for: selectedService) : cleanedStyleGoal,
                specialNotes: cleaned(specialNotes),
                styleReferenceSource: styleReferenceSource
            )
            isEditingTask = false
            templateSaved = false
        }
    }

    private func populateDraft(from task: GroomingTask) {
        if let petIndex = model.pets.firstIndex(where: { $0.id == task.petID }) {
            selectedPetIndex = petIndex
        }
        selectedService = task.service
        selectedDate = task.targetDate < todayStart ? todayStart : task.targetDate
        selectedTimeWindow = task.timeWindow
        selectedSearchRadiusMiles = task.searchArea.radiusMiles
        selectedAddressSource = task.searchArea.addressSource
        manualTaskAddress = ProfileAddress(
            streetLine1: task.searchArea.streetLine1,
            streetLine2: task.searchArea.streetLine2,
            city: task.searchArea.city,
            state: task.searchArea.state,
            postalCode: task.searchArea.zipCode,
            country: task.searchArea.country
        )
        styleGoal = task.styleGoal
        specialNotes = task.specialNotes
        styleReferenceSource = task.styleReferenceSource
    }

    private func clearTaskDraft() {
        selectedPetIndex = 0
        selectedService = .bath
        selectedDate = todayStart
        selectedTimeWindow = .eightAM
        selectedSearchRadiusMiles = 10
        selectedAddressSource = .currentLocation
        manualTaskAddress = .empty
        styleGoal = ""
        specialNotes = ""
        styleReferenceSource = nil
        selectedStyleReferencePhoto = nil
    }

    private func applyTemplate(_ template: GroomingTaskTemplate) {
        if let petIndex = model.pets.firstIndex(where: { $0.id == template.petID }) {
            selectedPetIndex = petIndex
        }
        selectedService = template.service
        selectedDate = todayStart
        selectedTimeWindow = template.timeWindow
        selectedSearchRadiusMiles = template.searchArea.radiusMiles
        selectedAddressSource = template.searchArea.addressSource == .manualEntry ? .currentLocation : template.searchArea.addressSource
        manualTaskAddress = .empty
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

struct HomeHeroHeader: View {
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 0 : 6) {
            Text("Find the actual groomer")
                .animatedRoundedFont(size: isCompact ? 22 : 42, weight: .bold)
                .foregroundStyle(PetTheme.ink)
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !isCompact {
                Text("Compare real portfolios, pet-fit details, price ranges, and direct contact options.")
                    .font(.subheadline)
                    .foregroundStyle(PetTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, isCompact ? 4 : 12)
        .animation(.smooth(duration: 0.46), value: isCompact)
    }
}

private struct AnimatedRoundedFontModifier: AnimatableModifier {
    var size: CGFloat
    let weight: Font.Weight

    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: .rounded))
    }
}

private extension View {
    func animatedRoundedFont(size: CGFloat, weight: Font.Weight) -> some View {
        modifier(AnimatedRoundedFontModifier(size: size, weight: weight))
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
                Chip(text: "\(recommendedCount) public groomer cards matched", color: PetTheme.mint)
                Chip(text: task.referenceImageSlot.hasImage ? "Reference ready" : "Reference slot ready", color: PetTheme.sky)
            }

            Divider()
                .overlay(PetTheme.line.opacity(0.45))

            HStack(alignment: .top, spacing: 16) {
                GroomingTaskFact(iconName: "calendar", title: "Date", value: dateText)
                GroomingTaskFact(iconName: "clock", title: "Time", value: task.timeWindow.displayTitle)
            }

            HStack(alignment: .top, spacing: 16) {
                GroomingTaskFact(iconName: task.searchArea.addressSource.iconName, title: "Address", value: task.searchArea.locationTitle)
                GroomingTaskFact(iconName: "scope", title: "Search range", value: task.searchArea.rangeTitle)
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
                Label("Saved as a local task-card package", systemImage: "shippingbox.fill")
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

struct TaskAddressPickerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSource: GroomingTaskAddressSource
    @Binding var manualAddress: ProfileAddress
    @State private var showsManualEntry = false

    private var savedAddress: ProfileAddress {
        model.customerPersonalProfile.address
    }

    var body: some View {
        NavigationStack {
            Group {
                if showsManualEntry {
                    ManualAddressEntryView(initialAddress: manualAddress) { address in
                        manualAddress = address
                        selectedSource = .manualEntry
                        dismiss()
                    } onCancel: {
                        showsManualEntry = false
                    }
                } else {
                    addressOptions
                }
            }
            .navigationTitle("Task address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showsManualEntry {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    private var addressOptions: some View {
        ScrollView {
            VStack(spacing: 12) {
                addressOption(
                    title: "Current Location",
                    subtitle: [model.currentUser.city, model.currentUser.zipCode].filter { !$0.isEmpty }.joined(separator: ", "),
                    icon: "location.fill",
                    isSelected: selectedSource == .currentLocation
                ) {
                    selectedSource = .currentLocation
                    dismiss()
                }

                addressOption(
                    title: "Saved Profile Address",
                    subtitle: savedAddress.isEmpty ? "Add an address from Account first" : savedAddress.compactTitle,
                    icon: "house.fill",
                    isSelected: selectedSource == .savedProfileAddress
                ) {
                    guard !savedAddress.isEmpty else { return }
                    selectedSource = .savedProfileAddress
                    dismiss()
                }
                .opacity(savedAddress.isEmpty ? 0.55 : 1)

                addressOption(
                    title: manualAddress.isEmpty ? "Enter a New Address" : "Manual Address",
                    subtitle: manualAddress.isEmpty ? "Use address search or standard address fields" : manualAddress.compactTitle,
                    icon: "mappin.and.ellipse",
                    isSelected: selectedSource == .manualEntry
                ) {
                    showsManualEntry = true
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .appBackground()
    }

    private func addressOption(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isSelected ? PetTheme.coral : PetTheme.sage)
                    .frame(width: 36, height: 36)
                    .background((isSelected ? PetTheme.coral : PetTheme.sage).opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                    Text(subtitle.isEmpty ? "No address detail available" : subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isSelected ? PetTheme.coral : PetTheme.muted)
            }
            .taskCard()
        }
        .buttonStyle(.plain)
    }
}

struct ManualAddressEntryView: View {
    @StateObject private var completer = AddressSearchCompleter()
    @State private var draft: ProfileAddress
    @State private var isResolvingSuggestion = false

    let onSave: (ProfileAddress) -> Void
    let onCancel: () -> Void

    init(initialAddress: ProfileAddress, onSave: @escaping (ProfileAddress) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: initialAddress.isEmpty ? .empty : initialAddress)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var canSave: Bool {
        !draft.streetLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !draft.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !draft.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !draft.postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search address")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PetTheme.muted)
                    TextField("Street address, city, ZIP", text: $completer.query)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if isResolvingSuggestion {
                    Label("Loading address details", systemImage: "location.magnifyingglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }

                if !completer.results.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(completer.results.prefix(5).enumerated()), id: \.offset) { _, result in
                            Button {
                                apply(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PetTheme.ink)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(PetTheme.muted)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(11)
                                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(spacing: 10) {
                    addressTextField("Street address", text: $draft.streetLine1)
                    addressTextField("Apt, suite, unit", text: $draft.streetLine2)
                    addressTextField("City", text: $draft.city)
                    HStack(spacing: 10) {
                        addressTextField("State", text: $draft.state)
                        addressTextField("ZIP", text: $draft.postalCode)
                    }
                    addressTextField("Country", text: $draft.country)
                }

                HStack(spacing: 10) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(QuietButtonStyle())

                    Button {
                        onSave(cleaned(draft))
                    } label: {
                        Label("Use Address", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CoralButtonStyle())
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.55)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .appBackground()
    }

    private func addressTextField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.words)
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func apply(_ completion: MKLocalSearchCompletion) {
        isResolvingSuggestion = true
        Task {
            let address = await resolvedAddress(from: completion)
            await MainActor.run {
                draft = address
                completer.query = address.compactTitle
                completer.results = []
                isResolvingSuggestion = false
            }
        }
    }

    private func resolvedAddress(from completion: MKLocalSearchCompletion) async -> ProfileAddress {
        let request = MKLocalSearch.Request(completion: completion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            if let item = response.mapItems.first {
                let placemark = item.placemark
                return cleaned(
                    ProfileAddress(
                        streetLine1: [placemark.subThoroughfare, placemark.thoroughfare].compactMap { $0 }.joined(separator: " "),
                        streetLine2: "",
                        city: placemark.locality ?? "",
                        state: placemark.administrativeArea ?? "",
                        postalCode: placemark.postalCode ?? "",
                        country: placemark.country ?? "United States"
                    )
                )
            }
        } catch {
            return fallbackAddress(from: completion)
        }

        return fallbackAddress(from: completion)
    }

    private func fallbackAddress(from completion: MKLocalSearchCompletion) -> ProfileAddress {
        cleaned(
            ProfileAddress(
                streetLine1: completion.title,
                streetLine2: "",
                city: "",
                state: "",
                postalCode: "",
                country: "United States"
            )
        )
    }

    private func cleaned(_ address: ProfileAddress) -> ProfileAddress {
        ProfileAddress(
            streetLine1: address.streetLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            streetLine2: address.streetLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: address.city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: address.state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            postalCode: address.postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: address.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "United States" : address.country.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

final class AddressSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = "" {
        didSet {
            completer.queryFragment = query
        }
    }
    @Published var results: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.results = []
        }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SavedView()
                } label: {
                    Label("Saved", systemImage: "heart.fill")
                }
                .accessibilityLabel("Open saved groomers and portfolio")
            }
        }
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

struct OrdersView: View {
    @EnvironmentObject private var model: AppModel

    private var orders: [CardExchangeOrderRecord] {
        model.orderRecords(for: .petOwner)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenTitle(title: "Orders", subtitle: "Task-card orders created from cards you have sent to groomers.")

                if orders.isEmpty {
                    EmptyState(
                        title: "No orders yet",
                        message: "Orders appear after you send a task card to a groomer.",
                        systemImage: "doc.text"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(orders) { order in
                            NavigationLink {
                                CustomerOrderDetailView(orderID: order.id)
                            } label: {
                                CustomerOrderRow(
                                    order: order,
                                    submission: model.taskSubmission(for: order),
                                    groomer: model.groomer(for: order)
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

struct CustomerOrderRow: View {
    let order: CardExchangeOrderRecord
    let submission: GroomingTaskSubmission?
    let groomer: Groomer?

    private var task: GroomingTask? {
        submission?.taskSnapshot
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: statusIcon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(statusColor)
                .frame(width: 34, height: 34)
                .background(statusColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(task?.service.rawValue ?? "Task card")
                        .font(.headline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(1)
                    Spacer()
                    Chip(text: order.status.label, color: statusColor.opacity(0.28))
                }

                Text(groomer?.name ?? "Groomer card")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.coralDark)
                    .lineLimit(1)

                Text(orderSubtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetTheme.muted)
                    .lineLimit(2)

                Text("Updated \(order.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(PetTheme.muted.opacity(0.86))
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted.opacity(0.72))
                .padding(.top, 8)
        }
        .taskCard()
    }

    private var orderSubtitle: String {
        guard let task else {
            return "Task package and groomer card links saved"
        }

        return "\(task.petSnapshot.name) · \(task.targetDate.formatted(date: .abbreviated, time: .omitted)) · \(task.timeWindow.displayTitle)"
    }

    private var statusIcon: String {
        switch order.status {
        case .waitingReply: "clock.fill"
        case .accepted: "checkmark.seal.fill"
        case .rejected: "xmark.seal.fill"
        case .cancelled: "minus.circle.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch order.status {
        case .waitingReply: PetTheme.apricot
        case .accepted: PetTheme.mint
        case .rejected, .cancelled, .completed: Color.gray.opacity(0.44)
        }
    }
}

struct CustomerOrderDetailView: View {
    @EnvironmentObject private var model: AppModel

    let orderID: UUID

    private var order: CardExchangeOrderRecord? {
        model.orderRecords(for: .petOwner).first { $0.id == orderID }
    }

    var body: some View {
        ScrollView {
            if let order {
                let submission = model.taskSubmission(for: order)
                let task = submission?.taskSnapshot
                let groomer = model.groomer(for: order)

                VStack(spacing: 16) {
                    ScreenTitle(title: "Order details", subtitle: "This order links your sent task-card package with the groomer public card.")

                    VStack(alignment: .leading, spacing: 13) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task?.service.rawValue ?? "Task card order")
                                    .font(.title2.weight(.bold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(PetTheme.ink)
                                Text(groomer?.name ?? "Groomer public card")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PetTheme.muted)
                            }
                            Spacer()
                            Chip(text: order.status.label, color: statusColor(order.status).opacity(0.28))
                        }

                        if let task {
                            detailRow("Pet", value: task.petSnapshot.name, icon: "pawprint.fill")
                            detailRow("Appointment", value: "\(task.targetDate.formatted(date: .abbreviated, time: .omitted)) · \(task.timeWindow.displayTitle)", icon: "calendar")
                            detailRow("Service", value: task.service.rawValue, icon: "scissors")
                        }
                        detailRow("Order store", value: order.localStoreLink.storageScope.displayTitle, icon: "doc.text.fill")
                        detailRow("Task package", value: order.taskCardLink.compactURL, icon: "shippingbox.fill")
                        detailRow("Groomer card", value: order.groomerCardLink.compactURL, icon: "person.text.rectangle")
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    if let submission {
                        HStack(spacing: 10) {
                            NavigationLink {
                                TaskChatView(
                                    submissionID: submission.id,
                                    senderRole: .petOwner,
                                    showsDoneButton: false
                                )
                                .environmentObject(model)
                            } label: {
                                Label("Message", systemImage: "bubble.left.and.bubble.right.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(CoralButtonStyle())

                            if let groomer {
                                NavigationLink {
                                    GroomerProfileView(groomer: groomer)
                                } label: {
                                    Label("Profile", systemImage: "person.text.rectangle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(QuietButtonStyle())
                            }
                        }
                        .padding(.horizontal, 18)
                    } else {
                        Label("Chat is unavailable because the task submission is missing.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PetTheme.muted)
                            .taskCard()
                            .padding(.horizontal, 18)
                    }
                }
                .padding(.bottom, 28)
            } else {
                EmptyState(title: "Order not found", message: "This order record is no longer available.", systemImage: "doc.badge.exclamationmark")
            }
        }
        .appBackground()
        .navigationTitle("Order")
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

    private func statusColor(_ status: CardExchangeOrderStatus) -> Color {
        switch status {
        case .waitingReply: PetTheme.apricot
        case .accepted: PetTheme.mint
        case .rejected, .cancelled, .completed: Color.gray.opacity(0.44)
        }
    }
}

struct AccountView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showPersonalProfileEditor = false

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

                    if model.activeRole == .groomer {
                        NavigationLink {
                            MyGroomerProfileView()
                        } label: {
                            Label("My Groomer Profile", systemImage: "person.text.rectangle.fill")
                        }
                        .buttonStyle(CoralButtonStyle())
                    }

                    Divider()
                    Label("No platform payment, booking calendar, or real-time chat in MVP", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }
                .taskCard()
                .padding(.horizontal, 18)

                SectionHeader(title: "Personal information")
                VStack(alignment: .leading, spacing: 12) {
                    profileRow("Name", value: model.customerPersonalProfile.fullName, icon: "person.fill")
                    profileRow("Gender", value: model.customerPersonalProfile.gender.rawValue, icon: "person.text.rectangle")
                    profileRow("Address", value: model.customerPersonalProfile.address.formattedAddress, icon: "house.fill")
                    profileRow("Phone", value: model.customerPersonalProfile.phone, icon: "phone.fill")
                    profileRow("Email", value: model.customerPersonalProfile.email, icon: "envelope.fill")

                    Button {
                        showPersonalProfileEditor = true
                    } label: {
                        Label("Edit Personal Info", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuietButtonStyle())
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
        .sheet(isPresented: $showPersonalProfileEditor) {
            CustomerPersonalProfileEditorView(profile: model.customerPersonalProfile) { profile in
                model.updateCustomerPersonalProfile(profile)
            }
        }
    }

    private func profileRow(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(PetTheme.sage)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value.isEmpty ? "Not set" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct CustomerPersonalProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CustomerPersonalProfile

    let onSave: (CustomerPersonalProfile) -> Void

    init(profile: CustomerPersonalProfile, onSave: @escaping (CustomerPersonalProfile) -> Void) {
        _draft = State(initialValue: profile)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    profileTextField("Name", text: $draft.fullName)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.muted)
                        Picker("Gender", selection: $draft.gender) {
                            ForEach(UserGender.allCases) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    profileTextField("Street address", text: $draft.address.streetLine1)
                    profileTextField("Apt, suite, unit", text: $draft.address.streetLine2)
                    profileTextField("City", text: $draft.address.city)
                    HStack(spacing: 10) {
                        profileTextField("State", text: $draft.address.state)
                        profileTextField("ZIP", text: $draft.address.postalCode)
                    }
                    profileTextField("Country", text: $draft.address.country)
                    profileTextField("Phone", text: $draft.phone)
                        .keyboardType(.phonePad)
                    profileTextField("Email", text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .appBackground()
            .navigationTitle("Personal Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(cleaned(draft))
                        dismiss()
                    }
                }
            }
        }
    }

    private func profileTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func cleaned(_ profile: CustomerPersonalProfile) -> CustomerPersonalProfile {
        var cleanedProfile = profile
        cleanedProfile.fullName = profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedProfile.phone = profile.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedProfile.email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedProfile.address = ProfileAddress(
            streetLine1: profile.address.streetLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            streetLine2: profile.address.streetLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: profile.address.city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: profile.address.state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            postalCode: profile.address.postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: profile.address.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "United States" : profile.address.country.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return cleanedProfile
    }
}
