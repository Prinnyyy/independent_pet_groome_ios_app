const STORAGE_KEY = "pet-groomer-admin-mock-v1";

const seedData = {
  users: [
    {
      id: "11111111-1111-1111-1111-111111111111",
      displayName: "Taylor Chen",
      email: "demo@petgroomer.local",
      city: "Fullerton",
      zipCode: "92832",
      status: "active",
      pets: 2
    }
  ],
  groomers: [
    {
      id: "33333333-3333-3333-3333-333333333331",
      name: "Ava Park",
      city: "Fullerton",
      serviceAreas: ["Fullerton", "Brea", "Anaheim"],
      languages: ["English", "Korean"],
      yearsExperience: 8,
      specialties: ["Doodle", "Poodle", "Teddy cut", "Anxious pets"],
      priceMin: 85,
      priceMax: 165,
      rating: 4.9,
      reviewCount: 42,
      isVerified: true,
      status: "published",
      contactEvents: 18
    },
    {
      id: "33333333-3333-3333-3333-333333333332",
      name: "Mia Santos",
      city: "Irvine",
      serviceAreas: ["Irvine", "Tustin", "Costa Mesa"],
      languages: ["English", "Spanish"],
      yearsExperience: 6,
      specialties: ["Cats", "Senior pets", "De-matting", "Sensitive skin"],
      priceMin: 95,
      priceMax: 180,
      rating: 4.8,
      reviewCount: 31,
      isVerified: true,
      status: "published",
      contactEvents: 13
    },
    {
      id: "33333333-3333-3333-3333-333333333333",
      name: "Leo Wu",
      city: "Arcadia",
      serviceAreas: ["Arcadia", "Pasadena", "Alhambra"],
      languages: ["English", "Mandarin"],
      yearsExperience: 10,
      specialties: ["Asian fusion style", "Bichon", "Maltipoo", "Small dogs"],
      priceMin: 105,
      priceMax: 210,
      rating: 4.7,
      reviewCount: 26,
      isVerified: false,
      status: "published",
      contactEvents: 9
    }
  ],
  portfolio: [
    {
      id: "44444444-4444-4444-4444-444444444441",
      groomerId: "33333333-3333-3333-3333-333333333331",
      breed: "Mini Goldendoodle",
      serviceType: "Full groom",
      styleName: "Teddy cut",
      coatCondition: "Light matting",
      caption: "Soft teddy face with practical body length for a curly coat.",
      hidden: false
    },
    {
      id: "44444444-4444-4444-4444-444444444442",
      groomerId: "33333333-3333-3333-3333-333333333332",
      breed: "Domestic longhair",
      serviceType: "Cat grooming",
      styleName: "Sanitary trim",
      coatCondition: "Shedding",
      caption: "Low-stress comb-out and sanitary trim for an older longhair cat.",
      hidden: false
    },
    {
      id: "44444444-4444-4444-4444-444444444443",
      groomerId: "33333333-3333-3333-3333-333333333333",
      breed: "Bichon",
      serviceType: "Haircut",
      styleName: "Bichon round head",
      coatCondition: "Normal",
      caption: "Round head and balanced legs for a clean Asian fusion profile.",
      hidden: false
    }
  ],
  reviews: [
    {
      id: "review-1",
      groomerId: "33333333-3333-3333-3333-333333333331",
      author: "Taylor Chen",
      overallRating: 5,
      serviceType: "Full groom",
      reviewText: "Ava explained every step and Mochi came home calm with the exact teddy face I asked for.",
      status: "published"
    },
    {
      id: "review-2",
      groomerId: "33333333-3333-3333-3333-333333333332",
      author: "Taylor Chen",
      overallRating: 4.8,
      serviceType: "Cat grooming",
      reviewText: "Clear pricing, quiet setup, and a patient approach for Luna.",
      status: "published"
    }
  ],
  reports: [
    {
      id: "report-1",
      targetType: "groomer",
      targetId: "33333333-3333-3333-3333-333333333333",
      reason: "Inaccurate information",
      details: "Service area may have changed.",
      status: "open",
      adminNotes: ""
    }
  ],
  quoteRequests: [
    {
      id: "quote-1",
      groomerId: "33333333-3333-3333-3333-333333333331",
      serviceType: "Full groom",
      status: "submitted"
    }
  ]
};

class MockDataProvider {
  constructor() {
    const stored = localStorage.getItem(STORAGE_KEY);
    this.data = stored ? JSON.parse(stored) : structuredClone(seedData);
  }

  reset() {
    this.data = structuredClone(seedData);
    this.persist();
  }

  persist() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(this.data));
  }

  analytics() {
    const contactEvents = this.data.groomers.reduce((sum, groomer) => sum + groomer.contactEvents, 0);
    return {
      users: this.data.users.length,
      pets: this.data.users.reduce((sum, user) => sum + user.pets, 0),
      groomers: this.data.groomers.length,
      portfolio: this.data.portfolio.length,
      reviews: this.data.reviews.length,
      reports: this.data.reports.filter((report) => report.status !== "resolved").length,
      contactEvents,
      quoteRequests: this.data.quoteRequests.length
    };
  }

  createGroomer(input) {
    this.data.groomers.unshift({
      id: crypto.randomUUID(),
      name: input.name,
      city: input.city,
      serviceAreas: splitCSV(input.serviceAreas),
      languages: splitCSV(input.languages),
      yearsExperience: Number(input.yearsExperience || 0),
      specialties: splitCSV(input.specialties),
      priceMin: Number(input.priceMin || 0),
      priceMax: Number(input.priceMax || 0),
      rating: 0,
      reviewCount: 0,
      isVerified: input.isVerified === "on",
      status: "draft",
      contactEvents: 0
    });
    this.persist();
  }

  updateGroomerStatus(id, status) {
    const groomer = this.data.groomers.find((item) => item.id === id);
    if (groomer) groomer.status = status;
    this.persist();
  }

  toggleGroomerVerified(id) {
    const groomer = this.data.groomers.find((item) => item.id === id);
    if (groomer) groomer.isVerified = !groomer.isVerified;
    this.persist();
  }

  togglePortfolioHidden(id) {
    const item = this.data.portfolio.find((portfolio) => portfolio.id === id);
    if (item) item.hidden = !item.hidden;
    this.persist();
  }

  updateReviewStatus(id, status) {
    const review = this.data.reviews.find((item) => item.id === id);
    if (review) review.status = status;
    this.persist();
  }

  updateReportStatus(id, status) {
    const report = this.data.reports.find((item) => item.id === id);
    if (report) report.status = status;
    this.persist();
  }

  disableUser(id) {
    const user = this.data.users.find((item) => item.id === id);
    if (user) user.status = user.status === "disabled" ? "active" : "disabled";
    this.persist();
  }
}

class SupabaseDataProvider {
  constructor({ url, anonKey }) {
    this.url = url;
    this.anonKey = anonKey;
  }

  async notConfigured() {
    throw new Error("SupabaseDataProvider placeholder: add Supabase JS client and project credentials before use.");
  }

  analytics() {
    return this.notConfigured();
  }
}

const provider = new MockDataProvider();
const app = document.querySelector("#app");
const pageTitle = document.querySelector("#page-title");
let activeSection = "dashboard";

document.querySelectorAll(".nav-item").forEach((button) => {
  button.addEventListener("click", () => {
    activeSection = button.dataset.section;
    document.querySelectorAll(".nav-item").forEach((item) => item.classList.toggle("is-active", item === button));
    render();
  });
});

document.querySelector("#seed-reset").addEventListener("click", () => {
  provider.reset();
  render();
});

app.addEventListener("submit", (event) => {
  if (event.target.matches("#groomer-form")) {
    event.preventDefault();
    const formData = Object.fromEntries(new FormData(event.target).entries());
    formData.isVerified = event.target.elements.isVerified.checked ? "on" : "";
    provider.createGroomer(formData);
    event.target.reset();
    render();
  }
});

app.addEventListener("click", (event) => {
  const action = event.target.closest("[data-action]");
  if (!action) return;

  const { action: actionName, id, value } = action.dataset;
  if (actionName === "groomer-status") provider.updateGroomerStatus(id, value);
  if (actionName === "groomer-verified") provider.toggleGroomerVerified(id);
  if (actionName === "portfolio-hidden") provider.togglePortfolioHidden(id);
  if (actionName === "review-status") provider.updateReviewStatus(id, value);
  if (actionName === "report-status") provider.updateReportStatus(id, value);
  if (actionName === "user-disable") provider.disableUser(id);
  render();
});

function render() {
  const titles = {
    dashboard: "Dashboard",
    groomers: "Groomers",
    portfolio: "Portfolio",
    reviews: "Reviews",
    reports: "Reports",
    users: "Users"
  };
  pageTitle.textContent = titles[activeSection];
  app.innerHTML = renderers[activeSection]();
}

const renderers = {
  dashboard() {
    const stats = provider.analytics();
    const topGroomers = [...provider.data.groomers].sort((a, b) => b.contactEvents - a.contactEvents).slice(0, 3);
    return `
      <section class="grid stats-grid">
        ${statCard("Users", stats.users)}
        ${statCard("Pet profiles", stats.pets)}
        ${statCard("Contact events", stats.contactEvents)}
        ${statCard("Open reports", stats.reports)}
      </section>
      <section class="grid two-grid">
        <div class="card">
          <h2>Most contacted groomers</h2>
          <table class="table">
            <thead><tr><th>Groomer</th><th>City</th><th>Contacts</th></tr></thead>
            <tbody>
              ${topGroomers.map((groomer) => `
                <tr>
                  <td>${escapeHTML(groomer.name)}</td>
                  <td>${escapeHTML(groomer.city)}</td>
                  <td>${groomer.contactEvents}</td>
                </tr>
              `).join("")}
            </tbody>
          </table>
        </div>
        <div class="card">
          <h2>MVP boundaries</h2>
          <p>This dashboard manages discovery, portfolios, reviews, reports, users, and analytics. Payment, booking calendars, disputes, ads, memberships, and real-time chat stay out of the MVP.</p>
          <span class="pill">AI flags disabled</span>
          <span class="pill sky">Supabase placeholder ready</span>
          <span class="pill apricot">Mock CRUD enabled</span>
        </div>
      </section>
    `;
  },
  groomers() {
    return `
      <section class="grid two-grid">
        <form id="groomer-form" class="card form">
          <h2>Create groomer</h2>
          ${field("Name", "name", "Ava Park")}
          ${field("City", "city", "Fullerton")}
          ${field("Service areas", "serviceAreas", "Fullerton, Brea")}
          ${field("Languages", "languages", "English, Korean")}
          ${field("Specialties", "specialties", "Doodle, Teddy cut")}
          ${field("Years experience", "yearsExperience", "5", "number")}
          ${field("Price min", "priceMin", "85", "number")}
          ${field("Price max", "priceMax", "165", "number")}
          <label class="field"><span>Verified</span><input type="checkbox" name="isVerified" /></label>
          <button class="primary-action" type="submit">Add draft groomer</button>
        </form>
        <div class="card">
          <h2>Groomer profiles</h2>
          ${groomerTable(provider.data.groomers)}
        </div>
      </section>
    `;
  },
  portfolio() {
    return `
      <section class="card">
        <h2>Portfolio moderation</h2>
        <table class="table">
          <thead><tr><th>Style</th><th>Groomer</th><th>Tags</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            ${provider.data.portfolio.map((item) => {
              const groomer = provider.data.groomers.find((groomer) => groomer.id === item.groomerId);
              return `
                <tr>
                  <td><strong>${escapeHTML(item.styleName)}</strong><br>${escapeHTML(item.caption)}</td>
                  <td>${escapeHTML(groomer?.name || "Unassigned")}</td>
                  <td>${chips([item.breed, item.serviceType, item.coatCondition])}</td>
                  <td>${status(item.hidden ? "hidden" : "visible", item.hidden)}</td>
                  <td><button class="quiet-action" data-action="portfolio-hidden" data-id="${item.id}">${item.hidden ? "Show" : "Hide"}</button></td>
                </tr>
              `;
            }).join("")}
          </tbody>
        </table>
      </section>
    `;
  },
  reviews() {
    return `
      <section class="card">
        <h2>Review moderation</h2>
        <table class="table">
          <thead><tr><th>Review</th><th>Groomer</th><th>Rating</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            ${provider.data.reviews.map((review) => {
              const groomer = provider.data.groomers.find((groomer) => groomer.id === review.groomerId);
              return `
                <tr>
                  <td><strong>${escapeHTML(review.author)}</strong><br>${escapeHTML(review.reviewText)}</td>
                  <td>${escapeHTML(groomer?.name || "Unknown")}</td>
                  <td>${review.overallRating}</td>
                  <td>${status(review.status, review.status !== "published")}</td>
                  <td class="actions">
                    <button class="quiet-action" data-action="review-status" data-id="${review.id}" data-value="published">Publish</button>
                    <button class="danger-action" data-action="review-status" data-id="${review.id}" data-value="hidden">Hide</button>
                    <button class="danger-action" data-action="review-status" data-id="${review.id}" data-value="flagged">Flag</button>
                  </td>
                </tr>
              `;
            }).join("")}
          </tbody>
        </table>
      </section>
    `;
  },
  reports() {
    return `
      <section class="card">
        <h2>Reports</h2>
        <table class="table">
          <thead><tr><th>Target</th><th>Reason</th><th>Details</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            ${provider.data.reports.map((report) => `
              <tr>
                <td>${escapeHTML(report.targetType)}<br><small>${escapeHTML(report.targetId)}</small></td>
                <td>${escapeHTML(report.reason)}</td>
                <td>${escapeHTML(report.details)}</td>
                <td>${status(report.status, report.status !== "resolved")}</td>
                <td class="actions">
                  <button class="quiet-action" data-action="report-status" data-id="${report.id}" data-value="reviewing">Reviewing</button>
                  <button class="quiet-action" data-action="report-status" data-id="${report.id}" data-value="resolved">Resolve</button>
                  <button class="danger-action" data-action="report-status" data-id="${report.id}" data-value="dismissed">Dismiss</button>
                </td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </section>
    `;
  },
  users() {
    return `
      <section class="card">
        <h2>Users</h2>
        <table class="table">
          <thead><tr><th>User</th><th>Location</th><th>Pets</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>
            ${provider.data.users.map((user) => `
              <tr>
                <td><strong>${escapeHTML(user.displayName)}</strong><br>${escapeHTML(user.email)}</td>
                <td>${escapeHTML(user.city)}, ${escapeHTML(user.zipCode)}</td>
                <td>${user.pets}</td>
                <td>${status(user.status, user.status === "disabled")}</td>
                <td><button class="danger-action" data-action="user-disable" data-id="${user.id}">${user.status === "disabled" ? "Enable" : "Disable"}</button></td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </section>
    `;
  }
};

function statCard(label, value) {
  return `<article class="card stat"><span>${escapeHTML(label)}</span><strong>${value}</strong></article>`;
}

function groomerTable(groomers) {
  if (!groomers.length) return `<div class="empty">No groomers yet.</div>`;
  return `
    <table class="table">
      <thead><tr><th>Name</th><th>Fit</th><th>Status</th><th>Actions</th></tr></thead>
      <tbody>
        ${groomers.map((groomer) => `
          <tr>
            <td>
              <strong>${escapeHTML(groomer.name)}</strong><br>
              ${escapeHTML(groomer.city)} · $${groomer.priceMin}-$${groomer.priceMax}
            </td>
            <td>${chips(groomer.specialties)}${chips(groomer.languages, "sky")}</td>
            <td>${status(groomer.status, groomer.status !== "published")}<br>${groomer.isVerified ? '<span class="pill">Verified</span>' : '<span class="pill apricot">Unverified</span>'}</td>
            <td class="actions">
              <button class="quiet-action" data-action="groomer-verified" data-id="${groomer.id}">${groomer.isVerified ? "Unverify" : "Verify"}</button>
              <button class="quiet-action" data-action="groomer-status" data-id="${groomer.id}" data-value="published">Publish</button>
              <button class="danger-action" data-action="groomer-status" data-id="${groomer.id}" data-value="hidden">Hide</button>
            </td>
          </tr>
        `).join("")}
      </tbody>
    </table>
  `;
}

function field(label, name, placeholder, type = "text") {
  return `
    <label class="field">
      <span>${escapeHTML(label)}</span>
      <input name="${escapeHTML(name)}" type="${type}" placeholder="${escapeHTML(placeholder)}" required />
    </label>
  `;
}

function chips(items, tone = "apricot") {
  return items.map((item) => `<span class="pill ${tone}">${escapeHTML(item)}</span>`).join("");
}

function status(label, warning = false) {
  return `<span class="status ${warning ? "warning" : ""}">${escapeHTML(label)}</span>`;
}

function splitCSV(value) {
  return String(value || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function escapeHTML(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

render();
