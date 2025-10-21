# RealLife Lingo

RealLife Lingo is an iOS 17+ SwiftUI application that captures real-life language input, generates enriched flashcards with AI, and schedules SM-2 spaced repetition reviews. The repository also ships a lightweight Node.js server stub for Stripe webhooks, mock image generation, and TSV exports.

## Project Structure

```
RealLifeLingo/
  ios/              # SwiftUI application code organised by feature and core services
  server/           # Express stub server for webhooks, mock image generation, TSV exports
  Tests/            # Unit and UI test targets (XCTest)
  Scripts/          # Developer tooling (seed data, nightly roll-up placeholder)
```

Key architectural pieces:

- **CoreData persistence** is configured programmatically in `PersistenceController` with repositories to abstract storage.
- **Services** handle transcription (Apple Speech), NLP (Apple NLP), card creation, SM-2 scheduling, billing state machine, analytics roll-ups, and ingestion pipelines.
- **Protocol-driven clients** (`ImageGenClient`, `LLMClient`, `BillingClient`) make it trivial to swap providers while stubs keep the demo self-contained.
- **Features** are grouped by domain with SwiftUI view + view model pairs consuming `AppEnvironment` dependencies via `@EnvironmentObject`.
- **B2B admin** screens display weekly usage roll-ups and export TSVs for organisations.

## iOS App

1. Open `RealLifeLingo/ios` in Xcode 15+ and build the `RealLifeLingoApp` target for an iOS 17 simulator.
2. The app boots into a five-tab navigation:
   - **Home**: shows today's review queue, entry points for recording/importing sources, and plan summary.
   - **Library**: lists previously ingested transcripts, Kindle highlights, and subtitle files.
   - **Cards**: searchable/filtered list with detail editing for generated cards.
   - **Review**: SM-2 review session with tap-to-grade controls.
   - **Profile**: learner preferences, plan management, exports, and links to Org admin dashboards.
3. Recording leverages `AppleSpeechTranscriptionService` for on-device transcription with starred highlights, then queues AI enrichment through the card creation pipeline.
4. Import Kindle/Readwise/SRT files from the Import sheet; seed fixtures are available under `Scripts/` (see below).

### Seed Data

Run the helper script to stage demo assets and pre-populate the Core Data store with a full walkthrough user:

```bash
./Scripts/seed.sh
```

The script copies sample transcript, Kindle, and subtitle files into `RealLifeLingo/ios/Resources/Seed` and generates `seed_state.json` with:

- One demo learner tied to the “RealLife Academy” org.
- Three sample sources (lesson transcript, Kindle highlights, subtitles).
- Thirty enriched flashcards (10 due today) plus 10 review records.
- Usage events that mark the user Active with a rolling 30-day billing window and seeded weekly usage rows.

On the first launch the app detects the seed file, imports the demo data through the repository layer, and flags it so future launches operate on the live database. Delete the `Seed/seed_state.json` file or wipe the simulator data if you need a clean slate.

### Nightly Roll-up

`Scripts/nightly_rollup.sh` drives `xcodebuild` to run the `NightlyAutomationTests` suite, which calls both `BillingService.nightlyDowngrade` and `AnalyticsService.nightlyRollup`. Provide an Xcode project named `RealLifeLingo.xcodeproj`, or update the script’s environment variables, and execute it on macOS:

```bash
./Scripts/nightly_rollup.sh
```

Set `DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"` to override the simulator or export `SKIP_NIGHTLY_CHECK=1` in CI environments that should bypass the command.

## Server Stub

The Express server provides mock infrastructure endpoints used by the app.

```bash
cd server
npm install
npm run dev
```

Endpoints:

- `POST /webhook/stripe`: logs incoming Stripe webhook payloads (test mode).
- `POST /imagegen/mock`: returns a deterministic placeholder image URL for requested terms.
- `GET /export/tsv/:type`: streams TSVs (`cards`, `reviews`, `sources`, `user_profile`, `b2b_usage`, `b2b_org_metrics`) from `server/sample_exports`.
- `GET /health`: readiness probe.

Configure environment variables through `.env` (copy `.env.example`).

## Tests

Unit tests cover card extraction, SM-2 scheduling behaviour, billing state machine transitions, and parser utilities. UI tests provide a launch sanity placeholder.

Run the suites from Xcode or using `xcodebuild` once the project is set up. The test sources live under `Tests/Unit` and `Tests/UI`.

## Scripts

- `Scripts/seed.sh`: copies bundled sample assets for the Recorder/Import demo flows.
- `Scripts/nightly_rollup.sh`: documents how to invoke nightly analytics/billing routines.

## Requirements

- Xcode 15+, iOS 17 simulator.
- Node.js 18+ for the stub server.
- Swift 5.9 runtime for unit tests / scripts.

## Next Steps

- Wire the mock server into the app’s networking layer when switching from local stubs to remote providers.
- Expand UI tests using XCTest UI recording on macOS.
- Replace the placeholder nightly script with a CI job integrating `AnalyticsService` and `BillingService` in an automation bundle.
