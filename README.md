# FanScope

Native iOS application for tracking Turkish fan token TRY markets, order book depth, circulating/total supply ratios, and on-chain mint, burn, and exchange wallet flows across Ethereum and Chiliz Chain.

Zero third-party SDK dependencies and no API keys required to build and run.

## Architecture

The codebase separates platform-independent core, domain, and data layers into a local Swift Package (`Packages/FanScopeKit`) linked into a thin `FanScope` SwiftUI/UIKit app target:

- **App (`FanScope/`)**: SwiftUI views, design system, EN/TR `Localizable.xcstrings` localization with live in-app locale switching, targeted UIKit bridges (`SFSafariViewController`, haptics), and `SwiftData` persistence.
- **Core (`FanScopeKit/Core`)**: Protocol-backed `URLSessionHTTPClient`, typed `NetworkError` (explicit HTTP `429 Retry-After` and `CancellationError` handling), `OSLog` logger categories, and an `actor`-based `TTLCache` with stale-value fallback.
- **Domain (`FanScopeKit/Domain`)**: Pure Swift entities (`FanToken`, `OrderBook`, `OnChainEvent`, `TokenHolder`, `SupplyMetrics`), verified mainnet contracts for 18 fan tokens (`TokenCatalog` & `KnownWalletRegistry`), repository protocols, and deterministic services (`OnChainFlowClassifier`, `OrderBookAnalyzer`).
- **Data (`FanScopeKit/Data`)**: Live repository implementations merging Paribu, CoinGecko, Ethereum Blockscout v2, and Chiliz Chain Routescan v2 endpoints with parallel fetching (`async let`) and partial-failure tolerance.

## Data Sources (Public, No API Key Required)

| Source | Data | Resilience |
| :--- | :--- | :--- |
| **Paribu Public API** | Live TRY tickers (`18` fan token pairs) and order book depth | 15s / 5s `TTLCache` |
| **CoinGecko Public API** | Circulating/total/max supply and 7-day sparkline points | 5m `TTLCache` + stale fallback on HTTP `429` |
| **Ethereum Blockscout v2** | On-chain supply, holders, mint/burn/transfer events (`FB`, `BJK`, `CHZ`) | 60s `TTLCache` + partial-failure isolation |
| **Chiliz Routescan v2** | On-chain supply, holders, and exchange wallet flows (`GAL`, `TRA`, `BAR`, `PSG`, etc.) | 60s `TTLCache` + partial-failure isolation |

## Technical Stack

- **Language & Concurrency:** Swift 6 (`SWIFT_STRICT_CONCURRENCY = complete`, `actor`, `Sendable`, `Synchronization.Mutex`)
- **UI & Persistence:** iOS 18+, SwiftUI (`@Observable`), UIKit interoperability, Swift Charts, SwiftData
- **Localization:** English & Turkish via `Localizable.xcstrings`
- **Testing & CI:** Apple `Swift Testing` (`@Suite`, `@Test`, `#expect`), host-isolated `MockURLProtocol`, GitHub Actions CI

## Running Locally

### Core & Data Unit Tests
```bash
cd Packages/FanScopeKit
swift test
```

### iOS Build
Open `FanScope.xcodeproj` in Xcode and run the `FanScope` scheme, or build from the command line:
```bash
xcodebuild build \
  -project FanScope.xcodeproj \
  -scheme FanScope \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

## Status

- [x] Phase 1: Project setup, local `FanScopeKit` package, design system, EN/TR localization, CI
- [x] Phase 2: `URLSessionHTTPClient`, actor `TTLCache`, domain entities, verified contract catalog, flow & order book analyzers
- [x] Phase 3: Paribu, CoinGecko, Blockscout, and Routescan data repositories + 33 unit tests
- [ ] Phase 4: Markets list, interactive charts, order book depth, on-chain activity feed, and Safari explorer sheet
- [ ] Phase 5: `SwiftData` watchlist, TRY price targets, and personal trade notes
- [ ] Phase 6: ViewModel test suite, UI polish, and app screenshots
