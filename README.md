# flutter-food-cart-hive-provider

A **Food Ordering App** with shopping cart, built in Flutter using **MVC**, **Provider**, **Hive**, and **Firebase Auth**.

## Assignment context

**Week 10 · Session 20** — Food cart with Provider and Hive  
**Continuation** — Dart extension methods, Firebase Auth, cash-on-delivery checkout, UI polish  

Repository: [devDoniaAlhosin/food-ordering-provider-hive](https://github.com/devDoniaAlhosin/food-ordering-provider-hive.git)

## Overview

Browse a sample food menu, search items, add them to a cart (with editions and special instructions), then check out with **cash on delivery**. Cart data persists locally with Hive. Users must **login / register** with Firebase Auth before ordering.

## What has been done

### Base S20 assignment
- Food menu (name, category, price, image) with sample data
- Shopping cart: add / increase / decrease / remove / clear
- Totals (quantity + price), empty-cart handling
- MVC + Provider (`ChangeNotifier`) + Hive cart persistence
- `AnimatedScale` / `AnimatedContainer` interactions

### Continuation extras
| Area | What was added |
|---|---|
| **Extensions** | Shared `TextField` / `TextFormField` styling & validators in `lib/extensions/` |
| **Search** | Menu search (`AppTextField.search`) |
| **Notes** | Special instructions on add-to-cart (`AppTextFormField.notes`), shown on cart lines |
| **Quantity field** | Editable cart quantity (`AppTextFormField.quantity`) |
| **Firebase Auth** | Login + Register (email/password), AuthGate, profile avatar + sign out |
| **Checkout** | Delivery form (name, phone, address) + **Cash on delivery** only |
| **UI polish** | Warm café theme, improved cards, login/register screens, greeting header |

## Features

- Food menu with search, category chips, and add-to-cart sheet
- Cart with notes, quantity editing, and checkout entry
- Firebase Auth login / register
- Profile menu (name + email) and sign out when logged in
- Checkout with cash on delivery
- Hive cart persistence across restarts
- Dart extension methods for form fields

## Technologies used

| Technology | Role |
|---|---|
| Flutter / Dart | UI framework |
| Provider | State management (`ChangeNotifier`) |
| Hive + hive_flutter | Local cart storage |
| Firebase Auth | Login / register |
| Material 3 | Theming (`lib/theme/app_theme.dart`) |

## Project folder structure

```
lib/
├── main.dart
├── firebase_options.dart
├── theme/app_theme.dart
├── Model/          # Food, OrderItem, CheckoutOrder
├── Controller/     # OrderController
├── Provider/       # OrderProvider, AppAuthProvider
├── Services/       # HiveCartService, AuthService
├── extensions/     # TextField / TextFormField helpers
├── data/           # sample_foods.dart
└── View/
    ├── auth_gate.dart
    ├── auth/login_screen.dart
    ├── auth/register_screen.dart
    ├── food_menu_screen.dart
    ├── cart_screen.dart
    ├── checkout_screen.dart
    └── widgets/food_card.dart
```

## Auth & checkout flow

```text
Login / Register (Firebase Auth)
        ↓
   Food Menu → Cart → Checkout (Cash on delivery)
        ↓
   Place order → clear cart → confirmation dialog
```

### Checkout (cash on delivery)
1. Open cart → tap **Checkout**
2. Enter **full name**, **phone**, and **delivery address**
3. Payment method is fixed to **Cash on delivery**
4. Tap **Place order (COD)** → cart clears → success dialog

## Firebase Auth setup

1. Create a Firebase project and enable **Email/Password** auth  
2. Run:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
flutter run
```

Configured project example: `project-app-7d6f5`

## Installation & run

```bash
git clone https://github.com/devDoniaAlhosin/food-ordering-provider-hive.git
cd food-ordering-provider-hive
flutter pub get
flutter run
```

## Dart extension methods

| Extension | Purpose |
|---|---|
| `AppInputDecoration` | Shared outlined / search / notes / quantity decorations |
| `AppTextField` | Menu search |
| `AppTextFormField` | notes, quantity, email, password, fullName, phone, address |
| `StringValidators` | email, password, phone, required, max-length, positive int |

## Screenshots

Screenshots live in `screenshots/` (also under `docs/screenshots/`).

### Login
Firebase email/password sign-in screen.

![Login](screenshots/login.png)

### Register
Create account with full name, email, and password confirmation.

![Register](screenshots/register.png)

### Logged-in food menu
Greeting + profile avatar menu (name/email + Sign out), search, cart badge, and food grid.

![Logged in menu](screenshots/menu_logged_in.png)

### Firebase Auth users (generated output)
Users created from the app appear in Firebase Console → Authentication → Users.

![Firebase users](screenshots/firebase_users.png)

### Menu search
![Menu search](screenshots/menu_search.png)

### Special instructions
![Special instructions](screenshots/add_instructions.png)

### Cart
![Your Cart](screenshots/cart.png)

### Cart notes / comments
![Cart notes](screenshots/cart_notes.png)

### Food menu (catalog)
![Food Menu](screenshots/menu.png)

## License

Educational project for Week 10, Session 20 (with continuation features).
