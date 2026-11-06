# DigiNiwas — Login / OTP / Forgot-Password setup

## Mode
`lib/core/config/auth_config.dart`
- Buyer, Seller, Partner -> sab OTP-only Firebase login: `POST /api/auths/firebase-phone-login` body `{idToken, role}`
- Seller/Partner ko PDF OTP (`/auths/login-otp/*`) par rakhna ho to `firebaseRoles` se hata do.
- Partner/Seller login screens ab common OTP screen hain (email/password login UI hat gaya).

## Backend dev se confirm karo
0. `/auths/firebase-phone-login` me role `seller` / `partner` support hai? Aur route public whitelist me hai? (Pehle 'Token missing' 401 aaya tha.)
1. PDF-1 base `/api/v1` bolta hai, par Firebase PDF `/api/auths/...` (bina v1). `login-otp/*` aur `forgot/reset` paths me `/v1` sahi hai ya nahi? (404 aaye to `/v1` hata do.)
2. Forgot/reset body: assumed `{phone, otp, newPassword, confirmPassword, resetToken?}`.
3. Firebase login phone `+91XXXXXXXXXX` format me save karta hai; `/auths/register` 10-digit save kare to duplicate buyer ban sakta hai.

## Firebase Console
1. Authentication -> Sign-in method -> Phone: Enable.
2. Android: `cd android && ./gradlew signingReport` -> SHA-1 + SHA-256 Firebase project settings me add karo.
3. Naya `google-services.json` download karke `android/app/` me replace karo.
4. iOS: APNs key upload + `GoogleService-Info.plist`.
5. Testing: Authentication -> Phone -> "Phone numbers for testing".
6. Real SMS ke liye Blaze plan chahiye.

## Debug prints
Console me `[AUTH]` filter karo. Tags: FIREBASE, API, CTRL, OTP, FORGOT.
Common errors:
- `app-not-authorized` / `invalid-app-credential` -> SHA keys missing.
- `operation-not-allowed` -> Phone sign-in enable nahi.
- `[API] 404` -> endpoint path galat (ApiConstants).
- `[API] 401/400` + body -> backend ne idToken/role reject kiya, body print me dikhega.
