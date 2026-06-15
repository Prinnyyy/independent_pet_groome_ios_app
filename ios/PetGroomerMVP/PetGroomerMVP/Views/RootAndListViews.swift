import CoreLocation
import MapKit
import Photos
import PhotosUI
import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView(selection: $model.selectedAppTab) {
            if model.activeRole == .petOwner {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag("home")

                NavigationStack {
                    SearchView()
                }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag("search")

                NavigationStack {
                    PetsView()
                }
                .tabItem { Label("Pets", systemImage: "pawprint.fill") }
                .tag("pets")

                NavigationStack {
                    OrdersView()
                }
                .tabItem { Label("Orders", systemImage: "doc.text.fill") }
                .tag("orders")
            } else {
                NavigationStack {
                    GroomerTodayView()
                }
                .tabItem { Label("Today", systemImage: "chart.line.uptrend.xyaxis") }
                .tag("groomerToday")

                NavigationStack {
                    GroomerScheduleView()
                }
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag("groomerSchedule")

                NavigationStack {
                    GroomerInboxView()
                }
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .tag("groomerInbox")

                NavigationStack {
                    GroomerPortfolioManagerView()
                }
                .tabItem { Label("Portfolio", systemImage: "photo.stack.fill") }
                .tag("groomerPortfolio")
            }

            NavigationStack {
                AccountView()
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle.fill") }
            .tag("account")
        }
        .tint(PetTheme.coral)
    }
}

struct CustomerChatToolbarModifier: ViewModifier {
    @EnvironmentObject private var model: AppModel
    @State private var showChatInbox = false
    let viewerRole: AppRole

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ChatToolbarButton(
                        hasConversations: model.hasUnreadMessages(for: viewerRole),
                        action: { showChatInbox = true }
                    )
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
            }
            .sheet(isPresented: $showChatInbox) {
                TaskChatInboxView(viewerRole: viewerRole)
                    .environmentObject(model)
            }
    }
}

extension View {
    func customerChatToolbar() -> some View {
        modifier(CustomerChatToolbarModifier(viewerRole: .petOwner))
    }

    func groomerChatToolbar() -> some View {
        modifier(CustomerChatToolbarModifier(viewerRole: .groomer))
    }

    func roleAwareChatToolbar() -> some View {
        modifier(RoleAwareChatToolbarModifier())
    }
}

struct RoleAwareChatToolbarModifier: ViewModifier {
    @EnvironmentObject private var model: AppModel

    func body(content: Content) -> some View {
        content.modifier(CustomerChatToolbarModifier(viewerRole: model.activeRole))
    }
}

private struct ShakeEffect: GeometryEffect {
    var trigger: Int
    var animatableData: CGFloat {
        get { CGFloat(trigger) }
        set { trigger = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 3) * 4
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

private enum GroomingTaskReferenceRenditionFactory {
    static func makeRenditions(from data: Data) -> GroomingTaskReferenceImageRenditions {
        guard let image = UIImage(data: data) else {
            return GroomingTaskReferenceImageRenditions(
                originalData: data,
                thumbnailData: data,
                previewData: data,
                fullScreenData: data
            )
        }

        return GroomingTaskReferenceImageRenditions(
            originalData: data,
            thumbnailData: centerCroppedJPEGData(from: image, targetSize: CGSize(width: 520, height: 520)),
            previewData: scaledJPEGData(from: image, fittingInside: CGSize(width: 1200, height: 900)),
            fullScreenData: scaledJPEGData(from: image, fittingInside: CGSize(width: 2400, height: 2400))
        )
    }

    private static func centerCroppedJPEGData(from image: UIImage, targetSize: CGSize) -> Data? {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0, targetSize.width > 0, targetSize.height > 0 else {
            return image.jpegData(compressionQuality: 0.86)
        }

        let targetAspect = targetSize.width / targetSize.height
        let sourceAspect = sourceSize.width / sourceSize.height
        let cropSize: CGSize
        if sourceAspect > targetAspect {
            cropSize = CGSize(width: sourceSize.height * targetAspect, height: sourceSize.height)
        } else {
            cropSize = CGSize(width: sourceSize.width, height: sourceSize.width / targetAspect)
        }

        let cropOrigin = CGPoint(
            x: (sourceSize.width - cropSize.width) / 2,
            y: (sourceSize.height - cropSize.height) / 2
        )
        let cropRect = CGRect(origin: cropOrigin, size: cropSize)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(
                x: -cropRect.origin.x * targetSize.width / cropRect.width,
                y: -cropRect.origin.y * targetSize.height / cropRect.height,
                width: sourceSize.width * targetSize.width / cropRect.width,
                height: sourceSize.height * targetSize.height / cropRect.height
            ))
        }
        return rendered.jpegData(compressionQuality: 0.86)
    }

    private static func scaledJPEGData(from image: UIImage, fittingInside maxSize: CGSize) -> Data? {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0, maxSize.width > 0, maxSize.height > 0 else {
            return image.jpegData(compressionQuality: 0.88)
        }
        let scale = min(1, maxSize.width / sourceSize.width, maxSize.height / sourceSize.height)
        let targetSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.88)
    }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var locationProvider = CurrentLocationProvider()
    @State private var showNewPet = false
    @State private var selectedPetID: UUID?
    @State private var selectedService: GroomingTaskService = .bath
    @State private var selectedDate = Date()
    @State private var selectedTimeWindow: GroomingTaskTimeWindow = .eightAM
    @State private var selectedServiceLocation: GroomingTaskServiceLocation = .atCustomerAddress
    @State private var selectedSearchRadiusMiles = 10
    @State private var selectedAddressSource: GroomingTaskAddressSource = .currentLocation
    @State private var manualTaskAddress: ProfileAddress = .empty
    @State private var styleGoal = ""
    @State private var specialNotes = ""
    @State private var styleReferenceSource: GroomingTaskStyleReferenceSource?
    @State private var styleReferenceImageData: Data?
    @State private var styleReferenceImageRenditions: GroomingTaskReferenceImageRenditions?
    @State private var selectedStyleReferencePhoto: PhotosPickerItem?
    @State private var showStyleReferencePhotoPicker = false
    @State private var isEditingTask = true
    @State private var hasLoadedTemporaryTaskContainer = false
    @State private var styleGoalLimitFeedback = false
    @State private var styleGoalShakeTrigger = 0
    @State private var showStyleReferenceTooLargeAlert = false
    @State private var showStyleReferenceCameraPicker = false
    @State private var showCameraUnavailableAlert = false
    @State private var showManualAddressEntry = false
    @State private var showTaskDatePicker = false
    @State private var selectedGroomerForDetails: Groomer?

    private var selectedPet: Pet? {
        if let selectedPetID, let pet = model.pets.first(where: { $0.id == selectedPetID }) {
            return pet
        }
        return model.pets.first
    }

    private let styleGoalCharacterLimit = 100

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
        if let resolvedAddress = locationProvider.currentAddress {
            return resolvedAddress
        }
        return ProfileAddress(
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
            VStack(spacing: 9) {
                if let task = model.currentGroomingTask,
                   let acceptedSubmission = model.acceptedTaskSubmission(for: task),
                   let pet = model.pet(for: task) {
                    AcceptedTaskConfirmationView(
                        task: task,
                        pet: pet,
                        groomer: model.groomers.first { $0.id == acceptedSubmission.groomerID },
                        onCreateNewTask: {
                            withAnimation(homeTransitionAnimation) {
                                clearTaskDraft()
                                model.cancelGroomingTask()
                                isEditingTask = true
                            }
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                } else {
                    taskBuilderHeader
                    groomingTaskBuilder
                }

                if let task = model.currentGroomingTask,
                   model.acceptedTaskSubmission(for: task) == nil,
                   !isEditingTask {
                    SectionHeader(title: "Recommended for this task")
                    VStack(spacing: 14) {
                        ForEach(model.recommendedGroomers(for: task)) { groomer in
                            let pendingSubmission = model.pendingTaskSubmission(for: task, groomer: groomer)
                            GroomerCard(
                                groomer: groomer,
                                portfolio: model.portfolio(for: groomer),
                                isSaved: model.isFavorite(targetType: .groomer, targetID: groomer.id),
                                onSave: { model.toggleFavorite(targetType: .groomer, targetID: groomer.id) },
                                onContact: {
                                    if let pendingSubmission {
                                        model.revokeTaskSubmission(id: pendingSubmission.id)
                                    } else {
                                        model.sendCurrentTask(to: groomer)
                                    }
                                },
                                contactTitle: pendingSubmission == nil ? "Send Card" : "Revoke",
                                contactIcon: pendingSubmission == nil ? "paperplane.fill" : "arrow.uturn.backward.circle.fill",
                                isContactDisabled: false,
                                contactMismatchReasons: [],
                                secondaryTitle: "Details",
                                secondaryIcon: "person.text.rectangle",
                                onSecondaryAction: { selectedGroomerForDetails = groomer }
                            )
                            .padding(.horizontal, 18)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
            .animation(homeTransitionAnimation, value: model.currentGroomingTask?.id)
        }
        .appBackground()
        .customerChatToolbar()
        .sheet(isPresented: $showNewPet) {
            PetEditorView(mode: .create)
                .environmentObject(model)
        }
        .sheet(isPresented: $showManualAddressEntry) {
            ManualAddressEntryView(initialAddress: manualTaskAddress, showsHomeAddressToggle: true) { address, shouldUpdateHomeAddress in
                manualTaskAddress = address
                selectedAddressSource = .manualEntry
                if shouldUpdateHomeAddress {
                    var profile = model.customerPersonalProfile
                    profile.address = address
                    model.updateCustomerPersonalProfile(profile)
                }
                showManualAddressEntry = false
            } onCancel: {
                showManualAddressEntry = false
            }
            .environmentObject(model)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTaskDatePicker) {
            VStack(spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose date")
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(PetTheme.ink)
                        Text("Past dates are unavailable.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PetTheme.muted)
                    }

                    Spacer()

                    Button {
                        showTaskDatePicker = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.muted)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close date picker")
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                VStack(spacing: 10) {
                    DatePicker(
                        "Task date",
                        selection: $selectedDate,
                        in: validTaskDateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(PetTheme.coral)
                    .labelsHidden()
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PetTheme.line.opacity(0.55), lineWidth: 1)
                )
                .padding(.horizontal, 18)

                Spacer(minLength: 0)

                Button {
                    showTaskDatePicker = false
                } label: {
                    Label("Use This Date", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CoralButtonStyle())
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .appBackground()
            .safeAreaPadding(.bottom, 10)
            .presentationDetents([.fraction(0.72), .large])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(item: $selectedGroomerForDetails) { groomer in
            GroomerProfileView(groomer: groomer)
        }
        .onChange(of: model.pets.map(\.id)) { _, petIDs in
            if let selectedPetID, petIDs.contains(selectedPetID) {
                return
            }
            self.selectedPetID = petIDs.first
        }
        .onAppear {
            restoreTemporaryTaskContainerIfNeeded()
            if selectedDate < todayStart {
                selectedDate = todayStart
            }
        }
        .onChange(of: selectedPetID) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: selectedService) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: selectedDate) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: selectedTimeWindow) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: selectedServiceLocation) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: selectedSearchRadiusMiles) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: selectedAddressSource) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: manualTaskAddress) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: styleGoal) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: specialNotes) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: styleReferenceSource) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: styleReferenceImageData) { _, _ in saveTemporaryDraft(state: .editing) }
        .onChange(of: styleReferenceImageRenditions) { _, _ in saveTemporaryDraft(state: .editing) }
    }

    private var taskBuilderHeader: some View {
        let hasGeneratedTask = model.currentGroomingTask != nil && !isEditingTask
        return VStack(alignment: .leading, spacing: 8) {
            Text(hasGeneratedTask ? "Recommended groomers" : "Create a task card")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PetTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(hasGeneratedTask ? "These groomer cards match this task’s pet, timing, location, and style goal." : "Set the pet, time, place, and style goal before choosing a groomer.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PetTheme.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [PetTheme.porcelain, PetTheme.apricot.opacity(0.44)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.045), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 18)
    }

    @ViewBuilder
    private var groomingTaskBuilder: some View {
        Group {
            if let task = model.currentGroomingTask, let pet = model.pet(for: task), !isEditingTask {
                GroomingTaskCard(
                    task: task,
                    pet: pet,
                    recommendedCount: model.recommendedGroomers(for: task).count,
                    onRewrite: {
                        populateDraft(from: task)
                        withAnimation(homeTransitionAnimation) {
                            model.cancelGroomingTask()
                            isEditingTask = true
                        }
                        saveTemporaryDraft(state: .editing)
                    }
                )
                .padding(.horizontal, 18)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if model.pets.isEmpty {
                        Text("Create a pet card first so this task can use your pet list.")
                            .font(.subheadline)
                            .foregroundStyle(PetTheme.muted)
                        Button {
                            showNewPet = true
                        } label: {
                            Label("Create Pet Card", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(CoralButtonStyle())
                    } else {
                        taskForm
                    }
                }
                .padding(9)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(PetTheme.porcelain)
                        .shadow(color: .black.opacity(0.045), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PetTheme.line.opacity(0.72), lineWidth: 1)
                )
                .padding(.horizontal, 18)
            }
        }
        .photosPicker(isPresented: $showStyleReferencePhotoPicker, selection: $selectedStyleReferencePhoto, matching: .images)
        .onChange(of: selectedStyleReferencePhoto) { _, item in
            loadStyleReferenceImage(from: item)
        }
        .sheet(isPresented: $showStyleReferenceCameraPicker) {
            CameraPhotoPicker { data in
                if data.count > GroomingTaskReferenceImageSlot.maxByteSize {
                    styleReferenceSource = nil
                    styleReferenceImageData = nil
                    styleReferenceImageRenditions = nil
                    selectedStyleReferencePhoto = nil
                    showStyleReferenceTooLargeAlert = true
                } else {
                    let renditions = GroomingTaskReferenceRenditionFactory.makeRenditions(from: data)
                    styleReferenceSource = .camera
                    styleReferenceImageData = data
                    styleReferenceImageRenditions = renditions
                    selectedStyleReferencePhoto = nil
                    saveTemporaryDraft(state: .editing)
                }
            }
            .ignoresSafeArea()
        }
        .alert("Photo is too large", isPresented: $showStyleReferenceTooLargeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please upload one style reference photo smaller than 10 MB.")
        }
        .alert("Camera unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This simulator or device does not currently provide a camera. Please upload from Photos instead.")
        }
    }

    private var taskForm: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Task details")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.coralDark)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    if let template = model.savedGroomingTaskTemplates.first {
                        applyTemplate(template)
                    }
                } label: {
                    Label("Last Template", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .foregroundStyle(model.savedGroomingTaskTemplates.isEmpty ? PetTheme.muted.opacity(0.72) : PetTheme.coralDark)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PetTheme.line.opacity(0.55), lineWidth: 1)
                )
                .disabled(model.savedGroomingTaskTemplates.isEmpty)
                .accessibilityLabel("Use last generated task template")
            }

            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    taskField(title: "Pet") {
                        Picker("Pet", selection: selectedPetIDBinding) {
                            ForEach(model.pets) { pet in
                                Text(pet.name).tag(Optional(pet.id))
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

                GridRow {
                    taskField(title: "Date") {
                        Button {
                            showTaskDatePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                                Spacer(minLength: 2)
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(PetTheme.coral)
                        }
                        .buttonStyle(.plain)
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

                GridRow {
                    taskField(title: "Grooming place") {
                        Picker("Grooming place", selection: $selectedServiceLocation) {
                            ForEach(GroomingTaskServiceLocation.allCases) { location in
                                Text(location.displayTitle).tag(location)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    taskField(title: "Radius") {
                        Picker("Search range", selection: $selectedSearchRadiusMiles) {
                            ForEach(searchRadiusOptions, id: \.self) { radius in
                                Text("Within \(radius) mi").tag(radius)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                GridRow {
                    taskField(title: "Start from") {
                        Menu {
                            Button {
                                selectedAddressSource = .currentLocation
                                locationProvider.requestCurrentLocation()
                            } label: {
                                Label("Current Location", systemImage: "location.fill")
                            }

                            Button {
                                selectedAddressSource = .savedProfileAddress
                            } label: {
                                Label("Home Address", systemImage: "house.fill")
                            }
                            .disabled(model.customerPersonalProfile.address.isEmpty)

                            Button {
                                showManualAddressEntry = true
                            } label: {
                                Label("New Address", systemImage: "mappin.and.ellipse")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedAddressSource.iconName)
                                Text(currentSearchArea.locationTitle)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                                Spacer(minLength: 2)
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(PetTheme.coral)
                        }
                    }

                    Color.clear
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Style goal")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetTheme.muted)

                HStack(alignment: .center, spacing: 8) {
                    TextField("Bath only, teddy face, summer cut", text: limitedStyleGoalBinding, axis: .vertical)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2, reservesSpace: true)
                        .frame(height: 42, alignment: .topLeading)
                        .tint(styleGoalLimitFeedback ? PetTheme.coral : PetTheme.sage)
                        .modifier(ShakeEffect(trigger: styleGoalShakeTrigger))

                    Menu {
                        Button {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showStyleReferenceCameraPicker = true
                            } else {
                                showCameraUnavailableAlert = true
                            }
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }

                        Button {
                            showStyleReferencePhotoPicker = true
                        } label: {
                            Label("Upload from Photos", systemImage: "photo.fill.on.rectangle.fill")
                        }

                        if styleReferenceSource != nil {
                            Button(role: .destructive) {
                                styleReferenceSource = nil
                                styleReferenceImageData = nil
                                styleReferenceImageRenditions = nil
                                selectedStyleReferencePhoto = nil
                                saveTemporaryDraft(state: .editing)
                            } label: {
                                Label("Remove Reference", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: styleReferenceSource == nil ? "photo.badge.plus" : "photo.badge.checkmark")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(styleReferenceSource == nil ? PetTheme.coral : PetTheme.sage)
                            .frame(width: 32, height: 32)
                            .background(PetTheme.apricot.opacity(0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .accessibilityLabel("Add style reference photo")
                }

                if let styleReferenceSource {
                    Label(styleReferenceImageData == nil ? "No style photo selected" : "1 style photo selected", systemImage: styleReferenceSource.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(styleReferenceImageData == nil ? PetTheme.muted : PetTheme.sage)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(styleGoalLimitFeedback ? PetTheme.coral.opacity(0.75) : PetTheme.line.opacity(0.42), lineWidth: 1)
            )
            .animation(.smooth(duration: 0.18), value: styleGoalLimitFeedback)

            VStack(alignment: .leading, spacing: 6) {
                Text("Special notes")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                LimitedTextField("Matting, sensitive skin, afraid of dryers", text: $specialNotes, limit: 240, axis: .vertical)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2, reservesSpace: true)
                    .frame(height: 42, alignment: .topLeading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
            )

            HStack(spacing: 9) {
                Button {
                    generateTaskCard()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: model.currentGroomingTask == nil ? "doc.badge.plus" : "arrow.triangle.2.circlepath.doc.on.clipboard")
                            .font(.headline.weight(.bold))
                        Text(model.currentGroomingTask == nil ? "Create Task Card" : "Update Task Card")
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                }
                .buttonStyle(CoralButtonStyle())

                Button {
                    resetTemporaryTaskDraft()
                } label: {
                    Label("Clear", systemImage: "eraser.fill")
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(width: 76)
                        .padding(.vertical, 2)
                }
                .buttonStyle(QuietButtonStyle())
                .accessibilityLabel("Clear task card draft")
            }
        }
    }

    private func taskField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(PetTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 24, alignment: .center)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
        )
    }

    private var limitedStyleGoalBinding: Binding<String> {
        Binding(
            get: { styleGoal },
            set: { newValue in
                guard newValue.count <= styleGoalCharacterLimit else {
                    if styleGoal.count < styleGoalCharacterLimit {
                        styleGoal = String(newValue.prefix(styleGoalCharacterLimit))
                    }
                    triggerStyleGoalLimitFeedback()
                    return
                }
                styleGoal = newValue
            }
        )
    }

    private var selectedPetIDBinding: Binding<UUID?> {
        Binding(
            get: { selectedPet?.id },
            set: { newValue in selectedPetID = newValue }
        )
    }

    private func triggerStyleGoalLimitFeedback() {
        withAnimation(.linear(duration: 0.18)) {
            styleGoalShakeTrigger += 1
        }
        styleGoalLimitFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            styleGoalLimitFeedback = false
        }
    }

    private func restoreTemporaryTaskContainerIfNeeded() {
        guard !hasLoadedTemporaryTaskContainer else { return }
        let container = model.temporaryGroomingTaskContainer

        switch container.state {
        case .noData:
            clearTaskDraft()
            isEditingTask = true
        case .editing:
            applyTemporaryContainer(container)
            model.currentGroomingTask = nil
            isEditingTask = true
        case .completed:
            applyTemporaryContainer(container)
            model.currentGroomingTask = container.completedTask
            isEditingTask = false
        }
        hasLoadedTemporaryTaskContainer = true
    }

    private func applyTemporaryContainer(_ container: TemporaryGroomingTaskContainer) {
        selectedPetID = container.petID ?? model.pets.first?.id
        selectedService = container.service
        selectedDate = container.targetDate < todayStart ? todayStart : container.targetDate
        selectedTimeWindow = container.timeWindow
        selectedServiceLocation = container.serviceLocation
        selectedSearchRadiusMiles = container.searchArea.radiusMiles
        selectedAddressSource = container.searchArea.addressSource
        manualTaskAddress = ProfileAddress(
            streetLine1: container.searchArea.streetLine1,
            streetLine2: container.searchArea.streetLine2,
            city: container.searchArea.city,
            state: container.searchArea.state,
            postalCode: container.searchArea.zipCode,
            country: container.searchArea.country
        )
        styleGoal = String(container.styleGoal.prefix(styleGoalCharacterLimit))
        specialNotes = container.specialNotes
        styleReferenceSource = container.styleReferenceSource
        styleReferenceImageData = container.styleReferenceImageData
        styleReferenceImageRenditions = container.styleReferenceImageRenditions
    }

    private func saveTemporaryDraft(state: TemporaryGroomingTaskContainerState) {
        guard hasLoadedTemporaryTaskContainer, state != .noData else { return }
        guard let petID = selectedPet?.id else { return }
        let completedTask = state == .completed ? model.currentGroomingTask : nil
        model.saveTemporaryGroomingTaskContainer(
            TemporaryGroomingTaskContainer(
                state: state,
                petID: petID,
                service: selectedService,
                targetDate: selectedDate < todayStart ? todayStart : selectedDate,
                timeWindow: selectedTimeWindow,
                serviceLocation: selectedServiceLocation,
                searchArea: currentSearchArea,
                styleGoal: String(styleGoal.prefix(styleGoalCharacterLimit)),
                specialNotes: specialNotes,
                styleReferenceSource: styleReferenceSource,
                styleReferenceImageData: styleReferenceImageData,
                styleReferenceImageRenditions: styleReferenceImageRenditions,
                completedTask: completedTask,
                updatedAt: Date()
            )
        )
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
        let resolvedStyleGoal = cleanedStyleGoal.isEmpty ? defaultStyleGoal(for: selectedService) : cleanedStyleGoal

        if let currentTask = model.currentGroomingTask, draftMatches(currentTask, styleGoal: resolvedStyleGoal, targetDate: safeDate) {
            model.saveTemporaryGroomingTaskContainer(
                TemporaryGroomingTaskContainer(
                    state: .completed,
                    petID: currentTask.petID,
                    service: currentTask.service,
                    targetDate: currentTask.targetDate,
                    timeWindow: currentTask.timeWindow,
                    serviceLocation: currentTask.serviceLocation,
                    searchArea: currentTask.searchArea,
                    styleGoal: currentTask.styleGoal,
                    specialNotes: currentTask.specialNotes,
                    styleReferenceSource: currentTask.styleReferenceSource,
                    styleReferenceImageData: currentTask.referenceImageSlot.imageData,
                    styleReferenceImageRenditions: currentTask.referenceImageSlot.imageRenditions,
                    completedTask: currentTask,
                    updatedAt: Date()
                )
            )
            model.saveCurrentGroomingTaskAsTemplate()
            withAnimation(homeTransitionAnimation) {
                isEditingTask = false
            }
            returnToSearchIfNeeded()
            return
        }

        withAnimation(homeTransitionAnimation) {
            model.saveGroomingTask(
                pet: selectedPet,
                service: selectedService,
                targetDate: safeDate,
                timeWindow: selectedTimeWindow,
                serviceLocation: selectedServiceLocation,
                searchArea: currentSearchArea,
                styleGoal: resolvedStyleGoal,
                specialNotes: cleaned(specialNotes),
                styleReferenceSource: styleReferenceSource,
                styleReferenceImageData: styleReferenceImageData,
                styleReferenceImageRenditions: styleReferenceImageRenditions
            )
            model.saveCurrentGroomingTaskAsTemplate()
            isEditingTask = false
        }
        returnToSearchIfNeeded()
    }

    private func returnToSearchIfNeeded() {
        guard model.shouldReturnToSearchAfterTaskCreation else { return }
        model.shouldReturnToSearchAfterTaskCreation = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            model.selectedAppTab = "search"
        }
    }

    private func draftMatches(_ task: GroomingTask, styleGoal resolvedStyleGoal: String, targetDate safeDate: Date) -> Bool {
        guard selectedPet?.id == task.petID else { return false }
        return selectedService == task.service &&
            Calendar.current.isDate(safeDate, inSameDayAs: task.targetDate) &&
            selectedTimeWindow == task.timeWindow &&
            selectedServiceLocation == task.serviceLocation &&
            currentSearchArea == task.searchArea &&
            resolvedStyleGoal == task.styleGoal &&
            cleaned(specialNotes) == task.specialNotes &&
            styleReferenceSource == task.styleReferenceSource &&
            styleReferenceImageData == task.referenceImageSlot.imageData &&
            styleReferenceImageRenditions == task.referenceImageSlot.imageRenditions
    }

    private func populateDraft(from task: GroomingTask) {
        selectedPetID = task.petID
        selectedService = task.service
        selectedDate = task.targetDate < todayStart ? todayStart : task.targetDate
        selectedTimeWindow = task.timeWindow
        selectedServiceLocation = task.serviceLocation
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
        styleReferenceImageData = task.referenceImageSlot.imageData
        styleReferenceImageRenditions = task.referenceImageSlot.imageRenditions
    }

    private func clearTaskDraft() {
        selectedPetID = model.pets.first?.id
        selectedService = .bath
        selectedDate = todayStart
        selectedTimeWindow = .eightAM
        selectedServiceLocation = .atCustomerAddress
        selectedSearchRadiusMiles = 10
        selectedAddressSource = .currentLocation
        manualTaskAddress = .empty
        styleGoal = ""
        specialNotes = ""
        styleReferenceSource = nil
        styleReferenceImageData = nil
        styleReferenceImageRenditions = nil
        selectedStyleReferencePhoto = nil
    }

    private func resetTemporaryTaskDraft() {
        withAnimation(homeTransitionAnimation) {
            model.currentGroomingTask = nil
            model.clearTemporaryGroomingTaskContainer()
            hasLoadedTemporaryTaskContainer = false
            restoreTemporaryTaskContainerIfNeeded()
            isEditingTask = true
        }
    }

    private func applyTemplate(_ template: GroomingTaskTemplate) {
        selectedPetID = template.petID
        selectedService = template.service
        selectedDate = todayStart
        selectedTimeWindow = template.timeWindow
        selectedServiceLocation = template.serviceLocation
        selectedSearchRadiusMiles = template.searchArea.radiusMiles
        selectedAddressSource = template.searchArea.addressSource == .manualEntry ? .currentLocation : template.searchArea.addressSource
        manualTaskAddress = .empty
        styleGoal = template.styleGoal
        specialNotes = template.specialNotes
        styleReferenceSource = template.styleReferenceSource
        styleReferenceImageData = template.styleReferenceImageData
        styleReferenceImageRenditions = template.styleReferenceImageRenditions
        model.cancelGroomingTask()
        isEditingTask = true
        saveTemporaryDraft(state: .editing)
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadStyleReferenceImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            await MainActor.run {
                if data.count > GroomingTaskReferenceImageSlot.maxByteSize {
                    styleReferenceSource = nil
                    styleReferenceImageData = nil
                    styleReferenceImageRenditions = nil
                    selectedStyleReferencePhoto = nil
                    showStyleReferenceTooLargeAlert = true
                } else {
                    let renditions = GroomingTaskReferenceRenditionFactory.makeRenditions(from: data)
                    styleReferenceSource = .photoLibrary
                    styleReferenceImageData = data
                    styleReferenceImageRenditions = renditions
                    saveTemporaryDraft(state: .editing)
                }
            }
        }
    }
}

struct GroomingTaskCard: View {
    @State private var isDetailsExpanded = false
    @State private var showStyleReferencePreview = false

    let task: GroomingTask
    let pet: Pet
    let recommendedCount: Int
    let onRewrite: () -> Void
    var statusLabel: String?
    var showsActions: Bool = true

    private var canCollapseDetails: Bool {
        showsActions && statusLabel == nil
    }

    private var shouldShowDetails: Bool {
        !canCollapseDetails || isDetailsExpanded
    }

    private var dateText: String {
        task.targetDate.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: "rectangle.stack.badge.person.crop")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.coral)
                        Text("Task card")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(PetTheme.coralDark)
                            .textCase(.uppercase)
                    }
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
                if let statusLabel {
                    Chip(text: statusLabel, color: PetTheme.mint)
                }
            }

            matchSummary
                .zIndex(1)

            if canCollapseDetails {
                detailsToggle
                    .zIndex(1)
            }

            if shouldShowDetails {
                taskDetails
                    .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .top)))
                    .zIndex(0)
            }

            if showsActions {
                HStack(spacing: 10) {
                    Button(action: onRewrite) {
                        Label("Rewrite Card", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .buttonStyle(CoralButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 7)
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
        .overlay {
            GeometryReader { proxy in
                if showStyleReferencePreview {
                    let origin = proxy.frame(in: .global).origin

                    StyleReferencePreviewOverlay(slot: task.referenceImageSlot) {
                        withAnimation(.smooth(duration: 0.18)) {
                            showStyleReferencePreview = false
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .offset(x: -origin.x, y: -origin.y)
                    .zIndex(10_000)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .zIndex(showStyleReferencePreview ? 10_000 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isDetailsExpanded)
    }

    private var matchSummary: some View {
        HStack(spacing: 9) {
            Image(systemName: statusLabel == nil ? "sparkles" : "lock.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.sage)
                .frame(width: 24, height: 24)
                .background(PetTheme.mint.opacity(0.28), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(statusLabel == nil ? "\(recommendedCount) groomer cards matched" : "Task card locked")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
        )
    }

    private var detailsToggle: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                isDetailsExpanded.toggle()
            }
        } label: {
            Image(systemName: isDetailsExpanded ? "chevron.compact.up" : "chevron.compact.down")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PetTheme.muted.opacity(0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDetailsExpanded ? "Collapse task details" : "Expand task details")
    }

    private var taskDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    GroomingTaskFact(iconName: "calendar", title: "Date", value: dateText)
                    GroomingTaskFact(iconName: "clock", title: "Time", value: task.timeWindow.displayTitle)
                }
                GridRow {
                    GroomingTaskFact(iconName: task.searchArea.addressSource.iconName, title: "Start from", value: task.searchArea.locationTitle)
                    GroomingTaskFact(iconName: "scope", title: "Range", value: task.searchArea.rangeTitle)
                }
                GridRow {
                    GroomingTaskFact(iconName: task.serviceLocation.iconName, title: "Grooming place", value: task.serviceLocation.shortTitle)
                    Color.clear
                }
            }

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Style goal", systemImage: "scissors")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PetTheme.coralDark)
                    Text(task.styleGoal)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(PetTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                StyleReferenceImageButton(slot: task.referenceImageSlot) {
                    withAnimation(.smooth(duration: 0.2)) {
                        showStyleReferencePreview = true
                    }
                }
            }
            .padding(10)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
            )

            if !task.specialNotes.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Notes", systemImage: "exclamationmark.bubble")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PetTheme.coralDark)
                    Text(task.specialNotes)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(PetTheme.apricot.opacity(0.2), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct AcceptedTaskConfirmationView: View {
    let task: GroomingTask
    let pet: Pet
    let groomer: Groomer?
    let onCreateNewTask: () -> Void

    @State private var showTitle = false
    @State private var showCard = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Congratulations")
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : -12)

                Text(acceptedMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : -8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)

            GroomingTaskCard(
                task: task,
                pet: pet,
                recommendedCount: 0,
                onRewrite: {},
                statusLabel: "Accepted",
                showsActions: false
            )
            .padding(.horizontal, 18)
            .scaleEffect(showCard ? 1 : 0.96)
            .opacity(showCard ? 1 : 0)

            Button(action: onCreateNewTask) {
                Label("Create New Task Card", systemImage: "plus.circle.fill")
            }
            .buttonStyle(CoralButtonStyle())
            .padding(.horizontal, 18)
            .opacity(showCard ? 1 : 0)
            .offset(y: showCard ? 0 : 10)
        }
        .onAppear {
            showTitle = false
            showCard = false
            withAnimation(.smooth(duration: 0.48)) {
                showTitle = true
            }
            withAnimation(.spring(response: 0.46, dampingFraction: 0.86).delay(0.22)) {
                showCard = true
            }
        }
    }

    private var acceptedMessage: String {
        if let groomer {
            "Your task card has been accepted by \(groomer.name)."
        } else {
            "Your task card has been accepted."
        }
    }
}

struct StyleReferenceImageButton: View {
    @State private var showPreview = false

    let slot: GroomingTaskReferenceImageSlot
    var onPreview: (() -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            referenceButton
                .overlay(alignment: .topLeading) {
                    if showPreview {
                        let origin = proxy.frame(in: .global).origin

                        StyleReferencePreviewOverlay(slot: slot) {
                            withAnimation(.smooth(duration: 0.18)) {
                                showPreview = false
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .offset(x: -origin.x, y: -origin.y)
                        .zIndex(500)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
        }
        .frame(width: 82, height: 58)
    }

    private var referenceButton: some View {
        Button {
            if slot.hasImage {
                if let onPreview {
                    onPreview()
                } else {
                    withAnimation(.smooth(duration: 0.2)) {
                        showPreview = true
                    }
                }
            }
        } label: {
            ZStack {
                if let data = slot.thumbnailDisplayData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 82, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack {
                        Spacer()
                        Text("Reference")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.28), in: Capsule())
                            .padding(5)
                    }
                } else {
                    VStack(spacing: 5) {
                        Image(systemName: "photo")
                            .font(.headline.weight(.semibold))
                        Text("No photo")
                            .font(.caption2.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundStyle(PetTheme.muted)
                }
            }
            .frame(width: 82, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(slot.hasImage ? PetTheme.apricot.opacity(0.34) : Color.gray.opacity(0.11))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(slot.hasImage ? PetTheme.coral.opacity(0.25) : Color.gray.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!slot.hasImage)
    }
}

struct StyleReferencePreviewOverlay: View {
    @State private var showSaveAlert = false
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""

    let slot: GroomingTaskReferenceImageSlot
    let onDismiss: () -> Void

    private let cardWidth: CGFloat = 330
    private let horizontalPadding: CGFloat = 14

    var body: some View {
        ZStack {
            Color.black.opacity(0.26)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            let imageWidth = cardWidth - horizontalPadding * 2
            let imageHeight = previewImage.map { previewHeight(for: $0, width: imageWidth) } ?? 320

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Style reference")
                        .font(.headline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.muted)
                            .frame(width: 30, height: 30)
                            .background(PetTheme.porcelain, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close style reference preview")
                }

                Group {
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        EmptyState(title: "No image", message: "This task card does not include a style reference photo.", systemImage: "photo")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .background(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    saveToPhotoLibrary()
                } label: {
                    Label("保存到相册", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(CoralButtonStyle())
                .disabled(previewImage == nil)
            }
            .padding(horizontalPadding)
            .frame(width: cardWidth)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 22, x: 0, y: 12)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .alert(saveAlertTitle, isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if !saveAlertMessage.isEmpty {
                Text(saveAlertMessage)
            }
        }
    }

    private var previewImage: UIImage? {
        guard let data = slot.previewDisplayData else { return nil }
        return UIImage(data: data)
    }

    private func previewHeight(for image: UIImage, width: CGFloat) -> CGFloat {
        guard image.size.width > 0, image.size.height > 0 else { return 320 }
        let fittedHeight = width * image.size.height / image.size.width
        return min(fittedHeight, width * 2)
    }

    private func saveToPhotoLibrary() {
        guard let image = previewImage else {
            presentSaveAlert(title: "No image", message: "This task card does not include a style reference photo.")
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                presentSaveAlert(title: "Photo Access Needed", message: "Allow photo library access in Settings to save this image.")
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    presentSaveAlert(title: "Saved", message: "The style reference photo was saved to your album.")
                } else {
                    presentSaveAlert(title: "Save Failed", message: error?.localizedDescription ?? "Please try again.")
                }
            }
        }
    }

    private func presentSaveAlert(title: String, message: String) {
        DispatchQueue.main.async {
            saveAlertTitle = title
            saveAlertMessage = message
            showSaveAlert = true
        }
    }
}

struct GroomingTaskFact: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: iconName)
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
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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
                    ManualAddressEntryView(initialAddress: manualAddress) { address, _ in
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
            .navigationTitle("Task start")
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
                    title: "Home Address",
                    subtitle: savedAddress.isEmpty ? "Add a home address from Account first" : savedAddress.compactTitle,
                    icon: "house.fill",
                    isSelected: selectedSource == .savedProfileAddress
                ) {
                    guard !savedAddress.isEmpty else { return }
                    selectedSource = .savedProfileAddress
                    dismiss()
                }
                .opacity(savedAddress.isEmpty ? 0.55 : 1)

                addressOption(
                    title: manualAddress.isEmpty ? "Enter a New Address" : "New Address",
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
    @State private var shouldUpdateHomeAddress = false

    var showsHomeAddressToggle = true
    let onSave: (ProfileAddress, Bool) -> Void
    let onCancel: () -> Void

    init(initialAddress: ProfileAddress, showsHomeAddressToggle: Bool = true, onSave: @escaping (ProfileAddress, Bool) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: initialAddress.isEmpty ? .empty : initialAddress)
        self.showsHomeAddressToggle = showsHomeAddressToggle
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Add New Address")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(PetTheme.ink)
                        Text("Search first, then confirm the standard address fields.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PetTheme.muted)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address search")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.muted)
                        LimitedTextField("Street address, city, ZIP", text: $completer.query, limit: 120)
                            .textInputAutocapitalization(.words)
                            .padding(12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(PetTheme.line.opacity(0.48), lineWidth: 1)
                            )

                        if isResolvingSuggestion {
                            Label("Loading address details", systemImage: "location.magnifyingglass")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PetTheme.muted)
                        }

                        if !completer.results.isEmpty {
                            VStack(spacing: 7) {
                                ForEach(Array(completer.results.prefix(4).enumerated()), id: \.offset) { _, result in
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
                                        .padding(10)
                                        .background(PetTheme.cream.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .taskCard()

                    VStack(spacing: 10) {
                        addressTextField("Address line 1", text: $draft.streetLine1)
                        addressTextField("Address line 2", text: $draft.streetLine2)
                        addressTextField("City", text: $draft.city)

                        HStack(spacing: 10) {
                            statePicker
                            addressTextField("ZIP code", text: $draft.postalCode)
                                .keyboardType(.numbersAndPunctuation)
                        }
                    }
                    .taskCard()

                    if showsHomeAddressToggle {
                        Button {
                            shouldUpdateHomeAddress.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: shouldUpdateHomeAddress ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(shouldUpdateHomeAddress ? PetTheme.coral : PetTheme.muted)
                                Text("Update existing home address")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(PetTheme.ink)
                                Spacer()
                            }
                            .padding(12)
                            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        onSave(cleaned(draft), shouldUpdateHomeAddress)
                    } label: {
                        Label("Add Address", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CoralButtonStyle())
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.55)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .appBackground()
            .navigationTitle("Add New Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }

    private func addressTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            LimitedTextField(title, text: text, limit: addressLimit(for: title))
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PetTheme.line.opacity(0.48), lineWidth: 1)
                )
        }
    }

    private var statePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("State")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            Picker("State", selection: $draft.state) {
                Text("State").tag("")
                ForEach(usStates, id: \.self) { state in
                    Text(state).tag(state)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.48), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func addressLimit(for title: String) -> Int {
        switch title {
        case "Address line 1": 80
        case "Address line 2": 60
        case "City": 50
        case "ZIP code": 12
        default: 80
        }
    }

    private func cleaned(_ address: ProfileAddress) -> ProfileAddress {
        ProfileAddress(
            streetLine1: address.streetLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            streetLine2: address.streetLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: address.city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: address.state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            postalCode: address.postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: "United States"
        )
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
                        country: "United States"
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

    private var usStates: [String] {
        ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY", "DC"]
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

final class CurrentLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentAddress: ProfileAddress?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            DispatchQueue.main.async {
                self?.currentAddress = ProfileAddress(
                    streetLine1: [placemark.subThoroughfare, placemark.thoroughfare].compactMap { $0 }.joined(separator: " "),
                    streetLine2: "",
                    city: placemark.locality ?? "",
                    state: placemark.administrativeArea ?? "",
                    postalCode: placemark.postalCode ?? "",
                    country: placemark.country ?? "United States"
                )
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentAddress = nil
    }
}

struct SearchView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var savedOnly = false
    @State private var selectedGroomerForDetails: Groomer?
    @State private var showMissingTaskCardAlert = false

    private var results: [Groomer] {
        let groomers = model.filteredGroomers(query: query, city: "All", verifiedOnly: false, acceptsCatsOnly: false)
        guard savedOnly else { return groomers }
        return groomers.filter { model.isFavorite(targetType: .groomer, targetID: $0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 13) {
                searchHeader

                searchFilterCard

                if results.isEmpty {
                    EmptyState(
                        title: savedOnly ? "No saved groomers match" : "No groomers match",
                        message: savedOnly ? "Turn off saved-only or save more groomers from the list." : "Try a name, city, style, or specialty.",
                        systemImage: savedOnly ? "heart" : "magnifyingglass"
                    )
                } else {
                    VStack(spacing: 14) {
                        ForEach(results) { groomer in
                            let mismatchReasons = taskMismatchReasons(for: groomer)
                            GroomerCard(
                                groomer: groomer,
                                portfolio: model.portfolio(for: groomer),
                                isSaved: model.isFavorite(targetType: .groomer, targetID: groomer.id),
                                onSave: { model.toggleFavorite(targetType: .groomer, targetID: groomer.id) },
                                onContact: { sendOrAskForTaskCard(to: groomer) },
                                contactTitle: contactTitle(for: groomer),
                                contactIcon: contactIcon(for: groomer),
                                isContactDisabled: contactIsDisabled(for: groomer),
                                contactMismatchReasons: mismatchReasons,
                                secondaryTitle: "Details",
                                secondaryIcon: "person.text.rectangle",
                                onSecondaryAction: { selectedGroomerForDetails = groomer }
                            )
                            .padding(.horizontal, 18)
                        }
                    }
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .navigationDestination(item: $selectedGroomerForDetails) { groomer in
            GroomerProfileView(groomer: groomer)
        }
        .alert("No task card yet", isPresented: $showMissingTaskCardAlert) {
            Button("Create Now") {
                model.shouldReturnToSearchAfterTaskCreation = true
                model.selectedAppTab = "home"
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Create this visit’s task card first, then send it to a groomer from Search.")
        }
        .customerChatToolbar()
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search groomers")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PetTheme.ink)

            Text(model.currentGroomingTask == nil ? "Create a task card first, then send it from any profile." : "Browse profiles and send your current task card.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PetTheme.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [PetTheme.porcelain, PetTheme.apricot.opacity(0.44)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.045), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.78), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var searchFilterCard: some View {
        VStack(spacing: 9) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(PetTheme.coral)
                    .frame(width: 24, height: 24)
                    .background(PetTheme.apricot.opacity(0.28), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                LimitedTextField("Breed, style, city, specialty", text: $query, limit: 80)
                    .font(.subheadline.weight(.semibold))
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(PetTheme.muted.opacity(0.72))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
            )

            Button {
                withAnimation(.smooth(duration: 0.22)) {
                    savedOnly.toggle()
                }
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: savedOnly ? "heart.fill" : "heart")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(savedOnly ? .white : PetTheme.coral)
                        .frame(width: 24, height: 24)
                        .background(savedOnly ? PetTheme.coral : PetTheme.apricot.opacity(0.28), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    Text("Saved groomers only")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PetTheme.ink)
                    Spacer()
                    Text(savedOnly ? "On" : "Off")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(savedOnly ? PetTheme.coralDark : PetTheme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(savedOnly ? PetTheme.apricot.opacity(0.22) : .white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(savedOnly ? PetTheme.coral.opacity(0.26) : PetTheme.line.opacity(0.36), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(PetTheme.porcelain, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.72), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    private func sendOrAskForTaskCard(to groomer: Groomer) {
        guard let task = model.currentGroomingTask else {
            showMissingTaskCardAlert = true
            return
        }

        if let pendingSubmission = model.pendingTaskSubmission(for: task, groomer: groomer) {
            model.revokeTaskSubmission(id: pendingSubmission.id)
        } else {
            model.sendCurrentTask(to: groomer)
        }
    }

    private func contactTitle(for groomer: Groomer) -> String {
        guard let task = model.currentGroomingTask else { return "Send Card" }
        if !model.taskMismatchReasons(for: task, groomer: groomer).isEmpty {
            return "Unavailable"
        }
        if let pendingSubmission = model.pendingTaskSubmission(for: task, groomer: groomer), pendingSubmission.status == .sent {
            return "Revoke"
        }
        if let submission = model.taskSubmission(for: task, groomer: groomer), submission.status == .accepted {
            return "Accepted"
        }
        return "Send Card"
    }

    private func contactIcon(for groomer: Groomer) -> String {
        guard let task = model.currentGroomingTask else { return "paperplane.fill" }
        if !model.taskMismatchReasons(for: task, groomer: groomer).isEmpty {
            return "slash.circle.fill"
        }
        if model.pendingTaskSubmission(for: task, groomer: groomer) != nil {
            return "arrow.uturn.backward.circle.fill"
        }
        if let submission = model.taskSubmission(for: task, groomer: groomer), submission.status == .accepted {
            return "checkmark.seal.fill"
        }
        return "paperplane.fill"
    }

    private func contactIsDisabled(for groomer: Groomer) -> Bool {
        guard let task = model.currentGroomingTask else {
            return false
        }
        if !model.taskMismatchReasons(for: task, groomer: groomer).isEmpty {
            return true
        }
        guard let submission = model.taskSubmission(for: task, groomer: groomer) else {
            return false
        }
        return submission.status == .accepted || submission.status == .completed
    }

    private func taskMismatchReasons(for groomer: Groomer) -> [String] {
        guard let task = model.currentGroomingTask else { return [] }
        return model.taskMismatchReasons(for: task, groomer: groomer)
    }
}

struct SavedView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Saved", subtitle: "Keep groomers and portfolio looks for later.")

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
        .customerChatToolbar()
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
                ScreenTitle(title: "Orders", subtitle: "Track sent task cards and groomer replies.")

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
        .customerChatToolbar()
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
                    ScreenTitle(title: "Order details", subtitle: "Review the task, groomer, status, and chat.")

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
        .customerChatToolbar()
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
                ScreenTitle(title: "Account", subtitle: "Manage your profile, role, and app settings.")

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
                    Label("Payments, calendar booking, and live chat are not enabled", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }
                .taskCard()
                .padding(.horizontal, 18)

                SectionHeader(title: "Personal information")
                VStack(alignment: .leading, spacing: 12) {
                    profileRow("Name", value: model.customerPersonalProfile.fullName, icon: "person.fill")
                    profileRow("Gender", value: model.customerPersonalProfile.gender.rawValue, icon: "person.text.rectangle")
                    profileRow("Home address", value: model.customerPersonalProfile.address.formattedAddress, icon: "house.fill")
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
        .roleAwareChatToolbar()
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
    @State private var showHomeAddressEditor = false

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

                    SectionHeader(title: "Home address")
                    VStack(alignment: .leading, spacing: 10) {
                        if !draft.address.isEmpty {
                            Text(draft.address.formattedAddress)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PetTheme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            showHomeAddressEditor = true
                        } label: {
                            Label(draft.address.isEmpty ? "Add Address" : "Update Address", systemImage: draft.address.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuietButtonStyle())
                    }
                    .taskCard()

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
        .sheet(isPresented: $showHomeAddressEditor) {
            ManualAddressEntryView(initialAddress: draft.address, showsHomeAddressToggle: false) { address, _ in
                draft.address = address
                showHomeAddressEditor = false
            } onCancel: {
                showHomeAddressEditor = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func profileTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            LimitedTextField(title, text: text, limit: profileLimit(for: title))
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func profileLimit(for title: String) -> Int {
        switch title {
        case "Name": 60
        case "Phone": 24
        case "Email": 120
        default: 80
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
            country: "United States"
        )
        return cleanedProfile
    }
}
