# ShareNPay

A 2026 rebuild of John Mitchell’s Salt Lake City social-payments product (Share N Pay, Inc., ~2009–2017). This is the original idea — **record a shared expense like a tweet, talk it through, agree, then settle** — not a Venmo clone.

v1 is a native **SwiftUI iPhone app** with a **local mock ledger**. Nothing here moves real money.

## Open and run

You need a Mac with **Xcode 15 or later** and the **iOS 17+** simulator.

1. Clone this repo.
2. Open `ShareNPay/ShareNPay.xcodeproj` in Xcode.
3. Select the **ShareNPay** scheme and an **iPhone** simulator (iPhone 15 or newer is fine).
4. Press Run.

On first launch the app seeds a demo table: roommates, friends, family, and Rio Grande Salon. Sign in with any display name — it stays on the device.

Light and dark mode follow the system appearance.

To run the ledger tests in Xcode: Product → Test (the **ShareNPayTests** target).

## What works in v1

| Flow | What it does |
| --- | --- |
| Onboarding / sign-in | Local mock account, persisted with SwiftData |
| Activity | Feed of shares with note, people, amount, and status |
| New expense | Tweet-style composer (160-character note + amount + category + people). Even split. Starts **pending** |
| Pay / request | One person, one amount, then the same agree → settle path |
| Transaction detail | Thread to discuss, **Agree**, then **Settle on the mock ledger** |
| Balances | Who you owe and who owes you, with settle-up |
| People | Seeded friends, family, and one independent business |
| You | Display name, notifications toggle stub, reset demo, sign out |

2013 use cases live as categories: roommate rent, restaurant, salon/dentist, vacation, club dues, friends & family.

2011 ideas — classifieds, location deals, in-app browser for group activities — are **not built**. They appear as disabled “Coming later” rows on the People tab so the extension point is obvious.

## Mock vs future rails

**Mock (this build)**

- SwiftData on-device store
- `PaymentService` is the only place balances move
- Agree / settle / settle-up only change local numbers
- No accounts, cards, PayPal, banks, or network calls

**Not in v1 — and must not be bolted on casually**

The 2010 product settled through PayPal or cards. A future `PaymentService` implementation could sit behind the same API. That is a regulated money-transmitter problem. This repo ships **no payment SDKs and no API keys**.

## Architecture

SwiftUI + SwiftData + a small `PaymentService`, as hypothesized.

- **Models** — `Person`, `Payment`, `SplitShare`, `ThreadMessage`, `AppAccount`
- **LedgerMath** — even splits (leftover pennies to the first seats) and net balances; Foundation-only so it is easy to test
- **PaymentService** — create, comment, agree, settle, settle-up, seed, reset
- **DemoCatalog** — first-launch people and six sample shares

Statuses: **pending** (still talking) → **agreed** (everyone who must approve has tapped Agree) → **settled** (mock ledger closed).

That conversation-and-approval loop is the product. The public-feed model is the thing this rebuild refuses to become.

## Project layout

```
ShareNPay/ShareNPay.xcodeproj
ShareNPay/ShareNPay/          # app target
ShareNPay/ShareNPayTests/     # ledger + service tests
```

Bundle ID: `com.sharenpay.app`. Deployment target: iOS 17. iPhone only.
