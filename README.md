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
├── data/
│   └── sample_foods.dart     # Sample menu catalog
└── View/
    ├── food_menu_screen.dart
    ├── cart_screen.dart
    └── widgets/
        └── food_card.dart
```

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

Screenshots are stored in the `screenshots/` folder.

### Food Menu
Shows the sample catalog in a responsive 2-column grid, with name, category, price, image, and a cart badge when items are added.

![Food Menu](screenshots/menu.png)

### Your Cart
Shows cart lines with edition (e.g. Regular), quantity controls, remove/clear actions, and live item count + total price.

![Your Cart](screenshots/cart.png)

## License

Educational project for Week 10, Session 20.
