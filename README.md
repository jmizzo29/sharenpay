# ShareNPay

Shared bills. Any bill. **ShareNPay never takes the money.**

Add a bill, split it evenly, and show who owes whom so everyone knows. Roommate rent is a common example — so is dinner, an Uber, utilities, or concert tickets. Settle outside the app on Venmo, Zelle, Cash App, or PayPal, then mark paid.

## Open and run

You need a Mac with **Xcode 15 or later** and the **iOS 17+** simulator.

1. Clone this repo.
2. Open `ShareNPay/ShareNPay.xcodeproj` in Xcode.
3. Select the **ShareNPay** scheme and an iPhone simulator.
4. Press Run.

First launch seeds sample people and mixed bills: August rent (you, Maya, Jordan), Red Iguana (you, Maya, Priya), an Uber (you, Jordan), and The National tickets (you, Jordan, Priya).

## What v1 is

| Screen | What it does |
| --- | --- |
| Home | You owe / owed to you, add a bill, list of bills and who is unpaid |
| Bill | Even split, who owes whom, “Yes, that’s my share”, **Pay outside** (Venmo / Cash App / PayPal / Zelle / Mark paid), thread |
| Ledger | Who you owe and who owes you. Pay outside or mark paid |
| People | Anyone you split with — roommates, friends, whoever is on the bill |
| Profile | Name, reminders, reset demo |

Composer on Home: note, amount, category (dinner / ride / tickets / rent / electric / internet / groceries / other), who paid, who splits. Pick the people for that bill — not a fixed household roster.

## What v1 is not

- Not a payment processor. No Stripe, PayPal Checkout, cards, Braintree, or in-app rails.
- Not locked to one household. Rent with roommates is one kind of bill, not the product.
- Not a social Venmo feed.

## Mock vs real money

**In this build**

- SwiftData on this iPhone
- Confirming a share and marking paid only change the ledger
- Venmo / Cash App / PayPal / Zelle buttons open those apps (or their sites) with an amount and note
- PayPal is a paypal.me send-money link only — not Checkout, Braintree, or any ShareNPay rail
- If the other app is not installed, iOS will say so. Copy the Zelle note and pay in your bank app

**Never in this repo**

Payment SDKs, API keys, PayPal Checkout, Braintree, or anything that moves funds through ShareNPay. Last time, compliance cost killed the company.

## Architecture

SwiftUI + SwiftData + `PaymentService` (shared-bill ledger) + `ExternalSettle` (outbound links only).

Statuses: **Open** (still confirming or unpaid) → **Confirmed** (everyone agreed the split) → **Paid** (every share marked paid). Money still leaves via Venmo, Cash App, PayPal, or Zelle.

## Visual

White / near-white and dark, black text, one ink accent `#1B2A4A`. Large type, tight hierarchy, hairlines instead of chunky cards. Money uses SF Rounded. Dark mark with a white N. White tab bar.

## Project layout

```
ShareNPay/ShareNPay.xcodeproj
ShareNPay/ShareNPay/
ShareNPay/ShareNPayTests/
```

Bundle ID: `com.sharenpay.app`. iOS 17. iPhone only.
