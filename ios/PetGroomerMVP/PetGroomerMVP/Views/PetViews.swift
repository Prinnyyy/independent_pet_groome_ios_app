import PhotosUI
import SwiftUI

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
    @State private var showEditor = false
    @State private var selectedPhotoType: PetPhotoType = .front
    @State private var selectedItems: [PhotosPickerItem] = []

    let petID: UUID

    private var pet: Pet? {
        model.pets.first { $0.id == petID }
    }

    var body: some View {
        Group {
            if let pet {
                ScrollView {
                    VStack(spacing: 16) {
                        ScreenTitle(title: pet.name, subtitle: "\(pet.breed) · \(pet.coatType) · \(pet.coatCondition)")

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Chip(text: pet.species.rawValue, color: PetTheme.mint)
                                if let weight = pet.weight {
                                    Chip(text: "\(Int(weight)) lb")
                                }
                                Chip(text: "\(model.photos(for: pet).count)/8 photos", color: PetTheme.sky)
                            }
                            Text(pet.temperament.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundStyle(PetTheme.muted)
                            if let healthNotes = pet.healthNotes, !healthNotes.isEmpty {
                                Label(healthNotes, systemImage: "cross.case.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PetTheme.coralDark)
                            }
                        }
                        .taskCard()
                        .padding(.horizontal, 18)

                        SectionHeader(title: "Photos")
                        photoUploader(for: pet)

                        let photos = model.photos(for: pet)
                        if photos.isEmpty {
                            EmptyState(title: "No photos", message: "Add front, side, full body, coat close-up, or style reference photos.", systemImage: "photo")
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(photos) { photo in
                                    MockPhotoBlock(title: photo.photoType.rawValue, systemImage: "photo.fill", height: 120)
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        Button(role: .destructive) {
                            model.deletePet(pet)
                            dismiss()
                        } label: {
                            Label("Delete pet profile", systemImage: "trash")
                        }
                        .buttonStyle(QuietButtonStyle())
                        .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 28)
                }
                .appBackground()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { showEditor = true }
                    }
                }
                .sheet(isPresented: $showEditor) {
                    PetEditorView(mode: .edit(pet))
                        .environmentObject(model)
                }
            } else {
                EmptyState(title: "Pet not found", message: "This profile may have been deleted.", systemImage: "exclamationmark.triangle")
            }
        }
    }

    @ViewBuilder
    private func photoUploader(for pet: Pet) -> some View {
        let remaining = max(0, 8 - model.photos(for: pet).count)

        VStack(alignment: .leading, spacing: 12) {
            Picker("Photo type", selection: $selectedPhotoType) {
                ForEach(PetPhotoType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 10) {
                if remaining > 0 {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: remaining, matching: .images) {
                        Label("Photo library", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(QuietButtonStyle())

                    Button {
                        _ = model.addMockPhoto(to: pet, type: selectedPhotoType)
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                    }
                    .buttonStyle(QuietButtonStyle())
                } else {
                    Label("Photo limit reached", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetTheme.sage)
                }
            }

            Text("Images are stored as local mock references in this skeleton. The repository boundary is ready for compression and Supabase Storage upload.")
                .font(.caption)
                .foregroundStyle(PetTheme.muted)
        }
        .taskCard()
        .padding(.horizontal, 18)
        .onChange(of: selectedItems.count) { _, count in
            guard count > 0 else { return }
            for _ in 0..<min(count, remaining) {
                _ = model.addMockPhoto(to: pet, type: selectedPhotoType)
            }
            selectedItems.removeAll()
        }
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
    @State private var weightText: String
    @State private var coatType: String
    @State private var coatCondition: String
    @State private var temperamentText: String
    @State private var healthNotes: String
    @State private var groomingHistory: String

    init(mode: PetEditorMode) {
        self.mode = mode
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _species = State(initialValue: .dog)
            _breed = State(initialValue: "")
            _weightText = State(initialValue: "")
            _coatType = State(initialValue: "Curly")
            _coatCondition = State(initialValue: "Normal")
            _temperamentText = State(initialValue: "Calm")
            _healthNotes = State(initialValue: "")
            _groomingHistory = State(initialValue: "Regular grooming")
        case .edit(let pet):
            _name = State(initialValue: pet.name)
            _species = State(initialValue: pet.species)
            _breed = State(initialValue: pet.breed)
            _weightText = State(initialValue: pet.weight.map { "\(Int($0))" } ?? "")
            _coatType = State(initialValue: pet.coatType)
            _coatCondition = State(initialValue: pet.coatCondition)
            _temperamentText = State(initialValue: pet.temperament.joined(separator: ", "))
            _healthNotes = State(initialValue: pet.healthNotes ?? "")
            _groomingHistory = State(initialValue: pet.groomingHistory ?? "")
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
                    TextField("Breed", text: $breed)
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                }

                Section("Grooming profile") {
                    TextField("Coat type", text: $coatType)
                    TextField("Coat condition", text: $coatCondition)
                    TextField("Temperament tags", text: $temperamentText, axis: .vertical)
                    TextField("Health notes", text: $healthNotes, axis: .vertical)
                    TextField("Grooming history", text: $groomingHistory, axis: .vertical)
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
        let weight = Double(weightText.trimmingCharacters(in: .whitespacesAndNewlines))

        switch mode {
        case .create:
            model.addPet(name: name, species: species, breed: breed, weight: weight, coatType: coatType, temperament: temperament)
        case .edit(let original):
            var updated = original
            updated.name = name
            updated.species = species
            updated.breed = breed
            updated.weight = weight
            updated.coatType = coatType
            updated.coatCondition = coatCondition
            updated.temperament = temperament
            updated.healthNotes = healthNotes.isEmpty ? nil : healthNotes
            updated.groomingHistory = groomingHistory.isEmpty ? nil : groomingHistory
            model.updatePet(updated)
        }
        dismiss()
    }
}
