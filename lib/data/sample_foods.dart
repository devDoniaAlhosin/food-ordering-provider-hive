import '../Model/food.dart';

/// Sample food catalog used when no remote API is available.
const List<Food> sampleFoods = [
  Food(
    id: 'f1',
    name: 'Classic Burger',
    category: 'Burgers',
    price: 8.99,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
    description: 'Beef patty, lettuce, tomato, and house sauce.',
    editions: ['Regular', 'Double'],
  ),
  Food(
    id: 'f2',
    name: 'Margherita Pizza',
    category: 'Pizza',
    price: 12.50,
    imageUrl:
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
    description: 'Tomato, mozzarella, and fresh basil.',
    editions: ['Small', 'Medium', 'Large'],
  ),
  Food(
    id: 'f3',
    name: 'Chicken Shawarma',
    category: 'Wraps',
    price: 7.25,
    imageUrl:
        'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400',
    description: 'Grilled chicken with garlic sauce and pickles.',
    editions: ['Regular', 'Spicy'],
  ),
  Food(
    id: 'f4',
    name: 'Caesar Salad',
    category: 'Salads',
    price: 6.75,
    imageUrl:
        'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400',
    description: 'Romaine, croutons, parmesan, and Caesar dressing.',
    editions: ['Regular', 'Large'],
  ),
  Food(
    id: 'f5',
    name: 'Sushi Combo',
    category: 'Sushi',
    price: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400',
    description: 'Assorted rolls with soy sauce and wasabi.',
    editions: ['8 pcs', '12 pcs'],
  ),
  Food(
    id: 'f6',
    name: 'Chocolate Milkshake',
    category: 'Drinks',
    price: 4.50,
    imageUrl:
        'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400',
    description: 'Rich chocolate shake topped with whipped cream.',
    editions: ['Regular', 'Large'],
  ),
  Food(
    id: 'f7',
    name: 'Pasta Alfredo',
    category: 'Pasta',
    price: 11.25,
    imageUrl:
        'https://images.unsplash.com/photo-1645112411341-6c4fd023882c?w=400',
    description: 'Creamy Alfredo sauce with fettuccine.',
    editions: ['Regular', 'Extra cheese'],
  ),
  Food(
    id: 'f8',
    name: 'French Fries',
    category: 'Sides',
    price: 3.99,
    imageUrl:
        'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
    description: 'Crispy golden fries with sea salt.',
    editions: ['Small', 'Large'],
  ),
];
