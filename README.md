# flutter-food-cart-hive-provider

A simple **Food Ordering App** with a shopping cart, built in Flutter using **MVC architecture**, **Provider** for state management, and **Hive** for local cart persistence.

## Assignment context

**Week 10 · Session 20** — Food cart with Provider and Hive.

Repository: [devDoniaAlhosin/food-ordering-provider-hive](https://github.com/devDoniaAlhosin/food-ordering-provider-hive.git)

## Overview

Browse a sample food menu, add items (with optional editions / customizations) to a cart, adjust quantities, and clear the cart. Cart contents are saved locally with Hive and restored when the app restarts.

## Features

- Food menu with name, category, price, and image (sample catalog)
- Add items to cart with edition selection (e.g. size or spice level)
- Increase / decrease quantities and remove individual items
- Clear entire cart
- Live total quantity and total price
- Empty-cart state and invalid-quantity guards
- Provider + `ChangeNotifier` state updates
- Hive persistence across app restarts
- Graceful handling of Hive load / save errors
- Responsive grid layout with `AnimatedScale` and `AnimatedContainer`
- Menu search field (`AppTextField.search`)
- Optional special instructions on add-to-cart (`AppTextFormField.notes`), shown as cart comments
- Editable cart quantity field (`AppTextFormField.quantity`)
- Dart extension methods for shared `TextField` / `TextFormField` styling and validation

## Technologies used

| Technology | Role |
|---|---|
| Flutter / Dart | UI framework |
| Provider | State management (`ChangeNotifier`) |
| Hive + hive_flutter | Local NoSQL cart storage |
| Material 3 | App theming and components |

## Project folder structure

```
lib/
├── main.dart                 # Hive init, Provider wiring, app entry
├── Model/
│   ├── food.dart             # Food model + FoodAdapter
│   └── order_item.dart       # OrderItem model + OrderItemAdapter
├── Controller/
│   └── order_controller.dart # Cart business logic
├── Provider/
│   └── order_provider.dart   # ChangeNotifier + Hive sync
├── Services/
│   └── hive_cart_service.dart
├── extensions/               # Reusable TextField / TextFormField helpers
│   ├── input_decoration_extensions.dart
│   ├── text_field_extensions.dart
│   ├── text_form_field_extensions.dart
│   └── string_validators.dart
├── data/
│   └── sample_foods.dart     # Sample menu catalog
└── View/
    ├── food_menu_screen.dart
    ├── cart_screen.dart
    └── widgets/
        └── food_card.dart
```

## Dart extension methods

Repeated `TextField` / `TextFormField` configuration (borders, padding, icons, and validators) lives in `lib/extensions/` so screens stay focused on layout and behavior.

| Extension | Purpose |
|---|---|
| `AppInputDecoration` | Shared outlined / search / notes / quantity decorations |
| `AppTextField` | `AppTextField.search(...)` menu search field |
| `AppTextFormField` | `notes(...)` and `quantity(...)` form fields |
| `StringValidators` | Max-length and positive-integer validators |

**Where they are used**
- **Food menu** — `AppTextField.search` filters the catalog by name or category.
- **Add-to-cart sheet** — `AppTextFormField.notes` captures optional special instructions (validated, persisted on `OrderItem`).
- **Cart** — `AppTextFormField.quantity` lets you type a quantity directly (validated; still supports +/- buttons).

Provider, Hive persistence, and MVC boundaries are unchanged; extensions only standardize UI input widgets.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.12+ recommended)
- Android Studio / VS Code with Flutter plugins
- A connected device, emulator, or Chrome for web

## Installation

```bash
git clone https://github.com/devDoniaAlhosin/food-ordering-provider-hive.git
cd food-ordering-provider-hive
flutter pub get
```

Code generation is **not required**. `Food` and `OrderItem` use hand-written Hive `TypeAdapter`s registered in `HiveCartService.init()`.

## Run the application

```bash
flutter run
```

Optional checks:

```bash
flutter analyze
flutter test
```

## MVC, Provider, and Hive integration

1. **Model** — `Food` and `OrderItem` hold data and serialization helpers.
2. **Controller** — `OrderController` owns cart rules (add, merge by food+edition, quantity changes, totals, clear). It does **not** call `notifyListeners()`.
3. **Provider** — `OrderProvider` wraps the controller, calls `notifyListeners()` after changes, and persists through `HiveCartService`.
4. **View** — Screens only read/write via `context.watch` / `context.read` — no cart logic in widgets.
5. **Services** — `HiveCartService` initializes Hive, registers adapters, and loads/saves the cart box.

```text
UI (View)  →  OrderProvider  →  OrderController
                    ↓
              HiveCartService  →  Hive box
```

## Cart persistence

- On startup, `main.dart` calls `HiveCartService.init()` then `OrderProvider.initialize()`.
- After every successful cart mutation, items are written to the `cart_box` Hive box under key `order_items`.
- Clearing the cart deletes the persisted key.
- If Hive fails to init or save, the UI shows a snackbar / banner and continues with in-memory state where possible.

## Screenshots

Screenshots are stored in the `screenshots/` folder (also mirrored under `docs/screenshots/`).

### Food Menu
Sample catalog in a responsive grid, with name, category, price, image, and a cart badge.

![Food Menu](screenshots/menu.png)

### Menu search (`AppTextField.search`)
Search field filters food by name or category. Uses the shared outlined decoration, search icon, and clear button from `lib/extensions/`.

![Menu search](screenshots/menu_search.png)

### Special instructions (`AppTextFormField.notes`)
Add-to-cart sheet includes an optional notes `TextFormField` (max 80 characters) with shared validation and decoration.

![Special instructions](screenshots/add_instructions.png)

### Your Cart
Cart lines with edition, quantity controls (+/− and editable quantity field), remove/clear actions, and live totals.

![Your Cart](screenshots/cart.png)

### Cart comments / notes
Special instructions entered on the add sheet appear under each cart line (e.g. `dd`, `extra souce`) and are persisted with Hive.

![Cart notes](screenshots/cart_notes.png)

## License

Educational project for Week 10, Session 20.
