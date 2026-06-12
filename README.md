# Independent Pet Groomer MVP Skeleton

This repo is a first runnable skeleton for an independent pet groomer discovery app. It is intentionally mock-backed for the first pass, with Supabase schema and provider boundaries ready for real credentials later.

## Structure

- `ios/PetGroomerMVP/` - Native SwiftUI iOS app, minimum iOS 17, bundle id `com.local.petgroomer.mvp`.
- `supabase/migrations/0001_initial_schema.sql` - PostgreSQL schema for users, pets, photos, groomers, portfolio, reviews, favorites, contact events, quote requests, reports, AI logs, and feature flags.
- `supabase/seed.sql` - Demo records aligned with the iOS and admin mock data.
- `admin/` - Dependency-free static admin dashboard using local mock state.

## iOS App

Open the project in Xcode:

```sh
open ios/PetGroomerMVP/PetGroomerMVP.xcodeproj
```

Build from the command line:

```sh
xcodebuild \
  -project ios/PetGroomerMVP/PetGroomerMVP.xcodeproj \
  -scheme PetGroomerMVP \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

The app includes one shared mobile experience for both customer users and groomers:

- Pet owner mode: Home, Search, Pets, Orders, and Account tabs, with Saved moved into the Search toolbar.
- Groomer mode: Today, Schedule, Inbox, Portfolio, and Account tabs.
- Account role switcher so the same signed-in demo user can move between pet owner and groomer workspaces.
- Mock sign-in/profile state with the demo user claiming the Ava Park groomer profile.
- Pet profile create/edit/delete and photo picker flow with an 8-photo limit.
- Groomer directory, filters, groomer profile pages, portfolio detail pages.
- Favorites, contact event logging, task-card sending, mock chat with image placeholders, quote requests, reviews, reports, groomer inbox/schedule management, groomer profile editing, and groomer portfolio creation.
- Disabled AI feature flags and an `AIService` protocol with placeholder behavior.

The live Supabase integration should replace the `Mock*Repository` implementations with the `Supabase*Repository` placeholders after project URL, anon key, auth, storage, and RLS policies are finalized.

## Card Exchange Model

The core product model is card-package exchange:

- A customer creates a grooming task card as a local package. It contains the pet snapshot, pet photo snapshot references, appointment date, time window, style goal, notes, search area, 5 MB style-reference image slot, private owner score, and an internal lookup code that is not shown to the customer.
- Groomers publish public profile cards that stay server-addressable. Customer orders store a groomer card link instead of copying the groomer profile locally.
- Sending a task card creates a groomer inbox package plus two local order records: one in the customer order store and one in the groomer order store.
- Each order record points to the task-card package and the groomer public-card link, and tracks `waiting_reply`, `accepted`, `rejected`, `cancelled`, or `completed`.
- The Supabase schema mirrors this with `card_access_links`, `grooming_tasks`, `grooming_task_submissions`, and `card_exchange_orders` so the mock demo can later move to live storage without changing the product shape.

## Platform Admin Dashboard

Open directly:

```sh
open admin/index.html
```

Or serve locally:

```sh
python3 -m http.server 4173 --directory admin
```

Then visit `http://localhost:4173`.

The dashboard is for platform operators, not groomers. Groomers use the same iOS app as customers through Groomer mode. The dashboard supports mock local CRUD/moderation for platform admin tasks: groomers, portfolio visibility, review status, reports, users, and basic analytics. `SupabaseDataProvider` is a placeholder for a future Supabase JS client implementation.

## Supabase

Apply the schema in a Supabase project:

```sh
supabase db push
```

Or paste `supabase/migrations/0001_initial_schema.sql` into the Supabase SQL editor, then run `supabase/seed.sql`.

Recommended Storage buckets for the live backend:

- `pet-photos`
- `groomer-photos`
- `portfolio-images`
- `review-images`
- `task-reference-images`

RLS policies are not enabled in this skeleton because real auth roles, admin claims, and service-role usage need to be decided with the actual Supabase project. Add RLS before using live user data.

## MVP Boundaries

Included: discovery, profiles, portfolios, reviews, favorites, contact events, task-card exchange, mock chat, quote requests, reports, basic admin moderation, and AI-ready structure.

Not included: platform payment, production calendar sync, dispute handling, production real-time chat, memberships, ads, AI image generation, or production Supabase credentials.
