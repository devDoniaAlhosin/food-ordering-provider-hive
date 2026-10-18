# flutter-food-cart-hive-provider

A **Food Ordering App** with shopping cart, built in Flutter using **MVC**, **Provider**, **Hive**, **Firebase Auth**, and **Cloud Firestore**.

## Assignment context

| Session | Focus |
|---|---|
| **Week 10 · Session 20** | Food cart with Provider and Hive |
| **Week 11 · Session 21** | Dart extensions (form fields, validators, search helpers) |
| **Week 11 · Session 22** | Firebase Auth, COD checkout, UI polish |
| **Week 12 · Session 23** | Firestore users CRUD, profile, **roles** (`user` / `admin`) |

Repository: [devDoniaAlhosin/food-ordering-provider-hive](https://github.com/devDoniaAlhosin/food-ordering-provider-hive.git)

## Overview

Browse a sample food menu, search items, add them to a cart (with editions and special instructions), then check out with **cash on delivery**. Cart data persists locally with Hive. Users **login / register** with Firebase Auth; each account is stored in Firestore `users/{uid}`.

**Access control (Session 23):**
- Every signed-in user manages **only their own account** via **My profile**.
- **Manage users** (list / create / edit / delete all users) is available **only to admins**.

## What has been done

### Base S20
- Food menu, cart CRUD, totals, Hive persistence, MVC + Provider

### Session 21 — Extensions
- Dart field extensions, validators, search helpers
- Notes / quantity field helpers used across forms

### Session 22 — Auth & checkout
- Firebase Auth login / register
- COD checkout, UI theme polish

### Session 23 — Firestore users + roles
| Area | What was added |
|---|---|
| **UserFirestoreService** | Create / read / update / delete on `users` collection |
| **AppUser model** | `uid`, `email`, `fullName`, `phone`, `address`, **`role`**, timestamps |
| **Roles** | `user` (default) · `admin` (can manage all users) |
| **UserProvider** | Current profile, `isAdmin`, admin-gated users CRUD |
| **Register sync** | Creates Firestore doc after Auth register (`role: user`) |
| **Profile screen** | Each user edits **own** name / phone / address · can **delete own account** |
| **Users list** | **Admin only** — add Auth+Firestore user, edit role/fields, delete |
| **Menu avatar** | My profile for everyone · Manage users **only if admin** · Sign out |
| **Checkout** | Prefills delivery fields from Firestore profile |

## Features

- Food menu with search, notes, cart, COD checkout
- Firebase Auth login / register
- Firestore user profile (self-service edit + delete account)
- Admin role with full users management
- Hive cart persistence
- Dart extension methods for form fields

## Technologies used

| Technology | Role |
|---|---|
| Flutter / Dart | UI framework |
| Provider | State management |
| Hive | Local cart storage |
| Firebase Auth | Login / register |
| Cloud Firestore | Users CRUD + roles |
| Material 3 | Theming |

## Project folder structure

```
lib/
├── main.dart
├── firebase_options.dart
├── theme/app_theme.dart
├── Model/
│   ├── food.dart
│   ├── order_item.dart
│   ├── checkout_order.dart
│   └── app_user.dart
├── Controller/order_controller.dart
├── Provider/
│   ├── order_provider.dart
│   ├── auth_provider.dart
│   └── user_provider.dart
├── Services/
│   ├── hive_cart_service.dart
│   ├── auth_service.dart
│   └── user_firestore_service.dart
├── extensions/
├── data/sample_foods.dart
└── View/
    ├── auth_gate.dart
    ├── auth/login_screen.dart
    ├── auth/register_screen.dart
    ├── food_menu_screen.dart
    ├── cart_screen.dart
    ├── checkout_screen.dart
    ├── profile_screen.dart
    ├── users_list_screen.dart
    └── widgets/food_card.dart
```

## Auth + Firestore + roles flow

```text
Register / Login (Firebase Auth)
        ↓
Create / load Firestore users/{uid}  (role defaults to "user")
        ↓
Food Menu
  ├─ My profile     → any user edits own account
  └─ Manage users   → admin only (CRUD + set role)
        ↓
Cart → Checkout (COD, prefilled from profile)
```

### UserFirestoreService (CRUD)
- Collection: `users`
- `createUser` · `getUser` · `getAllUsers` / `watchUsers` · `updateUser` · `deleteUser`

### Firestore document shape
```text
users/{uid}
  uid, email, fullName, phone, address, role, createdAt, updatedAt

role: "user" | "admin"
```

### How to make the first admin
1. Register / sign in once so a `users/{uid}` document exists.
2. In **Firebase Console → Firestore**, open that document.
3. Add or edit field **`role`** (string) → value **`admin`**.
4. Restart / re-open the app (or sign out and sign in).  
   The avatar menu shows **Manage users** only for that account.

New registrations always get `role: "user"`. An existing admin can promote others from **Manage users**.

## Firebase setup

1. Enable **Authentication → Email/Password**
2. Enable **Cloud Firestore** (start in test mode for the assignment, or use the rules below)
3. Run:
```bash
flutterfire configure
flutter pub get
flutter run
```

Configured project example: `project-app-7d6f5`

### Suggested Firestore rules (assignment / demo)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      // Own profile: any signed-in user can update their doc
      allow create, update: if request.auth != null
        && request.auth.uid == userId;
      // Admins can manage any user doc
      allow create, update, delete: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

> For a quick classroom demo you may temporarily allow `read, write` for authenticated users; tighten rules before production.

## Installation & run

```bash
git clone https://github.com/devDoniaAlhosin/food-ordering-provider-hive.git
cd food-ordering-provider-hive
flutter pub get
flutter run
```

## Screenshots

Screenshots live in `screenshots/` (also under `docs/screenshots/`).

### Session 23 — Firestore + Profile

Document fields: `uid`, `email`, `fullName`, `phone`, `address`, `role`, `createdAt`, `updatedAt`.

<table>
  <tr>
    <td align="center" width="33%"><img src="screenshots/profile.png" alt="My Profile" /><br/><sub>My Profile (edit + delete account)</sub></td>
    <td align="center" width="67%" colspan="2"><img src="screenshots/firestore_users.png" alt="Firestore users document" /><br/><sub>Firestore <code>users</code> collection</sub></td>
  </tr>
</table>

### Session 23 — Admin user management

Admin avatar menu shows **Manage users**. Admins can list users and create **user** or **admin** accounts.

<table>
  <tr>
    <td align="center" width="33%"><img src="screenshots/admin_menu.png" alt="Admin menu" /><br/><sub>Admin menu · Manage users</sub></td>
    <td align="center" width="33%"><img src="screenshots/manage_users.png" alt="Manage users list" /><br/><sub>Manage users list</sub></td>
    <td align="center" width="33%"><img src="screenshots/admin_add_user.png" alt="Add user with role" /><br/><sub>Add user · role user/admin</sub></td>
  </tr>
</table>

### App screens (3 per row)

<table>
  <tr>
    <td align="center" width="33%"><img src="screenshots/login.png" alt="Login" /><br/><sub>Login</sub></td>
    <td align="center" width="33%"><img src="screenshots/register.png" alt="Register" /><br/><sub>Register</sub></td>
    <td align="center" width="33%"><img src="screenshots/menu_logged_in.png" alt="Logged in menu" /><br/><sub>Logged-in menu</sub></td>
  </tr>
  <tr>
    <td align="center" width="33%"><img src="screenshots/firebase_users.png" alt="Firebase Auth users" /><br/><sub>Firebase Auth users</sub></td>
    <td align="center" width="33%"><img src="screenshots/menu_search.png" alt="Menu search" /><br/><sub>Menu search</sub></td>
    <td align="center" width="33%"><img src="screenshots/add_instructions.png" alt="Special instructions" /><br/><sub>Special instructions</sub></td>
  </tr>
  <tr>
    <td align="center" width="33%"><img src="screenshots/cart.png" alt="Cart" /><br/><sub>Cart</sub></td>
    <td align="center" width="33%"><img src="screenshots/cart_notes.png" alt="Cart notes" /><br/><sub>Cart notes</sub></td>
    <td align="center" width="33%"><img src="screenshots/menu.png" alt="Food menu" /><br/><sub>Food menu</sub></td>
  </tr>
</table>

## License

Educational project for Week 10–12 (Sessions 20–23: S20 cart, S21 extensions, S22 Auth/checkout, S23 Firestore users).
