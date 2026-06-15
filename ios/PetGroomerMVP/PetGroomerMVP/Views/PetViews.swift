import PhotosUI
import SwiftUI
import UIKit

struct PetsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showNewPet = false
    @State private var selectedPetForCard: Pet?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    ScreenTitle(title: "Pet cards", subtitle: "Keep each pet’s card ready for task cards and groomer review.")

                    Button {
                        showNewPet = true
                    } label: {
                        Label("Create Pet Card", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(CoralButtonStyle())
                    .padding(.horizontal, 18)

                    if model.pets.isEmpty {
                        EmptyState(title: "No pet cards yet", message: "Create a pet card before sending task cards.", systemImage: "pawprint")
                    } else {
                        ForEach(model.pets) { pet in
                            Button {
                                withAnimation(.smooth(duration: 0.22)) {
                                    selectedPetForCard = pet
                                }
                            } label: {
                                PetTaskCard(pet: pet, primaryPhoto: model.photos(for: pet).first)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 18)
                        }
                    }
                }
                .padding(.bottom, 28)
            }

            if let selectedPetForCard {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.2)) {
                            self.selectedPetForCard = nil
                        }
                    }
                    .transition(.opacity)

                PetCardOverlayView(petID: selectedPetForCard.id) {
                    withAnimation(.smooth(duration: 0.2)) {
                        self.selectedPetForCard = nil
                    }
                }
                .environmentObject(model)
                .padding(.horizontal, 22)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .center)))
                .zIndex(2)
            }
        }
        .appBackground()
        .customerChatToolbar()
        .animation(.smooth(duration: 0.22), value: selectedPetForCard?.id)
        .sheet(isPresented: $showNewPet) {
            PetEditorView(mode: .create)
                .environmentObject(model)
        }
    }
}

struct PetCardOverlayView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showEditor = false

    let petID: UUID
    let onClose: () -> Void

    private var pet: Pet? {
        model.pets.first { $0.id == petID }
    }

    var body: some View {
        Group {
            if let pet {
                petCard(for: pet)
            } else {
                EmptyState(title: "Pet card not found", message: "This pet card may have been deleted.", systemImage: "exclamationmark.triangle")
                    .taskCard()
            }
        }
        .sheet(isPresented: $showEditor) {
            if let pet {
                PetEditorView(mode: .edit(pet))
                    .environmentObject(model)
            }
        }
    }

    private func petCard(for pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(pet.name)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text([pet.species.rawValue, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
                Spacer(minLength: 10)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PetTheme.muted)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            PetCardPhotoShowcase(photos: model.photos(for: pet), species: pet.species)
                .frame(height: 220)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                PetCardMiniFact(title: "Gender", value: pet.sex?.nilIfEmpty ?? "Not set", icon: "person.fill.questionmark")
                PetCardMiniFact(title: "Age", value: pet.age.map { "\(Int($0)) years" } ?? "Not set", icon: "calendar")
                PetCardMiniFact(title: "Weight", value: pet.weight.map { "\(Int($0)) lb" } ?? "Not set", icon: "scalemass")
                PetCardMiniFact(title: "Photos", value: "\(model.photos(for: pet).count)", icon: "photo.on.rectangle")
            }

            PetCardTextBlock(title: "Temperament", value: pet.temperament.isEmpty ? "Not set" : pet.temperament.joined(separator: " · "), icon: "heart.text.square.fill")
            PetCardTextBlock(title: "Health notes", value: pet.healthNotes?.nilIfEmpty ?? "No special notes", icon: "cross.case.fill")

            Button {
                showEditor = true
            } label: {
                Label("Edit", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CoralButtonStyle())
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.24)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PetTheme.coral.opacity(0.18), lineWidth: 1.2)
        )
        .frame(maxWidth: 390)
    }
}

struct ReadOnlyPetCardOverlayView: View {
    let package: PetProfilePackage
    let onClose: () -> Void

    private var pet: Pet {
        package.petSnapshot
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(pet.name)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(PetTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text([pet.species.rawValue, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
                Spacer(minLength: 10)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PetTheme.muted)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            PetCardPhotoShowcase(photos: package.photoSnapshots, species: pet.species)
                .frame(height: 220)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                PetCardMiniFact(title: "Gender", value: pet.sex?.nilIfEmpty ?? "Not set", icon: "person.fill.questionmark")
                PetCardMiniFact(title: "Age", value: pet.age.map { "\(Int($0)) years" } ?? "Not set", icon: "calendar")
                PetCardMiniFact(title: "Weight", value: pet.weight.map { "\(Int($0)) lb" } ?? "Not set", icon: "scalemass")
                PetCardMiniFact(title: "Photos", value: "\(package.photoSnapshots.count)", icon: "photo.on.rectangle")
            }

            PetCardTextBlock(title: "Temperament", value: pet.temperament.isEmpty ? "Not set" : pet.temperament.joined(separator: " · "), icon: "heart.text.square.fill")
            PetCardTextBlock(title: "Health notes", value: pet.healthNotes?.nilIfEmpty ?? "No special notes", icon: "cross.case.fill")
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.24)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 9)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PetTheme.coral.opacity(0.18), lineWidth: 1.2)
        )
        .frame(maxWidth: 390)
    }
}

private struct PetCardPhotoShowcase: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.78), lineWidth: 1)
        )
    }
}

private struct PetCardMiniFact: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.coral)
                .frame(width: 26, height: 26)
                .background(PetTheme.apricot.opacity(0.28), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PetTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            Spacer(minLength: 0)
        }
        .padding(9)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
        )
    }
}

private struct PetCardTextBlock: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.sage)
                .frame(width: 26, height: 26)
                .background(PetTheme.mint.opacity(0.3), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
                Text(value)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(PetTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
        )
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
                        Label("Server pet card package", systemImage: "link")
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
        .navigationTitle("Pet Card")
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
        ZStack {
            if let data = photo?.showcaseDisplayData, let uiImage = UIImage(data: data) {
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
                    Text(photo == nil ? "Add pet card photos" : "Local photo")
                        .font(.headline.weight(.semibold))
                        .fontDesign(.rounded)
                }
                .foregroundStyle(.white.opacity(0.94))
            }
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

private struct PetProfileTextField: View {
    let title: String
    @Binding var text: String
    var limit: Int = 120
    var keyboard: UIKeyboardType = .default
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            LimitedTextField(title, text: $text, limit: limit, axis: axis)
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
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private enum PetPhotoRenditionFactory {
    static func makeRenditions(from data: Data) -> PetPhotoImageRenditions {
        guard let image = UIImage(data: data) else {
            return PetPhotoImageRenditions(originalData: data, squareThumbnailData: data, cardShowcaseData: data)
        }

        return PetPhotoImageRenditions(
            originalData: data,
            squareThumbnailData: centerCroppedJPEGData(from: image, targetSize: CGSize(width: 800, height: 800)),
            cardShowcaseData: centerCroppedJPEGData(from: image, targetSize: CGSize(width: 1200, height: 760))
        )
    }

    private static func centerCroppedJPEGData(from image: UIImage, targetSize: CGSize) -> Data? {
        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return image.jpegData(compressionQuality: 0.86) }

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

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let renderedImage = renderer.image { _ in
            image.draw(in: CGRect(
                x: -cropRect.origin.x * targetSize.width / cropRect.width,
                y: -cropRect.origin.y * targetSize.height / cropRect.height,
                width: sourceSize.width * targetSize.width / cropRect.width,
                height: sourceSize.height * targetSize.height / cropRect.height
            ))
        }
        return renderedImage.jpegData(compressionQuality: 0.86)
    }
}

enum PetEditorMode {
    case create
    case edit(Pet)
}

private struct PetCardPhotoGridEditor: View {
    let photos: [PetPhoto]
    let species: PetSpecies
    let onAddCamera: () -> Void
    let onAddLibrary: () -> Void
    let onReplaceCamera: (PetPhoto) -> Void
    let onReplaceLibrary: (PetPhoto) -> Void
    let onDelete: (PetPhoto) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private var visiblePhotos: [PetPhoto] { Array(photos.prefix(8)) }
    private var shouldShowAddTile: Bool { visiblePhotos.count < 8 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Photos")
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                Spacer()
                Text("\(visiblePhotos.count)/8")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(visiblePhotos) { photo in
                    photoMenuTile(photo)
                }

                if shouldShowAddTile {
                    addPhotoTile
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.045), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(PetTheme.line.opacity(0.62), lineWidth: 1)
        )
    }

    private func photoMenuTile(_ photo: PetPhoto) -> some View {
        Menu {
            Button(role: .destructive) {
                onDelete(photo)
            } label: {
                Label("Delete Photo", systemImage: "trash")
            }

            Menu {
                Button {
                    onReplaceCamera(photo)
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                }

                Button {
                    onReplaceLibrary(photo)
                } label: {
                    Label("Upload from Photos", systemImage: "photo.fill.on.rectangle.fill")
                }
            } label: {
                Label("Replace Photo", systemImage: "arrow.triangle.2.circlepath.camera")
            }
        } label: {
            PetCardPhotoGridTile(photo: photo, species: species)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit pet card photo")
    }

    private var addPhotoTile: some View {
        Menu {
            Button {
                onAddCamera()
            } label: {
                Label("Take Photo", systemImage: "camera.fill")
            }

            Button {
                onAddLibrary()
            } label: {
                Label("Upload from Photos", systemImage: "photo.fill.on.rectangle.fill")
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PetTheme.apricot.opacity(0.25))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(PetTheme.coral.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(PetTheme.coral)
            }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add pet card photo")
    }
}

private struct PetCardPhotoGridTile: View {
    let photo: PetPhoto
    let species: PetSpecies

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let data = photo.squareDisplayData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    LinearGradient(
                        colors: [PetTheme.sky.opacity(0.72), PetTheme.mint.opacity(0.72), PetTheme.apricot.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: species == .cat ? "cat.fill" : "dog.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct PetEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let mode: PetEditorMode
    @State private var name: String
    @State private var species: PetSpecies
    @State private var breed: String
    @State private var weightText: String
    @State private var ageText: String
    @State private var sexOption: PetSexOption
    @State private var temperamentText: String
    @State private var healthNotes: String
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var showCameraUnavailableAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var replacementPhotoID: UUID?
    @State private var draftPhotos: [PetPhoto] = []
    @State private var draftLoadedForPetID: UUID?
    private let creationDraftPetID: UUID

    init(mode: PetEditorMode) {
        self.mode = mode
        self.creationDraftPetID = UUID()
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _species = State(initialValue: .dog)
            _breed = State(initialValue: "Maltipoo")
            _weightText = State(initialValue: "15")
            _ageText = State(initialValue: "4")
            _sexOption = State(initialValue: .notSpecified)
            _temperamentText = State(initialValue: "")
            _healthNotes = State(initialValue: "")
        case .edit(let pet):
            _name = State(initialValue: pet.name)
            _species = State(initialValue: pet.species)
            _breed = State(initialValue: pet.breed)
            _weightText = State(initialValue: pet.weight.map { "\(Int($0))" } ?? "")
            _ageText = State(initialValue: pet.age.map { "\(Int($0))" } ?? "")
            _sexOption = State(initialValue: PetSexOption(rawValue: pet.sex ?? "") ?? .notSpecified)
            _temperamentText = State(initialValue: pet.temperament.joined(separator: ", "))
            _healthNotes = State(initialValue: pet.healthNotes ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PetCardPhotoGridEditor(
                        photos: draftPhotos,
                        species: species,
                        onAddCamera: {
                            replacementPhotoID = nil
                            openCameraOrAlert()
                        },
                        onAddLibrary: {
                            replacementPhotoID = nil
                            showPhotoPicker = true
                        },
                        onReplaceCamera: { photo in
                            replacementPhotoID = photo.id
                            openCameraOrAlert()
                        },
                        onReplaceLibrary: { photo in
                            replacementPhotoID = photo.id
                            showPhotoPicker = true
                        },
                        onDelete: { photo in
                            withAnimation(.smooth(duration: 0.18)) {
                                draftPhotos.removeAll { $0.id == photo.id }
                                normalizeDraftPhotoPrimaryState()
                            }
                        }
                    )
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 12) {
                        petTextField("Name", text: $name)

                        Picker("Species", selection: $species) {
                            ForEach(PetSpecies.allCases) { species in
                                Text(species.rawValue).tag(species)
                            }
                        }
                        .pickerStyle(.segmented)

                        PetProfileMenuPicker(title: "Breed", value: $breed, options: breedOptions)
                        PetProfileEnumPicker(title: "Sex", value: $sexOption)

                        HStack(spacing: 10) {
                            petNumberField("Weight", text: $weightText, suffix: "lb")
                            petNumberField("Age", text: $ageText, suffix: "years")
                        }
                    }
                    .taskCard()
                    .padding(.horizontal, 18)

                    VStack(alignment: .leading, spacing: 12) {
                        PetProfileTextField(title: "Temperament tags", text: $temperamentText, limit: 120, axis: .vertical)
                        PetProfileTextField(title: "Health notes", text: $healthNotes, limit: 240, axis: .vertical)
                    }
                    .taskCard()
                    .padding(.horizontal, 18)
                }
                .padding(.vertical, 16)
            }
            .appBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, item in
                loadSelectedPhoto(item)
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPhotoPicker { data in
                    savePhotoData(data)
                }
                .ignoresSafeArea()
            }
            .alert("Camera unavailable", isPresented: $showCameraUnavailableAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This simulator or device does not currently provide a camera. Please upload from Photos instead.")
            }
            .onChange(of: species) { _, newSpecies in
                let options = PetProfileOptionSet.breeds(for: newSpecies)
                if !options.contains(breed), let first = options.first {
                    breed = first
                }
            }
            .onChange(of: weightText) { _, value in
                weightText = boundedNumericText(value, max: 999)
            }
            .onChange(of: ageText) { _, value in
                ageText = boundedNumericText(value, max: 99)
            }
            .onAppear {
                loadDraftPhotosIfNeeded()
            }
        }
    }

    private func petTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            LimitedTextField(title, text: text, limit: 40)
                .font(.subheadline.weight(.semibold))
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

    private func petNumberField(_ title: String, text: Binding<String>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.muted)
            HStack(spacing: 6) {
                LimitedTextField(title, text: text, limit: title == "Weight" ? 3 : 2)
                    .keyboardType(.numberPad)
                    .font(.subheadline.weight(.semibold))
                Text(suffix)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(PetTheme.cream.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.85), lineWidth: 1)
            )
        }
    }

    private var editingPet: Pet? {
        if case .edit(let pet) = mode {
            return model.pets.first { $0.id == pet.id } ?? pet
        }
        return nil
    }

    private var draftPhotoPetID: UUID {
        editingPet?.id ?? creationDraftPetID
    }

    private var title: String {
        switch mode {
        case .create: "Create Pet Card"
        case .edit: "Edit Pet Card"
        }
    }

    private func save() {
        let temperament = temperamentText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        switch mode {
        case .create:
            let newPet = model.addPet(
                name: name,
                species: species,
                breed: breed,
                weight: Double(boundedInt(weightText, max: 999)),
                age: Double(boundedInt(ageText, max: 99)),
                sex: sexOption.profileValue,
                temperament: temperament,
                healthNotes: healthNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
            model.setPetPhotos(for: newPet, photos: draftPhotos)
        case .edit(let original):
            var updated = original
            updated.name = name
            updated.species = species
            updated.breed = breed
            updated.weight = Double(boundedInt(weightText, max: 999))
            updated.age = Double(boundedInt(ageText, max: 99))
            updated.sex = sexOption.profileValue
            updated.temperament = temperament
            updated.healthNotes = healthNotes.isEmpty ? nil : healthNotes
            model.updatePet(updated)
            model.setPetPhotos(for: updated, photos: draftPhotos)
        }
        dismiss()
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run {
                savePhotoData(data)
                selectedPhotoItem = nil
            }
        }
    }

    private func openCameraOrAlert() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showCameraPicker = true
        } else {
            showCameraUnavailableAlert = true
        }
    }

    private func savePhotoData(_ data: Data?) {
        guard let data else {
            replacementPhotoID = nil
            return
        }
        let renditions = PetPhotoRenditionFactory.makeRenditions(from: data)
        withAnimation(.smooth(duration: 0.18)) {
            if let replacementPhotoID {
                if let index = draftPhotos.firstIndex(where: { $0.id == replacementPhotoID }) {
                    draftPhotos[index].imageURL = "local://pet-photo-\(UUID().uuidString)"
                    draftPhotos[index].imageData = data
                    draftPhotos[index].imageRenditions = renditions
                    draftPhotos[index].createdAt = Date()
                }
                self.replacementPhotoID = nil
            } else if draftPhotos.count < 8 {
                draftPhotos.append(
                    PetPhoto(
                        id: UUID(),
                        petID: draftPhotoPetID,
                        userID: model.currentUser.id,
                        imageURL: "local://pet-photo-\(UUID().uuidString)",
                        photoType: .petCard,
                        isPrimary: draftPhotos.isEmpty,
                        createdAt: Date(),
                        imageData: data,
                        imageRenditions: renditions
                    )
                )
            }
            normalizeDraftPhotoPrimaryState()
        }
    }

    private func loadDraftPhotosIfNeeded() {
        let petID = draftPhotoPetID
        guard draftLoadedForPetID != petID else { return }
        if let editingPet {
            draftPhotos = Array(model.photos(for: editingPet).prefix(8))
        } else {
            draftPhotos = []
        }
        normalizeDraftPhotoPrimaryState()
        draftLoadedForPetID = petID
    }

    private func normalizeDraftPhotoPrimaryState() {
        draftPhotos = draftPhotos.prefix(8).enumerated().map { index, photo in
            var normalizedPhoto = photo
            normalizedPhoto.photoType = .petCard
            normalizedPhoto.isPrimary = index == 0
            return normalizedPhoto
        }
    }

    private func boundedNumericText(_ value: String, max: Int) -> String {
        let digits = value.filter(\.isNumber)
        guard let number = Int(digits) else { return "" }
        return "\(min(number, max))"
    }

    private func boundedInt(_ value: String, max: Int) -> Int {
        min(Int(value.filter(\.isNumber)) ?? 0, max)
    }

    private var breedOptions: [String] {
        var options = PetProfileOptionSet.breeds(for: species)
        if !breed.isEmpty && !options.contains(breed) {
            options.insert(breed, at: 0)
        }
        return options
    }
}
