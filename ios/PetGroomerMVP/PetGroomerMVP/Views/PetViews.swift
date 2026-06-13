import PhotosUI
import SwiftUI
import UIKit

struct PetsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showNewPet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Pet profiles", subtitle: "Build reusable grooming cards with coat, behavior, health notes, and photos.")

                Button {
                    showNewPet = true
                } label: {
                    Label("Create pet profile", systemImage: "plus.circle.fill")
                }
                .buttonStyle(CoralButtonStyle())
                .padding(.horizontal, 18)

                if model.pets.isEmpty {
                    EmptyState(title: "No pets yet", message: "Create a profile before requesting quotes.", systemImage: "pawprint")
                } else {
                    ForEach(model.pets) { pet in
                        NavigationLink {
                            PetDetailView(petID: pet.id)
                        } label: {
                            PetTaskCard(pet: pet, photoCount: model.photos(for: pet).count)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)
                    }
                }
            }
            .padding(.bottom, 28)
        }
        .appBackground()
        .sheet(isPresented: $showNewPet) {
            PetEditorView(mode: .create)
                .environmentObject(model)
        }
    }
}

struct PetDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var name = ""
    @State private var species: PetSpecies = .dog
    @State private var breed = ""
    @State private var weightPounds = 15
    @State private var ageYears = 4
    @State private var sexOption: PetSexOption = .notSpecified
    @State private var temperamentText = ""
    @State private var healthNotes = ""
    @State private var showPhotoTypeMenu = false
    @State private var showReplacePhotoAlert = false
    @State private var showPhotoPicker = false
    @State private var pendingPhotoType: PetPhotoType?
    @State private var selectedPhotoItem: PhotosPickerItem?

    let petID: UUID

    private var pet: Pet? {
        model.pets.first { $0.id == petID }
    }

    var body: some View {
        Group {
            if let pet {
                ScrollView {
                    VStack(spacing: 0) {
                        PetProfilePhotoCarousel(photos: model.photos(for: pet), species: pet.species)

                        VStack(alignment: .leading, spacing: 18) {
                            profileTitle(for: pet)

                            if isEditing {
                                editableProfileFields
                            } else {
                                PetProfileDetailPanel(pet: pet, photoCount: model.photos(for: pet).count)
                            }

                            bottomActions(for: pet)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 30)
                    }
                }
                .appBackground()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if isEditing {
                            Button("Cancel") {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                                    populateDraft(from: pet)
                                    isEditing = false
                                }
                            }
                        }
                    }
                }
                .confirmationDialog("Add a pet photo", isPresented: $showPhotoTypeMenu, titleVisibility: .visible) {
                    ForEach(PetPhotoType.allCases) { type in
                        Button(type.rawValue) {
                            preparePhotoUpload(type: type, for: pet)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Choose the photo angle or purpose. Existing fixed-angle photos will be replaced.")
                }
                .alert(replacePhotoTitle, isPresented: $showReplacePhotoAlert) {
                    Button("Replace photo", role: .destructive) {
                        showPhotoPicker = true
                    }
                    Button("Cancel", role: .cancel) {
                        pendingPhotoType = nil
                    }
                } message: {
                    Text("This pet already has a \(pendingPhotoType?.rawValue.lowercased() ?? "selected") photo. Uploading a new one will replace it.")
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
                .onChange(of: selectedPhotoItem) { _, item in
                    loadSelectedPhoto(item, for: pet)
                }
                .onAppear {
                    populateDraft(from: pet)
                }
            } else {
                EmptyState(title: "Pet not found", message: "This profile may have been deleted.", systemImage: "exclamationmark.triangle")
            }
        }
    }

    @ViewBuilder
    private func profileTitle(for pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if isEditing {
                HStack(alignment: .center, spacing: 12) {
                    TextField("Pet name", text: $name)
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(PetTheme.ink)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 6)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(PetTheme.line)
                                .frame(height: 1)
                        }

                    Button {
                        showPhotoTypeMenu = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(PetTheme.coral)
                            .frame(width: 40, height: 40)
                    }
                    .background(PetTheme.apricot.opacity(0.34), in: Circle())
                    .accessibilityLabel("Add photo")
                }
            } else {
                Text(pet.name)
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
            }

            HStack(spacing: 8) {
                Chip(text: isEditing ? species.rawValue : pet.species.rawValue, color: PetTheme.mint)
                let weightValue = isEditing ? Double(weightPounds) : pet.weight
                if let weightValue {
                    Chip(text: "\(Int(weightValue)) lb", color: PetTheme.sky)
                }
                Chip(text: "\(model.photos(for: pet).count) photos", color: PetTheme.apricot)
            }
        }
    }

    private var editableProfileFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            PetEditFieldGroup(title: "Basics") {
                Picker("Species", selection: $species) {
                    ForEach(PetSpecies.allCases) { species in
                        Text(species.rawValue).tag(species)
                    }
                }
                .pickerStyle(.segmented)
                PetProfileMenuPicker(title: "Breed", value: $breed, options: breedOptions)
                PetProfileIntPicker(title: "Weight", value: $weightPounds, options: weightOptions, suffix: "lb")
                PetProfileIntPicker(title: "Age", value: $ageYears, options: ageOptions, suffix: "years")
                PetProfileEnumPicker(title: "Sex", value: $sexOption)
                PetProfileTextField(title: "Temperament tags", text: $temperamentText, axis: .vertical)
                PetProfileTextField(title: "Health notes", text: $healthNotes, axis: .vertical)
            }
        }
    }

    @ViewBuilder
    private func bottomActions(for pet: Pet) -> some View {
        VStack(spacing: 10) {
            if isEditing {
                Button {
                    saveDraft(original: pet)
                } label: {
                    Label("Save profile", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(CoralButtonStyle())

                Button(role: .destructive) {
                    model.deletePet(pet)
                    dismiss()
                } label: {
                    Label("Delete pet profile", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle())
            } else {
                Button {
                    populateDraft(from: pet)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        isEditing = true
                    }
                } label: {
                    Label("Edit profile", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(CoralButtonStyle())
            }
        }
    }

    private var replacePhotoTitle: String {
        "Replace \(pendingPhotoType?.rawValue ?? "photo")?"
    }

    private func populateDraft(from pet: Pet) {
        name = pet.name
        species = pet.species
        breed = pet.breed
        weightPounds = Int(pet.weight ?? 15)
        ageYears = Int(pet.age ?? 4)
        sexOption = PetSexOption(rawValue: pet.sex ?? "") ?? .notSpecified
        temperamentText = pet.temperament.joined(separator: ", ")
        healthNotes = pet.healthNotes ?? ""
    }

    private func saveDraft(original pet: Pet) {
        var updated = pet
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.species = species
        updated.breed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.weight = Double(weightPounds)
        updated.age = Double(ageYears)
        updated.sex = sexOption.profileValue
        updated.temperament = temperamentText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        updated.healthNotes = healthNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        model.updatePet(updated)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            isEditing = false
        }
    }

    private func preparePhotoUpload(type: PetPhotoType, for pet: Pet) {
        pendingPhotoType = type
        let shouldReplace = type != .other && model.photos(for: pet).contains { $0.photoType == type }
        if shouldReplace {
            showReplacePhotoAlert = true
        } else {
            showPhotoPicker = true
        }
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?, for pet: Pet) {
        guard let item, let pendingPhotoType else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run {
                _ = model.savePetPhoto(to: pet, type: pendingPhotoType, imageData: data)
                selectedPhotoItem = nil
                self.pendingPhotoType = nil
            }
        }
    }

    private var breedOptions: [String] {
        var options = PetProfileOptionSet.breeds(for: species)
        if !breed.isEmpty && !options.contains(breed) {
            options.insert(breed, at: 0)
        }
        return options
    }

    private var weightOptions: [Int] {
        PetProfileOptionSet.weightPounds
    }

    private var ageOptions: [Int] {
        PetProfileOptionSet.ageYears
    }
}

struct PetProfilePackageDetailView: View {
    let package: PetProfilePackage

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PetProfilePhotoCarousel(photos: package.photoSnapshots, species: package.petSnapshot.species)

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(package.petSnapshot.name)
                            .font(.largeTitle.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(PetTheme.ink)
                        HStack(spacing: 8) {
                            Chip(text: package.petSnapshot.species.rawValue, color: PetTheme.mint)
                            if let weight = package.petSnapshot.weight {
                                Chip(text: "\(Int(weight)) lb", color: PetTheme.sky)
                            }
                            Chip(text: "\(package.photoSnapshots.count) photos", color: PetTheme.apricot)
                        }
                    }

                    PetProfileDetailPanel(pet: package.petSnapshot, photoCount: package.photoSnapshots.count)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Server profile package", systemImage: "link")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.coralDark)
                        Text(package.serverProfileLink.compactURL)
                            .font(.caption)
                            .foregroundStyle(PetTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .taskCard()
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .appBackground()
        .navigationTitle("Pet profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PetProfilePhotoCarousel: View {
    let photos: [PetPhoto]
    let species: PetSpecies

    var body: some View {
        TabView {
            if photos.isEmpty {
                PetProfilePhotoPage(photo: nil, species: species)
            } else {
                ForEach(photos) { photo in
                    PetProfilePhotoPage(photo: photo, species: species)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
        .frame(height: 430)
        .background(PetTheme.apricot.opacity(0.25))
    }
}

private struct PetProfilePhotoPage: View {
    let photo: PetPhoto?
    let species: PetSpecies

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = photo?.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [PetTheme.apricot.opacity(0.78), PetTheme.mint.opacity(0.82), PetTheme.sky.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(spacing: 14) {
                    Image(systemName: species == .cat ? "cat.fill" : "dog.fill")
                        .font(.system(size: 74, weight: .semibold))
                    Text(photo == nil ? "Add profile photos" : "Local photo")
                        .font(.headline.weight(.semibold))
                        .fontDesign(.rounded)
                }
                .foregroundStyle(.white.opacity(0.94))
            }

            Text(photo?.photoType.rawValue ?? "No photo")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.82), in: Capsule())
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private struct PetProfileDetailPanel: View {
    let pet: Pet
    let photoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Chip(text: pet.species.rawValue, color: PetTheme.mint)
                Chip(text: pet.breed, color: PetTheme.sky)
            }

            VStack(spacing: 10) {
                PetProfileInfoRow(title: "About", value: aboutLine, icon: "pawprint.fill")
                PetProfileInfoRow(title: "Temperament", value: pet.temperament.isEmpty ? "Not set" : pet.temperament.joined(separator: " · "), icon: "heart.text.square.fill")
                PetProfileInfoRow(title: "Health notes", value: pet.healthNotes?.nilIfEmpty ?? "No special notes", icon: "cross.case.fill")
                PetProfileInfoRow(title: "Photo set", value: "\(photoCount) saved photos", icon: "photo.on.rectangle")
            }
        }
        .taskCard()
    }

    private var aboutLine: String {
        [
            pet.sex,
            pet.age.map { "\(Int($0)) years old" },
            pet.weight.map { "\(Int($0)) lb" }
        ]
        .compactMap { $0?.nilIfEmpty }
        .joined(separator: " · ")
        .nilIfEmpty ?? "Basics not set"
    }
}

private struct PetProfileInfoRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(PetTheme.coral)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct PetEditFieldGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
            content
        }
        .taskCard()
    }
}

private struct PetProfileTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            TextField(title, text: $text, axis: axis)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(PetTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PetTheme.line.opacity(0.85), lineWidth: 1)
                )
        }
    }
}

private struct PetProfileMenuPicker: View {
    let title: String
    @Binding var value: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            Picker(title, selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(PetTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.85), lineWidth: 1)
            )
        }
    }
}

private struct PetProfileIntPicker: View {
    let title: String
    @Binding var value: Int
    let options: [Int]
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            Picker(title, selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text("\(option) \(suffix)").tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(PetTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.85), lineWidth: 1)
            )
        }
    }
}

private struct PetProfileEnumPicker: View {
    let title: String
    @Binding var value: PetSexOption

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            Picker(title, selection: $value) {
                ForEach(PetSexOption.allCases) { option in
                    Text(option.displayTitle).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(PetTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.85), lineWidth: 1)
            )
        }
    }
}

private enum PetSexOption: String, CaseIterable, Identifiable {
    case notSpecified = "Not specified"
    case female = "Female"
    case male = "Male"
    case spayedFemale = "Spayed female"
    case neuteredMale = "Neutered male"

    var id: String { rawValue }
    var displayTitle: String { rawValue }

    var profileValue: String? {
        self == .notSpecified ? nil : rawValue
    }
}

private enum PetProfileOptionSet {
    static func breeds(for species: PetSpecies) -> [String] {
        switch species {
        case .dog:
            ["Maltipoo", "Poodle", "Goldendoodle", "Labradoodle", "Shih Tzu", "Yorkshire Terrier", "Bichon Frise", "Pomeranian", "Corgi", "French Bulldog", "Mixed breed"]
        case .cat:
            ["Domestic shorthair", "Domestic longhair", "Persian", "Maine Coon", "Ragdoll", "British shorthair", "Siamese", "Mixed breed"]
        }
    }

    static let weightPounds = Array(3...120)
    static let ageYears = Array(0...25)
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

enum PetEditorMode {
    case create
    case edit(Pet)
}

struct PetEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let mode: PetEditorMode
    @State private var name: String
    @State private var species: PetSpecies
    @State private var breed: String
    @State private var weightPounds: Int
    @State private var ageYears: Int
    @State private var sexOption: PetSexOption
    @State private var temperamentText: String
    @State private var healthNotes: String

    init(mode: PetEditorMode) {
        self.mode = mode
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _species = State(initialValue: .dog)
            _breed = State(initialValue: "Maltipoo")
            _weightPounds = State(initialValue: 15)
            _ageYears = State(initialValue: 4)
            _sexOption = State(initialValue: .notSpecified)
            _temperamentText = State(initialValue: "")
            _healthNotes = State(initialValue: "")
        case .edit(let pet):
            _name = State(initialValue: pet.name)
            _species = State(initialValue: pet.species)
            _breed = State(initialValue: pet.breed)
            _weightPounds = State(initialValue: Int(pet.weight ?? 15))
            _ageYears = State(initialValue: Int(pet.age ?? 4))
            _sexOption = State(initialValue: PetSexOption(rawValue: pet.sex ?? "") ?? .notSpecified)
            _temperamentText = State(initialValue: pet.temperament.joined(separator: ", "))
            _healthNotes = State(initialValue: pet.healthNotes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Pet name", text: $name)
                    Picker("Species", selection: $species) {
                        ForEach(PetSpecies.allCases) { species in
                            Text(species.rawValue).tag(species)
                        }
                    }
                    Picker("Breed", selection: $breed) {
                        ForEach(breedOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    Picker("Weight", selection: $weightPounds) {
                        ForEach(PetProfileOptionSet.weightPounds, id: \.self) { option in
                            Text("\(option) lb").tag(option)
                        }
                    }
                    Picker("Age", selection: $ageYears) {
                        ForEach(PetProfileOptionSet.ageYears, id: \.self) { option in
                            Text("\(option) years").tag(option)
                        }
                    }
                    Picker("Sex", selection: $sexOption) {
                        ForEach(PetSexOption.allCases) { option in
                            Text(option.displayTitle).tag(option)
                        }
                    }
                }

                Section("Profile notes") {
                    TextField("Temperament tags", text: $temperamentText, axis: .vertical)
                    TextField("Health notes", text: $healthNotes, axis: .vertical)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: species) { _, newSpecies in
                let options = PetProfileOptionSet.breeds(for: newSpecies)
                if !options.contains(breed), let first = options.first {
                    breed = first
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .create: "Create pet"
        case .edit: "Edit pet"
        }
    }

    private func save() {
        let temperament = temperamentText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        switch mode {
        case .create:
            model.addPet(
                name: name,
                species: species,
                breed: breed,
                weight: Double(weightPounds),
                age: Double(ageYears),
                sex: sexOption.profileValue,
                temperament: temperament,
                healthNotes: healthNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
        case .edit(let original):
            var updated = original
            updated.name = name
            updated.species = species
            updated.breed = breed
            updated.weight = Double(weightPounds)
            updated.age = Double(ageYears)
            updated.sex = sexOption.profileValue
            updated.temperament = temperament
            updated.healthNotes = healthNotes.isEmpty ? nil : healthNotes
            model.updatePet(updated)
        }
        dismiss()
    }

    private var breedOptions: [String] {
        var options = PetProfileOptionSet.breeds(for: species)
        if !breed.isEmpty && !options.contains(breed) {
            options.insert(breed, at: 0)
        }
        return options
    }
}
