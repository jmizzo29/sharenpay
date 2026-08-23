# ShareNPay

Shared bills. Any bill. **ShareNPay never takes the money.**

Add a bill, split it evenly, and show who owes whom so everyone knows. Roommate rent is a common example — so is dinner, an Uber, utilities, or concert tickets. Settle outside the app on Venmo, Zelle, Cash App, or PayPal, then mark paid.

Sign in with Google. Bills live in Cloud Firestore on that Google account, so they survive a reinstall.

## Open and run

You need a Mac with **Xcode 15 or later** and the **iOS 17+** simulator.

1. Clone this repo.
2. Open `ShareNPay/ShareNPay.xcodeproj` in Xcode and let Swift packages resolve (Firebase Auth, Cloud Firestore, Google Sign-In).
3. Add your Firebase iOS config (below). Until you do, the app opens a setup screen and does not crash.
4. Select the **ShareNPay** scheme and an iPhone simulator.
5. Press Run.

## One-time Firebase / Google Cloud setup

Do this once. This repo does **not** ship a real Firebase project or API keys.

### 1. Create the Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Create a project (or use an existing one).
3. Add an **iOS** app.
4. iOS bundle ID must be **`com.sharenpay.app`**.
5. App nickname can be ShareNPay.
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
| Home | You owe / owed to you, add a bill, list of bills and who is unpaid |
| Bill | Even split, who owes whom, “Yes, that’s my share”, **Pay outside** (Venmo / Cash App / PayPal / Zelle / Mark paid), thread |
| Ledger | Who you owe and who owes you. Pay outside or mark paid |
| People | Anyone you split with — roommates, friends, whoever is on the bill |
| Profile | Name, Google account, reminders, reset demo, **Sign out** |

Composer on Home: note, amount, category, who paid, who splits.

## What v1 is not

- Not a payment processor. No Stripe, PayPal Checkout, cards, Braintree, or in-app rails.
- Not locked to one household. Rent with roommates is one kind of bill, not the product.
- Not a social Venmo feed.
- No email/password auth.

## Mock vs real money

**In this build**

- Firestore is the source of truth for the signed-in Google account
- SwiftData is a local cache only
- Confirming a share and marking paid change the ledger, not a bank
- Venmo / Cash App / PayPal / Zelle buttons open those apps (or their sites) with an amount and note
- PayPal is a paypal.me send-money link only

**Never in this repo**

Payment SDKs, live Firebase API keys, PayPal Checkout, Braintree, or anything that moves funds through ShareNPay.

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
```

Bundle ID: `com.sharenpay.app`. iOS 17. iPhone only.
