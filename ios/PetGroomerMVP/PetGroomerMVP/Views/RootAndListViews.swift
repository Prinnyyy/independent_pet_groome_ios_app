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

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(
                    title: "Find the actual groomer",
                    subtitle: "Compare real portfolios, pet-fit details, price ranges, and direct contact options."
                )

                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(PetTheme.coral)
                        Text("Today’s grooming task")
                            .font(.headline.weight(.semibold))
                            .fontDesign(.rounded)
                        Spacer()
                    }
                    Text(model.pets.isEmpty ? "Create a pet profile so groomers can estimate coat condition, size, temperament, and service fit." : "Use \(model.pets[0].name)'s profile to request clear pricing and availability from a matching groomer.")
                        .font(.subheadline)
                        .foregroundStyle(PetTheme.muted)
                    Button {
                        showNewPet = true
                    } label: {
                        Label(model.pets.isEmpty ? "Create pet profile" : "Update pet profile", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(CoralButtonStyle())
                }
                .taskCard()
                .padding(.horizontal, 18)

                SectionHeader(title: "Nearby groomers")
                VStack(spacing: 14) {
                    ForEach(model.groomers.prefix(2)) { groomer in
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
