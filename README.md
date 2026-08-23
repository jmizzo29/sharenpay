# ShareNPay

A household bill-sharing app for roommates. Track rent, utilities, wifi, and house groceries. **ShareNPay never takes the money.**

Settle outside the app — Venmo, Cash App, PayPal, or Zelle — then mark the share paid. That is the resurrection path: a house ledger, not a money transmitter.

## Open and run

You need a Mac with **Xcode 15 or later** and the **iOS 17+** simulator.

1. Clone this repo.
2. Open `ShareNPay/ShareNPay.xcodeproj` in Xcode.
3. Select the **ShareNPay** scheme and an iPhone simulator.
4. Press Run.

First launch opens the **300 West** household: you, Maya, and Jordan, with this month’s rent, electric, internet, and house groceries already on the ledger.

## What v1 is

| Screen | What it does |
| --- | --- |
| Home | Household name, this month’s totals, add a house bill, list of bills and who is unpaid |
| Bill | Shares, “Yes, that’s my share”, **Pay outside** (Venmo / Cash App / PayPal / Zelle / Mark paid), house thread |
| Ledger | Who you owe and who owes you. Pay outside or mark paid |
| Household | The roommates |
| Profile | Name, household name, reset demo |

Composer on Home: note, amount, category (rent / electric / internet / groceries / other), who paid, who splits.

## What v1 is not

- Not a payment processor. No Stripe, PayPal, cards, or in-app rails.
- Not a social Venmo feed. No salon, vacation, club dues, or classifieds in v1.
- Friends-and-family dinners can come later.

## Mock vs real money

**In this build**

- SwiftData on this iPhone
- Confirming a share and marking paid only change the household ledger
- Venmo / Cash App / PayPal / Zelle buttons open those apps (or their sites) with an amount and note
- PayPal is a paypal.me send-money link only — not Checkout, Braintree, or any ShareNPay rail
- If the other app is not installed, iOS will say so. Copy the Zelle note and pay in your bank app

**Never in this repo**

Payment SDKs, API keys, PayPal Checkout, Braintree, or anything that moves funds through ShareNPay. Last time, compliance cost killed the company.

## Architecture

SwiftUI + SwiftData + `PaymentService` (house ledger) + `ExternalSettle` (outbound links only).

Statuses: **Open** (still confirming or unpaid) → **Confirmed** (roommates agreed the split) → **Paid** (every share marked paid). Money still leaves via Venmo, Cash App, PayPal, or Zelle.

## Visual

White / near-white, black text, one ink accent `#1B2A4A`. Dark mark with a white N. White tab bar.

## Project layout

```
ShareNPay/ShareNPay.xcodeproj
ShareNPay/ShareNPay/
ShareNPay/ShareNPayTests/
```

Bundle ID: `com.sharenpay.app`. iOS 17. iPhone only.
