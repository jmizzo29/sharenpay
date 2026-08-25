# Zeroed

Shared bills. Any bill. **Zeroed never takes the money.** Bills stay open until they are zeroed out.

Add a bill, split it evenly, and show who owes whom so everyone knows. Roommate rent is a common example — so is dinner, an Uber, utilities, or concert tickets. Settle outside the app on Venmo, Zelle, Cash App, or PayPal, then mark paid.

Sign in with Google. Bills live in Cloud Firestore on that Google account, so they survive a reinstall.

## Open and run

You need a Mac with **Xcode 15 or later** and the **iOS 17+** simulator.

1. Clone this repo.
2. Open `ShareNPay/ShareNPay.xcodeproj` in Xcode and let Swift packages resolve (Firebase Auth, Cloud Firestore, Google Sign-In).
3. Add your Firebase iOS config (below). Until you do, the app opens a setup screen and does not crash.
4. Select the iOS app scheme and an iPhone simulator. The home-screen name is **Zeroed**.
5. Press Run.

## One-time Firebase / Google Cloud setup

Do this once. This repo does **not** ship a real Firebase project or API keys.

### 1. Create the Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Create a project (or use an existing one).
3. Add an **iOS** app.
4. iOS bundle ID must be **`com.sharenpay.app`**.
5. App nickname can be Zeroed.
6. Download **GoogleService-Info.plist**.

### 2. Drop in the iOS config

1. Replace `ShareNPay/ShareNPay/GoogleService-Info.plist` with the file Firebase downloaded.  
   (The file in git is a placeholder. A copy of the template is `ShareNPay/ShareNPay/GoogleService-Info.plist.example`.)
2. Open `ShareNPay/ShareNPay/Info.plist`.
3. Set **GIDClientID** to the plist’s `CLIENT_ID` (ends in `.apps.googleusercontent.com`).
4. Set the URL scheme to the plist’s **REVERSED_CLIENT_ID** (`com.googleusercontent.apps.…`).  
   Google sign-in will not return to the app until that URL scheme matches.

### 3. Enable Google sign-in

1. In Firebase: **Authentication → Sign-in method → Google → Enable**.
2. Set a support email.
3. In [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials, confirm an **iOS OAuth client** exists for bundle ID `com.sharenpay.app`.
4. If you add a new iOS client, download a fresh GoogleService-Info.plist and repeat step 2.

### 4. Create Firestore and lock it down

1. In Firebase: **Build → Firestore Database → Create database**.
2. Start in **production** mode (rules stay closed).
3. Deploy the rules in this repo so a user can only read/write their own people and bills they participate in:

```
firebase deploy --only firestore:rules
```

Rules file: `firebase/firestore.rules`.  
`firebase.json` already points at that file.

Do not leave Firestore open (`allow read, write: if true`).

### 5. Run

Launch the app. First screen is **Continue with Google**. A new Google account gets the sample bills once. After that, every add / confirm / mark paid / note writes to Firestore.

Sign out is on Profile.

## What v1 is

| Screen | What it does |
| --- | --- |
| Setup | Shown when GoogleService-Info.plist is missing or still the placeholder |
| Sign in | Sign in with Google only. No email/password |
| Home | You owe / owed to you, natural-language composer, receipt capture, list of bills |
| Bill | Even split, who owes whom, due copy, **Pay outside** (Venmo / Cash App / PayPal / Zelle / Mark paid), thread |
| Ledger | Who you owe and who owes you. Pay outside or mark paid |
| People | Anyone you split with — roommates, friends, whoever is on the bill |
| Profile | Name, Google account, reminders, reset demo, **Sign out** |

Composer on Home: type **What’s the bill?** — `April rent 1800 with Maya` or `dinner 86.40 Maya Jordan` fills amount, people, and title. Confirm **Looks right** before it posts. Camera / photo reads a receipt on-device (Vision) for merchant + total; you confirm, then split.

A bill can be **monthly** (rent, wifi, electric). The app shows next due and optional local reminders. It never auto-charges anyone.

Opening Venmo / PayPal / Cash App / Zelle prefills `April rent · your share $900.00`.

## What v1 is not

- Not a payment processor. No Stripe, PayPal Checkout, cards, Braintree, or in-app rails.
- Not locked to one household. Rent with roommates is one kind of bill, not the product.
- Not a social Venmo feed.
- No email/password auth.
- Not a chatbot. The composer parses a bill line. It does not chat.

## Mock vs real money

**In this build**

- Firestore is the source of truth for the signed-in Google account
- SwiftData is a local cache only
- Confirming a share and marking paid change the ledger, not a bank
- Venmo / Cash App / PayPal / Zelle buttons open those apps (or their sites) with an amount and note
- PayPal is a paypal.me send-money link only

**Never in this repo**

Payment SDKs, live Firebase API keys, PayPal Checkout, Braintree, or anything that moves funds through Zeroed.

## Architecture

SwiftUI + Firebase Auth (Google) + Cloud Firestore + SwiftData cache + `PaymentService` + `ExternalSettle`.

A user can only read/write `/users/{theirUid}` and `/bills/{id}` documents whose `participantUIDs` include their Firebase Auth UID.

Statuses: **Open** → **Confirmed** → **Paid**. Money still leaves via Venmo, Cash App, PayPal, or Zelle.

## Visual

White / near-white and dark, black text, one ink accent `#1B2A4A`. Large type, tight hierarchy, hairlines instead of chunky cards. Money uses SF Rounded.

## Project layout

```
ShareNPay/ShareNPay.xcodeproj
ShareNPay/ShareNPay/
ShareNPay/ShareNPayTests/
firebase/firestore.rules
web/
```

The marketing site lives in `web/`.

Bundle ID: `com.sharenpay.app`. iOS 17. iPhone only.
