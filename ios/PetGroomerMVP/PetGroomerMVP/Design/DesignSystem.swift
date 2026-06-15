import SwiftUI

enum PetTheme {
    static let cream = Color(red: 0.99, green: 0.96, blue: 0.91)
    static let porcelain = Color(red: 1.0, green: 0.995, blue: 0.98)
    static let apricot = Color(red: 1.0, green: 0.88, blue: 0.78)
    static let coral = Color(red: 0.94, green: 0.38, blue: 0.28)
    static let coralDark = Color(red: 0.70, green: 0.20, blue: 0.16)
    static let sage = Color(red: 0.55, green: 0.70, blue: 0.58)
    static let mint = Color(red: 0.86, green: 0.94, blue: 0.86)
    static let ink = Color(red: 0.18, green: 0.18, blue: 0.17)
    static let muted = Color(red: 0.44, green: 0.43, blue: 0.39)
    static let line = Color(red: 0.90, green: 0.85, blue: 0.78)
    static let sky = Color(red: 0.84, green: 0.92, blue: 0.95)
}

struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PetTheme.cream.ignoresSafeArea())
            .tint(PetTheme.coral)
    }
}

struct TaskCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PetTheme.porcelain)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PetTheme.line.opacity(0.75), lineWidth: 1)
            )
    }
}

struct CoralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? PetTheme.coralDark : PetTheme.coral)
            )
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(PetTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? PetTheme.apricot.opacity(0.65) : PetTheme.apricot.opacity(0.38))
            )
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }

    func taskCard() -> some View {
        modifier(TaskCardStyle())
    }
}

struct ScreenTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
            Text(subtitle)
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
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(PetTheme.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetTheme.coralDark)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }
}

struct Chip: View {
    let text: String
    var color: Color = PetTheme.apricot

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(PetTheme.ink)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.55))
            )
    }
}

struct VerifiedBadge: View {
    var body: some View {
        Label("Verified", systemImage: "checkmark.seal.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(PetTheme.sage)
            .labelStyle(.titleAndIcon)
    }
}

struct RatingPill: View {
    let rating: Double
    let count: Int

    var body: some View {
        Label("\(rating, specifier: "%.1f") (\(count))", systemImage: "star.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(PetTheme.coralDark)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PetTheme.apricot.opacity(0.5))
            )
    }
}
