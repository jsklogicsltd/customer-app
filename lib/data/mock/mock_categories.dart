import '../../models/category.dart';

/// Flat AppCategory list used by the home/browse screens (unchanged structure).
final List<AppCategory> mockCategories = [
  AppCategory.fromMap({
    'id': 'cat001',
    'name': 'Textiles & Clothing',
    'nameUrdu': 'کپڑے اور لباس',
    'icon': '👗',
    'productCount': 150,
    'image': 'https://picsum.photos/seed/textiles/400/200',
    'subCategories': [
      'Abayas',
      "Women's Suits",
      "Men's Shalwar Kameez",
      'Kids Wear',
      'Shawls & Wraps',
      'Bridal Wear',
    ],
  }),
  AppCategory.fromMap({
    'id': 'cat002',
    'name': 'Embroidery & Handicrafts',
    'nameUrdu': 'کڑھائی اور دستکاری',
    'icon': '🪡',
    'productCount': 89,
    'image': 'https://picsum.photos/seed/embroidery/400/200',
    'subCategories': [
      'Phulkari',
      'Mirror Work',
      'Zardozi',
      'Kashmiri Embroidery',
      'Hand Painting',
    ],
  }),
  AppCategory.fromMap({
    'id': 'cat003',
    'name': 'Leather Goods',
    'nameUrdu': 'چمڑے کی اشیاء',
    'icon': '👜',
    'productCount': 45,
    'image': 'https://picsum.photos/seed/leather/400/200',
    'subCategories': [
      'Bags & Purses',
      'Belts & Wallets',
      'Footwear',
    ],
  }),
  AppCategory.fromMap({
    'id': 'cat004',
    'name': 'Pottery & Ceramics',
    'nameUrdu': 'مٹی کے برتن',
    'icon': '🏺',
    'productCount': 38,
    'image': 'https://picsum.photos/seed/pottery/400/200',
    'subCategories': [
      'Blue Pottery',
      'Decorative Pottery',
    ],
  }),
  AppCategory.fromMap({
    'id': 'cat005',
    'name': 'Woodwork & Furniture',
    'nameUrdu': 'لکڑی کا کام',
    'icon': '🪵',
    'productCount': 27,
    'image': 'https://picsum.photos/seed/wood/400/200',
    'subCategories': [
      'Carved Furniture',
      'Decorative Items',
    ],
  }),
  AppCategory.fromMap({
    'id': 'cat006',
    'name': 'Jewelry & Accessories',
    'nameUrdu': 'زیورات',
    'icon': '💍',
    'productCount': 62,
    'image': 'https://picsum.photos/seed/jewelry/400/200',
    'subCategories': [
      'Traditional Jewelry',
      'Fashion Jewelry',
    ],
  }),
];

/// 3-level hierarchy used by the Custom Request step-1 cascading dropdowns.
final List<Map<String, dynamic>> mockCategoriesHierarchy = [
  {
    'id': 'cat001',
    'name': 'Textiles & Clothing',
    'icon': '👗',
    'productCount': 150,
    'image': 'https://picsum.photos/seed/textiles/400/200',
    'subCategories': [
      {
        'name': 'Abayas',
        'productTypes': [
          'Pakistani Abaya',
          'Iranian Abaya',
          'Saudi Abaya',
          'Abaya with Embroidery',
          'Abaya with Lace',
          'Open-Front Abaya',
          'Niqab + Abaya Set',
        ],
      },
      {
        'name': "Women's Suits",
        'productTypes': [
          '2-Piece Suit',
          '3-Piece Suit',
          'Lawn Suit (Unstitched)',
          'Lawn Suit (Stitched)',
          'Bridal Suit',
          'Party Wear Suit',
          'Casual Suit',
          'Embroidered Suit',
        ],
      },
      {
        'name': "Men's Shalwar Kameez",
        'productTypes': [
          'Plain Shalwar Kameez',
          'Embroidered Kameez',
          'Khaddar Suit',
          'Linen Suit',
          'Silk Kurta',
          'Waistcoat Set',
          'Sherwani',
        ],
      },
      {
        'name': 'Kids Wear',
        'productTypes': [
          'Baby Girls Frock',
          'Baby Boys Shalwar Kameez',
          'Kids Party Wear',
          'Kids Casual Wear',
          'School Uniform (Custom)',
          'Newborn Set',
        ],
      },
      {
        'name': 'Shawls & Wraps',
        'productTypes': [
          'Pashmina Shawl',
          'Wool Shawl',
          'Silk Shawl',
          'Phulkari Dupatta',
          'Ajrak Dupatta',
          'Lawn Dupatta',
          'Hand-Embroidered Shawl',
        ],
      },
      {
        'name': 'Bridal Wear',
        'productTypes': [
          'Bridal Lehenga',
          'Bridal Sharara',
          'Bridal Gharara',
          'Bridal 3-Piece',
          'Nikkah Dress',
          'Walima Dress',
        ],
      },
    ],
  },
  {
    'id': 'cat002',
    'name': 'Embroidery & Handicrafts',
    'icon': '🪡',
    'productCount': 89,
    'image': 'https://picsum.photos/seed/embroidery/400/200',
    'subCategories': [
      {
        'name': 'Phulkari',
        'productTypes': [
          'Phulkari Dupatta',
          'Phulkari Shawl',
          'Phulkari Kurta',
          'Phulkari Table Runner',
          'Phulkari Cushion Cover',
        ],
      },
      {
        'name': 'Mirror Work',
        'productTypes': [
          'Mirror Work Kurta',
          'Mirror Work Dupatta',
          'Mirror Work Bag',
          'Mirror Work Wall Hanging',
          'Mirror Work Cushion',
        ],
      },
      {
        'name': 'Zardozi',
        'productTypes': [
          'Zardozi Bridal Dress',
          'Zardozi Dupatta',
          'Zardozi Clutch Bag',
          'Zardozi Decoration Piece',
        ],
      },
      {
        'name': 'Kashmiri Embroidery',
        'productTypes': [
          'Kashmiri Shawl',
          'Kashmiri Kurta',
          'Kashmiri Table Cloth',
          'Kashmiri Cushion Cover',
        ],
      },
      {
        'name': 'Hand Painting',
        'productTypes': [
          'Hand-Painted Fabric',
          'Hand-Painted Pottery',
          'Hand-Painted Canvas',
          'Hand-Painted Shoes',
        ],
      },
    ],
  },
  {
    'id': 'cat003',
    'name': 'Leather Goods',
    'icon': '👜',
    'productCount': 45,
    'image': 'https://picsum.photos/seed/leather/400/200',
    'subCategories': [
      {
        'name': 'Bags & Purses',
        'productTypes': [
          'Tote Bag',
          'Shoulder Bag',
          'Clutch Bag',
          'Backpack',
          'Office Bag',
          'Laptop Bag',
          'Ladies Handbag',
        ],
      },
      {
        'name': 'Belts & Wallets',
        'productTypes': [
          'Gents Belt',
          'Ladies Belt',
          'Gents Wallet',
          'Ladies Wallet',
          'Card Holder',
          'Passport Cover',
        ],
      },
      {
        'name': 'Footwear',
        'productTypes': [
          'Khussa (Traditional)',
          'Leather Sandals',
          'Leather Shoes (Men)',
          'Leather Shoes (Women)',
          'Mojari',
        ],
      },
    ],
  },
  {
    'id': 'cat004',
    'name': 'Pottery & Ceramics',
    'icon': '🏺',
    'productCount': 38,
    'image': 'https://picsum.photos/seed/pottery/400/200',
    'subCategories': [
      {
        'name': 'Blue Pottery',
        'productTypes': [
          'Blue Pottery Tea Set',
          'Blue Pottery Dinner Set',
          'Blue Pottery Vase',
          'Blue Pottery Plate',
          'Blue Pottery Mug',
          'Blue Pottery Gift Set',
        ],
      },
      {
        'name': 'Decorative Pottery',
        'productTypes': [
          'Decorative Vase',
          'Wall Plate',
          'Flower Pot',
          'Lantern',
          'Tile Set',
        ],
      },
    ],
  },
  {
    'id': 'cat005',
    'name': 'Woodwork & Furniture',
    'icon': '🪵',
    'productCount': 27,
    'image': 'https://picsum.photos/seed/wood/400/200',
    'subCategories': [
      {
        'name': 'Carved Furniture',
        'productTypes': [
          'Carved Chair',
          'Carved Side Table',
          'Carved Bed',
          'Carved Sofa Frame',
          'Carved Mirror Frame',
        ],
      },
      {
        'name': 'Decorative Items',
        'productTypes': [
          'Wooden Box (Lacquer)',
          'Wooden Frame',
          'Wooden Tray',
          'Camel Bone Inlay Box',
          'Wooden Wall Hanging',
        ],
      },
    ],
  },
  {
    'id': 'cat006',
    'name': 'Jewelry & Accessories',
    'icon': '💍',
    'productCount': 62,
    'image': 'https://picsum.photos/seed/jewelry/400/200',
    'subCategories': [
      {
        'name': 'Traditional Jewelry',
        'productTypes': [
          'Jhoomar / Passa',
          'Nath (Nose Ring)',
          'Tikka Set',
          'Rani Haar',
          'Kangan (Bangles Set)',
          'Payal (Anklet)',
          'Full Bridal Set',
        ],
      },
      {
        'name': 'Fashion Jewelry',
        'productTypes': [
          'Oxidised Necklace',
          'Statement Earrings',
          'Beaded Bracelet',
          'Hair Accessories',
          'Maang Tikka',
        ],
      },
    ],
  },
];
