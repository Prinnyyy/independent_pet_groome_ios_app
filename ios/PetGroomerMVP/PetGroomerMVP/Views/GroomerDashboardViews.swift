import PhotosUI
import SwiftUI
import UIKit

struct GroomerTodayView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let groomer = model.managedGroomer {
                    ScreenTitle(
                        title: "Today",
                        subtitle: "Review today’s work and recent task activity."
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
        .groomerChatToolbar()
    }
}

struct MyGroomerProfileView: View {
    @EnvironmentObject private var model: AppModel
    @State private var draft: Groomer?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "My profile", subtitle: "Edit the public card pet owners see.")

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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Service location")
                                .font(.headline.weight(.semibold))
                                .fontDesign(.rounded)

                            numberField("House-call radius (mi)", value: bindingDouble(\.mobileServiceRadiusMiles))

                            Text("Studio address is optional. Adding it enables customer drop-off tasks.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PetTheme.muted)

                            TextField("Studio street", text: studioAddressBinding(\.streetLine1))
                                .textFieldStyle(.roundedBorder)
                            TextField("Suite / unit", text: studioAddressBinding(\.streetLine2))
                                .textFieldStyle(.roundedBorder)
                            HStack(spacing: 10) {
                                TextField("City", text: studioAddressBinding(\.city))
                                    .textFieldStyle(.roundedBorder)
                                TextField("State", text: studioAddressBinding(\.state))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 76)
                            }
                            TextField("ZIP code", text: studioAddressBinding(\.postalCode))
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
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

    private func studioAddressBinding(_ keyPath: WritableKeyPath<ProfileAddress, String>) -> Binding<String> {
        Binding(
            get: { draft?.studioAddress?[keyPath: keyPath] ?? "" },
            set: { value in
                var address = draft?.studioAddress ?? ProfileAddress(
                    streetLine1: "",
                    streetLine2: "",
                    city: draft?.city ?? "",
                    state: "CA",
                    postalCode: draft?.zipCode ?? "",
                    country: "United States"
                )
                address[keyPath: keyPath] = value
                let requiredFieldsAreEmpty = address.streetLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    address.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    address.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    address.postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                draft?.studioAddress = requiredFieldsAreEmpty ? nil : address
            }
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
                ScreenTitle(title: "Inbox", subtitle: "Review new task cards from pet owners.")

                if let groomer = model.managedGroomer {
                    let taskSubmissions = model.taskSubmissions(for: groomer)
                    if taskSubmissions.isEmpty {
                        EmptyState(title: "No task cards yet", message: "Pet owners can send task cards from your profile.", systemImage: "tray")
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
                } else {
                    EmptyState(title: "No groomer profile", message: "No inbox is available for this demo user.", systemImage: "tray")
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .groomerChatToolbar()
    }
}

struct GroomerScheduleView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedDate = Date()

    private var calendar = Calendar.current

    private var selectedMonthTitle: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(firstIndex + $0) % 7] }
    }

    private var visibleDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return []
        }

        let firstDay = calendar.startOfDay(for: monthInterval.start)
        let leadingDays = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstDay) ?? firstDay
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(
                    title: "Schedule",
                    subtitle: "Manage accepted task cards by date and time."
                )

                if let groomer = model.managedGroomer {
                    let scheduledSubmissions = model.scheduledTaskSubmissions(for: groomer)
                    let selectedSubmissions = model.scheduledTaskSubmissions(for: groomer, on: selectedDate)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button {
                                moveMonth(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                            Text(selectedMonthTitle)
                                .font(.headline.weight(.semibold))
                                .fontDesign(.rounded)
                                .foregroundStyle(PetTheme.ink)
                            Spacer()

                            Button {
                                moveMonth(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundStyle(PetTheme.coralDark)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                            ForEach(weekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(PetTheme.muted)
                                    .frame(maxWidth: .infinity)
                            }

                            ForEach(visibleDays, id: \.self) { day in
                                ScheduleCalendarDayCell(
                                    date: day,
                                    taskCount: taskCount(on: day, in: scheduledSubmissions),
                                    isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                                    isCurrentMonth: calendar.isDate(day, equalTo: selectedDate, toGranularity: .month)
                                ) {
                                    selectedDate = day
                                }
                            }
                        }
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    SectionHeader(title: selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    ScheduleDayTimelineView(date: selectedDate, submissions: selectedSubmissions)
                } else {
                    EmptyState(title: "No groomer profile", message: "No schedule is available for this demo user.", systemImage: "calendar")
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .groomerChatToolbar()
    }

    private func taskCount(on date: Date, in submissions: [GroomingTaskSubmission]) -> Int {
        submissions.filter { calendar.isDate($0.taskSnapshot.targetDate, inSameDayAs: date) }.count
    }

    private func moveMonth(by value: Int) {
        selectedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? selectedDate
    }
}

struct ScheduleCalendarDayCell: View {
    let date: Date
    let taskCount: Int
    let isSelected: Bool
    let isCurrentMonth: Bool
    let action: () -> Void

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : isCurrentMonth ? PetTheme.ink : PetTheme.muted.opacity(0.58))

                if taskCount > 0 {
                    Text("\(taskCount) card\(taskCount == 1 ? "" : "s")")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isSelected ? .white.opacity(0.92) : PetTheme.sage)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                } else {
                    Text("Open")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.62) : PetTheme.muted.opacity(0.38))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? PetTheme.coral : isCurrentMonth ? .white.opacity(0.86) : Color.white.opacity(0.38))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(taskCount > 0 && !isSelected ? PetTheme.sage.opacity(0.45) : PetTheme.line.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ScheduleDayTimelineView: View {
    let date: Date
    let submissions: [GroomingTaskSubmission]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 0) {
                ForEach(GroomingTaskTimeWindow.allCases) { timeWindow in
                    ScheduleTimeSlotRow(
                        timeWindow: timeWindow,
                        submissions: submissions.filter { $0.taskSnapshot.timeWindow == timeWindow }
                    )

                    if timeWindow != GroomingTaskTimeWindow.allCases.last {
                        Divider()
                    }
                }
            }
            .taskCard()
            .padding(.horizontal, 18)

            if submissions.isEmpty {
                Text("No accepted task cards on this date.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetTheme.muted)
                    .padding(.horizontal, 18)
            }
        }
    }
}

struct ScheduleTimeSlotRow: View {
    let timeWindow: GroomingTaskTimeWindow
    let submissions: [GroomingTaskSubmission]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(timeWindow.displayTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
                .frame(width: 82, alignment: .leading)
                .padding(.top, 8)

            if submissions.isEmpty {
                Text("Open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetTheme.muted.opacity(0.58))
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                    .padding(.top, 8)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(submissions) { submission in
                        NavigationLink {
                            ScheduledTaskDetailView(submissionID: submission.id)
                        } label: {
                            ScheduledTaskTile(submission: submission)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
    }
}

struct ScheduledTaskTile: View {
    let submission: GroomingTaskSubmission

    private var task: GroomingTask {
        submission.taskSnapshot
    }

    private var isCompletedByDate: Bool {
        task.targetDate < Calendar.current.startOfDay(for: Date()) && submission.status == .accepted
    }

    private var isInactive: Bool {
        isCompletedByDate || submission.status == .completed || submission.status == .cancelled
    }

    private var displayStatus: String {
        if isCompletedByDate {
            return "Completed"
        }
        return submission.status.label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(task.petSnapshot.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(isInactive ? PetTheme.muted : PetTheme.ink)
                .strikethrough(isInactive, color: PetTheme.muted)
                .lineLimit(1)

            Text(task.service.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isInactive ? PetTheme.muted.opacity(0.72) : PetTheme.coralDark)
                .strikethrough(isInactive, color: PetTheme.muted)
                .lineLimit(1)

            Text(displayStatus)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isInactive ? PetTheme.muted : PetTheme.sage)
                .lineLimit(1)
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isInactive ? Color.gray.opacity(0.16) : PetTheme.apricot.opacity(0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isInactive ? Color.gray.opacity(0.24) : PetTheme.coral.opacity(0.4), lineWidth: 1)
        )
    }
}

struct ScheduledTaskDetailView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showChat = false
    @State private var showPetCard = false
    @State private var contactCopyTarget: ContactCopyTarget?

    let submissionID: UUID

    private var submission: GroomingTaskSubmission? {
        model.taskSubmission(id: submissionID)
    }

    var body: some View {
        ScrollView {
            if let submission {
                let task = submission.taskSnapshot
                let isPastCompleted = task.targetDate < Calendar.current.startOfDay(for: Date()) && submission.status == .accepted
                let canCancel = submission.status == .accepted && !isPastCompleted
                let canMessage = submission.status != .cancelled

                VStack(spacing: 16) {
                    ScreenTitle(
                        title: "Scheduled task",
                        subtitle: "Review the task, cancel if needed, or message the owner."
                    )

                    VStack(alignment: .leading, spacing: 13) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.service.rawValue)
                                    .font(.title2.weight(.bold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(PetTheme.ink)
                                Text("\(task.petSnapshot.name) · \(task.timeWindow.displayTitle)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PetTheme.muted)
                            }
                            Spacer()
                            Chip(text: isPastCompleted ? "Completed" : submission.status.label, color: scheduleStatusColor(submission, isPastCompleted: isPastCompleted))
                        }

                        detailRow("Appointment", value: "\(task.targetDate.formatted(date: .abbreviated, time: .omitted)) · \(task.timeWindow.displayTitle)", icon: "calendar")
                        detailRow("Grooming place", value: task.serviceLocation.shortTitle, icon: task.serviceLocation.iconName)
                        detailRow("Address", value: task.searchArea.locationTitle, icon: task.searchArea.addressSource.iconName)
                        if let package = model.petProfilePackage(for: task.petProfileLink) {
                            Button {
                                showPetCard = true
                            } label: {
                                petCardAccessButton(package: package)
                            }
                            .buttonStyle(.plain)
                        } else {
                            detailRow("Pet card", value: petDetail(task.petSnapshot), icon: "pawprint.fill")
                        }
                        styleGoalRow(task)
                        detailRow("Special note", value: task.specialNotes.isEmpty ? "None" : task.specialNotes, icon: "exclamationmark.bubble")
                        contactRows
                        detailRow("Task ID", value: task.sequenceCode, icon: "number")
                        detailRow("Owner score", value: "\(task.ownerHiddenScore.displayValue) · \(task.ownerHiddenScore.source)", icon: "lock.shield")
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    HStack(spacing: 10) {
                        Button(role: .destructive) {
                            model.cancelTaskSubmission(id: submission.id)
                        } label: {
                            Label("Cancel Task", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .disabled(!canCancel)
                        .opacity(canCancel ? 1 : 0.55)

                        Button {
                            showChat = true
                        } label: {
                            Label("Message Owner", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        .buttonStyle(CoralButtonStyle())
                        .disabled(!canMessage)
                        .opacity(canMessage ? 1 : 0.55)
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 28)
                .sheet(isPresented: $showChat) {
                    NavigationStack {
                        TaskChatView(submissionID: submission.id, senderRole: .groomer)
                            .environmentObject(model)
                    }
                }
                .fullScreenCover(isPresented: $showPetCard) {
                    if let package = model.petProfilePackage(for: submission.taskSnapshot.petProfileLink) {
                        ZStack {
                            Color.black.opacity(0.26)
                                .ignoresSafeArea()
                                .onTapGesture { showPetCard = false }
                            ReadOnlyPetCardOverlayView(package: package) {
                                showPetCard = false
                            }
                            .padding(.horizontal, 18)
                        }
                        .presentationBackground(.clear)
                    }
                }
                .alert(item: $contactCopyTarget) { target in
                    Alert(
                        title: Text(target.alertTitle),
                        message: Text(target.value),
                        primaryButton: .default(Text("Copy")) {
                            UIPasteboard.general.string = target.value
                        },
                        secondaryButton: .cancel()
                    )
                }
            } else {
                EmptyState(title: "Task not found", message: "This scheduled task card is no longer available.", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .appBackground()
        .navigationTitle("Scheduled task")
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

    private func styleGoalRow(_ task: GroomingTask) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "scissors")
                .foregroundStyle(PetTheme.sage)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 6) {
                Text("Style goal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                HStack(alignment: .top, spacing: 10) {
                    Text(task.styleGoal)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StyleReferenceImageButton(slot: task.referenceImageSlot)
                }
            }
        }
    }

    private var contactRows: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .foregroundStyle(PetTheme.sage)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 8) {
                Text("Customer contact")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                contactButton(title: "Phone", value: model.customerPersonalProfile.phone, icon: "phone.fill")
                contactButton(title: "Email", value: model.customerPersonalProfile.email, icon: "envelope.fill")
            }
        }
    }

    private func contactButton(title: String, value: String, icon: String) -> some View {
        Button {
            contactCopyTarget = ContactCopyTarget(title: title, value: value)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PetTheme.muted)
                    Text(value.isEmpty ? "Not provided" : value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }
            .padding(9)
            .background(PetTheme.cream.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(value.isEmpty)
        .opacity(value.isEmpty ? 0.58 : 1)
    }

    private func petCardAccessButton(package: PetProfilePackage) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .foregroundStyle(PetTheme.coral)
                .frame(width: 32, height: 32)
                .background(PetTheme.apricot.opacity(0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("Pet card")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text("\(package.petSnapshot.name) · \(package.petSnapshot.breed)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
        }
        .padding(10)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.5), lineWidth: 1)
        )
    }

    private struct ContactCopyTarget: Identifiable {
        let title: String
        let value: String

        var id: String { title }

        var alertTitle: String {
            "Copy \(title.lowercased())?"
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

    private func scheduleStatusColor(_ submission: GroomingTaskSubmission, isPastCompleted: Bool) -> Color {
        if isPastCompleted {
            return Color.gray.opacity(0.34)
        }

        return switch submission.status {
        case .accepted: PetTheme.mint
        case .completed, .cancelled: Color.gray.opacity(0.34)
        case .sent: PetTheme.apricot
        case .declined: Color.gray.opacity(0.34)
        }
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
        case .declined, .completed, .cancelled: Color.gray.opacity(0.34)
        }
    }

    private var textColor: Color {
        [.declined, .completed, .cancelled].contains(submission.status) ? PetTheme.muted : PetTheme.ink
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

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Label(task.referenceImageSlot.hasImage ? "Reference attached" : "No reference yet", systemImage: task.styleReferenceSource?.iconName ?? "photo")
                    Label("Owner score \(task.ownerHiddenScore.displayValue)", systemImage: "lock.shield")
                }
                Label("Inbox package saved", systemImage: "tray.and.arrow.down.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle([.declined, .completed, .cancelled].contains(submission.status) ? PetTheme.muted : PetTheme.sage)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill([.declined, .completed, .cancelled].contains(submission.status) ? Color.gray.opacity(0.14) : PetTheme.porcelain)
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
        .opacity([.declined, .completed, .cancelled].contains(submission.status) ? 0.72 : 1)
    }
}

struct PetProfileAccessRow: View {
    let link: CardAccessLink
    let photoCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .foregroundStyle(PetTheme.sage)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text("Pet card")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text("Open full pet card package")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                Text("\(photoCount) photos · \(link.compactURL)")
                    .font(.caption)
                    .foregroundStyle(PetTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
        }
        .contentShape(Rectangle())
    }
}

struct GroomingTaskSubmissionDetailView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showChat = false
    @State private var showPetCard = false
    @State private var contactCopyTarget: ContactCopyTarget?

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
                        title: "Incoming task",
                        subtitle: "Review the card, open the pet card, and reply to the owner."
                    )

                    taskSummaryCard(task, submission: submission)

                    petCardSection(task)

                    visitPlanSection(task)

                    styleRequestSection(task)

                    contactSection

                    internalInfoSection(task)

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
                    NavigationStack {
                        TaskChatView(submissionID: submission.id, senderRole: .groomer)
                            .environmentObject(model)
                    }
                }
                .fullScreenCover(isPresented: $showPetCard) {
                    if let package = model.petProfilePackage(for: submission.taskSnapshot.petProfileLink) {
                        ZStack {
                            Color.black.opacity(0.26)
                                .ignoresSafeArea()
                                .onTapGesture { showPetCard = false }
                            ReadOnlyPetCardOverlayView(package: package) {
                                showPetCard = false
                            }
                            .padding(.horizontal, 18)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                        .presentationBackground(.clear)
                    }
                }
                .alert(item: $contactCopyTarget) { target in
                    Alert(
                        title: Text(target.alertTitle),
                        message: Text(target.value),
                        primaryButton: .default(Text("Copy")) {
                            UIPasteboard.general.string = target.value
                        },
                        secondaryButton: .cancel()
                    )
                }
            } else {
                EmptyState(title: "Task not found", message: "This task card is no longer available.", systemImage: "tray")
            }
        }
        .appBackground()
        .navigationTitle("Task details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func taskSummaryCard(_ task: GroomingTask, submission: GroomingTaskSubmission) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: serviceIconName(for: task.service))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(PetTheme.coral, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.service.rawValue)
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(2)
                    Text("For \(task.petSnapshot.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }

                Spacer(minLength: 0)

                Chip(text: submission.status.label, color: statusChipColor(submission.status))
            }

            HStack(spacing: 9) {
                summaryPill(icon: "calendar", text: task.targetDate.formatted(date: .abbreviated, time: .omitted))
                summaryPill(icon: "clock", text: task.timeWindow.displayTitle)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.28)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.055), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.76), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }

    private func summaryPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.bold))
            .foregroundStyle(PetTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.45), lineWidth: 1)
            )
    }

    private func serviceIconName(for service: GroomingTaskService) -> String {
        switch service {
        case .bath: "drop.fill"
        case .fullGroom: "sparkles"
        case .haircut, .faceTrim, .sanitaryTrim: "scissors"
        case .nailTrim: "pawprint.fill"
        case .dematting: "comb.fill"
        case .catGrooming: "cat.fill"
        }
    }

    private func petCardSection(_ task: GroomingTask) -> some View {
        detailSection(title: "Pet card", icon: "pawprint.fill") {
            if let package = model.petProfilePackage(for: task.petProfileLink) {
                Button {
                    showPetCard = true
                } label: {
                    petCardAccessButton(package: package)
                }
                .buttonStyle(.plain)
            } else {
                fallbackPetCard(task.petSnapshot)
            }
        }
    }

    private func visitPlanSection(_ task: GroomingTask) -> some View {
        detailSection(title: "Visit plan", icon: "calendar.badge.clock") {
            HStack(spacing: 10) {
                compactInfoTile(
                    title: "Appointment",
                    value: "\(task.targetDate.formatted(date: .abbreviated, time: .omitted))\n\(task.timeWindow.displayTitle)",
                    icon: "calendar"
                )
                compactInfoTile(
                    title: "Place",
                    value: task.serviceLocation.shortTitle,
                    icon: task.serviceLocation.iconName
                )
            }

            fullInfoRow(
                title: "Address",
                value: task.searchArea.locationTitle,
                icon: task.searchArea.addressSource.iconName
            )
        }
    }

    private func styleRequestSection(_ task: GroomingTask) -> some View {
        detailSection(title: "Style request", icon: "scissors") {
            HStack(alignment: .center, spacing: 10) {
                Text(task.styleGoal)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                StyleReferenceImageButton(slot: task.referenceImageSlot)
            }
            .padding(10)
            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.46), lineWidth: 1)
            )

            fullInfoRow(
                title: "Special note",
                value: task.specialNotes.isEmpty ? "None" : task.specialNotes,
                icon: "exclamationmark.bubble"
            )
        }
    }

    private var contactSection: some View {
        detailSection(title: "Customer contact", icon: "person.crop.circle.badge.questionmark") {
            contactButton(title: "Phone", value: model.customerPersonalProfile.phone, icon: "phone.fill")
            contactButton(title: "Email", value: model.customerPersonalProfile.email, icon: "envelope.fill")
        }
    }

    private func internalInfoSection(_ task: GroomingTask) -> some View {
        detailSection(title: "Internal info", icon: "lock.shield") {
            fullInfoRow(title: "Task ID", value: task.sequenceCode, icon: "number")
            fullInfoRow(
                title: "Owner score",
                value: "\(task.ownerHiddenScore.displayValue) · \(task.ownerHiddenScore.source)",
                icon: "lock.shield"
            )
        }
    }

    private func detailSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
            content()
        }
        .taskCard()
        .padding(.horizontal, 18)
    }

    private func compactInfoTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.coral)
                .frame(width: 26, height: 26)
                .background(PetTheme.apricot.opacity(0.32), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.46), lineWidth: 1)
        )
    }

    private func fullInfoRow(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.sage)
                .frame(width: 26, height: 26)
                .background(PetTheme.mint.opacity(0.26), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.36), lineWidth: 1)
        )
    }

    private func fallbackPetCard(_ pet: Pet) -> some View {
        fullInfoRow(title: pet.name, value: petDetail(pet), icon: "pawprint.fill")
    }

    private func contactButton(title: String, value: String, icon: String) -> some View {
        Button {
            contactCopyTarget = ContactCopyTarget(title: title, value: value)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.coral)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PetTheme.muted)
                    Text(value.isEmpty ? "Not provided" : value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }
            .padding(9)
            .background(PetTheme.cream.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(value.isEmpty)
        .opacity(value.isEmpty ? 0.58 : 1)
    }

    private func petCardAccessButton(package: PetProfilePackage) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "pawprint.fill")
                .foregroundStyle(PetTheme.coral)
                .frame(width: 32, height: 32)
                .background(PetTheme.apricot.opacity(0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("Pet card")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text("\(package.petSnapshot.name) · \(package.petSnapshot.breed)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
        }
        .padding(10)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.5), lineWidth: 1)
        )
    }

    private struct ContactCopyTarget: Identifiable {
        let title: String
        let value: String

        var id: String { title }

        var alertTitle: String {
            "Copy \(title.lowercased())?"
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
        case .declined, .completed, .cancelled: Color.gray.opacity(0.34)
        }
    }
}

struct ChatToolbarButton: View {
    let hasConversations: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
                    .foregroundStyle(PetTheme.coral)
                    .frame(width: 36, height: 36)

                if hasConversations {
                    Circle()
                        .fill(PetTheme.sage)
                        .frame(width: 9, height: 9)
                        .offset(x: -4, y: 5)
                }
            }
        }
        .accessibilityLabel("Open messages")
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

struct TaskChatInboxView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let viewerRole: AppRole

    private var conversations: [TaskChatConversation] {
        model.chatConversations(for: viewerRole)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if conversations.isEmpty {
                        EmptyState(
                            title: "No conversations yet",
                            message: "Task-card messages with customers or groomers will appear here.",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                    } else {
                        ForEach(conversations) { conversation in
                            NavigationLink {
                                TaskChatView(
                                    submissionID: conversation.id,
                                    senderRole: viewerRole,
                                    showsDoneButton: false
                                )
                                .environmentObject(model)
                            } label: {
                                ChatConversationRow(conversation: conversation)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 18)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .appBackground()
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ChatConversationRow: View {
    let conversation: TaskChatConversation

    private var initials: String {
        conversation.counterpartName
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }

    private var preview: String {
        guard let message = conversation.lastMessage else {
            return "Task card conversation ready"
        }

        if message.imageURL != nil && message.body.isEmpty {
            return "Photo"
        }
        if message.imageURL != nil {
            return "\(message.body) · Photo"
        }
        return message.body
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [PetTheme.apricot, PetTheme.mint, PetTheme.sky],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(initials.isEmpty ? "?" : initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PetTheme.ink)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.counterpartName)
                        .font(.headline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.lastActivityAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                }

                Text(conversation.counterpartSubtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetTheme.sage)
                    .lineLimit(1)

                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(PetTheme.muted)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted.opacity(0.72))
        }
        .taskCard()
    }
}

struct TaskChatView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    let submissionID: UUID
    let senderRole: AppRole
    var showsDoneButton = true

    private var messages: [TaskChatMessage] {
        model.messages(for: submissionID)
    }

    private var conversation: TaskChatConversation? {
        model.chatConversations(for: senderRole).first { $0.id == submissionID }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    if messages.isEmpty {
                        EmptyState(
                            title: "No messages yet",
                            message: "Send a text or photo to discuss timing, handling, style details, and price.",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .padding(.horizontal, 0)
                    } else {
                        ForEach(messages) { message in
                            chatBubble(message)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }

            Divider()

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 1, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundStyle(PetTheme.coral)
                        .frame(width: 42, height: 42)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(PetTheme.line.opacity(0.7), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Upload photo from album")

                LimitedTextField("Message", text: $draft, limit: 500, axis: .vertical)
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
            .padding(.vertical, 12)
            .background(PetTheme.cream)
        }
        .appBackground()
        .navigationTitle(conversation?.counterpartName ?? "Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: selectedPhotoItems.count) { _, count in
            guard count > 0 else { return }
            for _ in selectedPhotoItems {
                model.sendTaskImageMessage(submissionID: submissionID, senderRole: senderRole)
            }
            selectedPhotoItems.removeAll()
        }
    }

    private func chatBubble(_ message: TaskChatMessage) -> some View {
        let isOutgoing = message.senderRole == senderRole

        return HStack {
            if isOutgoing {
                Spacer(minLength: 44)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(message.senderName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isOutgoing ? .white.opacity(0.82) : PetTheme.muted)

                if message.imageURL != nil {
                    chatImagePreview(isOutgoing: isOutgoing)
                }

                if !message.body.isEmpty {
                    Text(message.body)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOutgoing ? .white : PetTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(11)
            .frame(maxWidth: 260, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isOutgoing ? PetTheme.coral : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isOutgoing ? Color.clear : PetTheme.line.opacity(0.65), lineWidth: 1)
            )

            if !isOutgoing {
                Spacer(minLength: 44)
            }
        }
    }

    private func chatImagePreview(isOutgoing: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isOutgoing ? [.white.opacity(0.22), .white.opacity(0.08)] : [PetTheme.sky.opacity(0.55), PetTheme.apricot.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                Image(systemName: "photo.fill")
                    .font(.title2)
                    .foregroundStyle(isOutgoing ? .white : PetTheme.sage)
                Text("Album photo")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isOutgoing ? .white.opacity(0.9) : PetTheme.ink)
            }
        }
        .frame(width: 190, height: 128)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isOutgoing ? .white.opacity(0.2) : PetTheme.line.opacity(0.55), lineWidth: 1)
        )
    }
}

struct GroomerPortfolioManagerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showAddPortfolio = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "My portfolio", subtitle: "Manage looks customers see on your public card.")

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
        .groomerChatToolbar()
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
            Label("\(task.searchArea.locationTitle) · \(task.searchArea.rangeTitle)", systemImage: "location.fill")
            Label(petDetails, systemImage: "pawprint.fill")
            Label(task.styleGoal, systemImage: "scissors")
            StyleReferenceImageButton(slot: task.referenceImageSlot)
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
