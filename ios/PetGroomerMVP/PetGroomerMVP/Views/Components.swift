import SwiftUI
import UIKit

struct LimitedTextField: View {
    let placeholder: String
    @Binding var text: String
    let limit: Int
    var axis: Axis = .horizontal

    @State private var limitFeedback = false
    @State private var shakeTrigger = 0

    init(_ placeholder: String, text: Binding<String>, limit: Int, axis: Axis = .horizontal) {
        self.placeholder = placeholder
        self._text = text
        self.limit = limit
        self.axis = axis
    }

    var body: some View {
        TextField(placeholder, text: limitedBinding, axis: axis)
            .tint(limitFeedback ? PetTheme.coral : PetTheme.sage)
            .modifier(LimitShakeEffect(trigger: shakeTrigger))
            .animation(.smooth(duration: 0.16), value: limitFeedback)
    }

    private var limitedBinding: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                guard newValue.count <= limit else {
                    if text.count < limit {
                        text = String(newValue.prefix(limit))
                    }
                    triggerLimitFeedback()
                    return
                }
                text = newValue
            }
        )
    }

    private func triggerLimitFeedback() {
        withAnimation(.linear(duration: 0.18)) {
            shakeTrigger += 1
        }
        limitFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            limitFeedback = false
        }
    }
}

private struct LimitShakeEffect: GeometryEffect {
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

struct MockPhotoBlock: View {
    let title: String
    var systemImage: String = "pawprint.fill"
    var height: CGFloat = 118

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [PetTheme.apricot.opacity(0.65), PetTheme.sky.opacity(0.8), PetTheme.mint.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.ink)
                .padding(8)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(8)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct GroomerCard: View {
    @State private var showContactMismatchInfo = false

    let groomer: Groomer
    let portfolio: [PortfolioItem]
    let isSaved: Bool
    let onSave: () -> Void
    let onContact: () -> Void
    var contactTitle: String = "Contact groomer"
    var contactIcon: String = "paperplane.fill"
    var isContactDisabled: Bool = false
    var contactMismatchReasons: [String] = []
    var secondaryTitle: String?
    var secondaryIcon: String = "person.text.rectangle"
    var onSecondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                MockPhotoBlock(title: initials, systemImage: "scissors", height: 76)
                    .frame(width: 76)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(groomer.name)
                                .font(.title3.weight(.bold))
                                .fontDesign(.rounded)
                                .foregroundStyle(PetTheme.ink)
                                .lineLimit(1)

                            HStack(spacing: 7) {
                                Label(groomer.city, systemImage: "mappin.and.ellipse")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PetTheme.muted)
                                    .lineLimit(1)
                                if groomer.isVerified {
                                    VerifiedBadge()
                                }
                            }
                        }
                        Spacer()
                        Button(action: onSave) {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundStyle(isSaved ? PetTheme.coral : PetTheme.muted)
                                .frame(width: 34, height: 34)
                        }
                        .accessibilityLabel(isSaved ? "Remove saved groomer" : "Save groomer")
                    }

                    HStack(spacing: 8) {
                        RatingPill(rating: groomer.rating, count: groomer.reviewCount)
                        Text("$\(Int(groomer.priceMin))-$\(Int(groomer.priceMax))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PetTheme.ink)
                    }
                }
            }

            Text(groomer.bio)
                .font(.subheadline)
                .foregroundStyle(PetTheme.muted)
                .lineLimit(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(groomer.specialties.prefix(4), id: \.self) { specialty in
                        Chip(text: specialty, color: specialty == "Cats" ? PetTheme.mint : PetTheme.apricot)
                    }
                }
            }

            portfolioRail

            HStack(spacing: 9) {
                HStack(spacing: 6) {
                    Button(action: onContact) {
                        actionLabel(title: contactTitle, icon: contactIcon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CoralButtonStyle())
                    .disabled(isContactDisabled)
                    .opacity(isContactDisabled ? 0.58 : 1)

                    if !contactMismatchReasons.isEmpty {
                        Button {
                            showContactMismatchInfo = true
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(PetTheme.coralDark)
                                .frame(width: 34, height: 34)
                                .background(PetTheme.apricot.opacity(0.24), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Why this groomer does not match")
                        .popover(isPresented: $showContactMismatchInfo) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Not a fit for this task")
                                    .font(.headline.weight(.bold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(PetTheme.ink)
                                ForEach(contactMismatchReasons, id: \.self) { reason in
                                    Label(reason, systemImage: "info.circle")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(PetTheme.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(14)
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                if let secondaryTitle, let onSecondaryAction {
                    Button(action: onSecondaryAction) {
                        actionLabel(title: secondaryTitle, icon: secondaryIcon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuietButtonStyle())
                }
            }
            .frame(height: 46)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, PetTheme.porcelain, PetTheme.apricot.opacity(0.18)],
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
    }

    private var initials: String {
        groomer.name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }

    private var portfolioRail: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Recent work")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.coralDark)
                Spacer()
                Text("\(portfolio.count) looks")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(portfolio.prefix(7)) { item in
                        portfolioTile(item)
                    }

                    Button {
                        onSecondaryAction?()
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2.weight(.semibold))
                            Text("See all")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(PetTheme.coral)
                        .frame(width: 82, height: 82)
                        .background(PetTheme.apricot.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(PetTheme.coral.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(onSecondaryAction == nil)
                    .opacity(onSecondaryAction == nil ? 0.55 : 1)
                }
                .padding(.vertical, 1)
            }
        }
        .padding(10)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PetTheme.line.opacity(0.42), lineWidth: 1)
        )
    }

    private func portfolioTile(_ item: PortfolioItem) -> some View {
        MockPhotoBlock(
            title: item.styleName,
            systemImage: item.petSpecies == .cat ? "cat.fill" : "dog.fill",
            height: 82
        )
        .frame(width: 82)
    }

    private func actionLabel(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout.weight(.bold))
            Text(title)
                .font(.callout.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct PetTaskCard: View {
    let pet: Pet
    let primaryPhoto: PetPhoto?

    var body: some View {
        HStack(spacing: 12) {
            PetTaskAvatar(photo: primaryPhoto, species: pet.species)
                .frame(width: 72)
            VStack(alignment: .leading, spacing: 5) {
                Text(pet.name)
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(PetTheme.ink)
                Text([pet.species.rawValue, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(PetTheme.muted)
                    .lineLimit(2)
                HStack(spacing: 7) {
                    if let sex = pet.sex, !sex.isEmpty {
                        Label(sex, systemImage: "person.fill.questionmark")
                    }
                    if let age = pet.age {
                        Label("\(Int(age)) yrs", systemImage: "calendar")
                    }
                    if let weight = pet.weight {
                        Label("\(Int(weight)) lb", systemImage: "scalemass")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(PetTheme.sage)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(PetTheme.muted)
        }
        .taskCard()
    }
}

private struct PetTaskAvatar: View {
    let photo: PetPhoto?
    let species: PetSpecies

    var body: some View {
        ZStack {
            if let data = photo?.squareDisplayData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [PetTheme.apricot.opacity(0.72), PetTheme.mint.opacity(0.76), PetTheme.sky.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: species == .cat ? "cat.fill" : "dog.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct PortfolioCard: View {
    let item: PortfolioItem
    let isSaved: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MockPhotoBlock(title: item.styleName, systemImage: item.petSpecies == .cat ? "cat.fill" : "dog.fill", height: 150)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.breed)
                        .font(.headline.weight(.semibold))
                        .fontDesign(.rounded)
                    Text(item.caption)
                        .font(.caption)
                        .foregroundStyle(PetTheme.muted)
                        .lineLimit(3)
                }
                Spacer()
                Button(action: onSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(isSaved ? PetTheme.coral : PetTheme.muted)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(isSaved ? "Unsave portfolio" : "Save portfolio")
            }
        }
        .taskCard()
    }
}

struct EmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(PetTheme.sage)
            Text(title)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PetTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .taskCard()
        .padding(.horizontal, 18)
    }
}

struct CameraPhotoPicker: UIViewControllerRepresentable {
    let onImageData: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPhotoPicker

        init(parent: CameraPhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.86) {
                parent.onImageData(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
