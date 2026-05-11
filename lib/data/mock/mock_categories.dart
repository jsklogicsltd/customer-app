import '../../models/category.dart';

final List<AppCategory> mockCategories = [
  AppCategory.fromMap({
    'id': 'cat001',
    'name': 'Women Clothing',
    'nameUrdu': 'خواتین کے کپڑے',
    'icon': '👗',
    'productCount': 120,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Fwomen_clothing.png?alt=media',
    'subCategories': ['Casual Wear', 'Formal Wear', 'Traditional Wear', 'Party / Wedding Wear', 'Winter Wear', 'Night Wear'],
  }),
  AppCategory.fromMap({
    'id': 'cat002',
    'name': 'Men Clothing',
    'nameUrdu': 'مردانہ کپڑے',
    'icon': '👕',
    'productCount': 85,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Fmen_clothing.png?alt=media',
    'subCategories': ['Casual', 'Traditional', 'Formal', 'Winter'],
  }),
  AppCategory.fromMap({
    'id': 'cat003',
    'name': 'Kids Clothing',
    'nameUrdu': 'بچوں کے کپڑے',
    'icon': '👶',
    'productCount': 60,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Fkids_clothing.png?alt=media',
    'subCategories': ['Baby Wear', 'Girls Wear', 'Boys Wear', 'School Wear', 'Party Wear'],
  }),
  AppCategory.fromMap({
    'id': 'cat004',
    'name': 'Fabric / Cloth',
    'nameUrdu': 'کپڑا / فیبرک',
    'icon': '🧵',
    'productCount': 200,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Ffabric.png?alt=media',
    'subCategories': ['Lawn', 'Cotton', 'Linen', 'Silk', 'Chiffon', 'Khaddar', 'Denim', 'Wool'],
  }),
  AppCategory.fromMap({
    'id': 'cat005',
    'name': 'Handcrafted Clothing',
    'nameUrdu': 'ہاتھ سے بنے کپڑے',
    'icon': '🪡',
    'productCount': 45,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Fhandmade.png?alt=media',
    'subCategories': ['Hand Embroidered', 'Crochet', 'Knitted', 'Hand Painted', 'Mirror Work', 'Patchwork'],
  }),
  AppCategory.fromMap({
    'id': 'cat006',
    'name': 'Accessories',
    'nameUrdu': 'اشیاء',
    'icon': '🧣',
    'productCount': 110,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Faccessories.png?alt=media',
    'subCategories': ['Dupatta', 'Hijab / Scarf', 'Shawl', 'Handbags', 'Clutches', 'Belts'],
  }),
  AppCategory.fromMap({
    'id': 'cat007',
    'name': 'Custom Stitching',
    'nameUrdu': 'سلائی کی خدمات',
    'icon': '🧥',
    'productCount': 30,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Fcustom_stitching.png?alt=media',
    'subCategories': ['Dress Stitching', 'Bridal Custom', 'Kids Custom', 'Family Matching'],
  }),
  AppCategory.fromMap({
    'id': 'cat008',
    'name': 'Embroidery Services',
    'nameUrdu': 'کڑھائی کی خدمات',
    'icon': '🪡',
    'productCount': 25,
    'image': 'https://firebasestorage.googleapis.com/v0/b/karsaazi-app.appspot.com/o/categories%2Fembroidery_services.png?alt=media',
    'subCategories': ['Hand Embroidery', 'Machine Embroidery', 'Lace Work', 'Beads Work', 'Custom Name'],
  }),
];

final List<Map<String, dynamic>> mockCategoriesHierarchy = [
  {
    'id': 'cat001',
    'name': 'Women\'s Clothing',
    'icon': '👗',
    'subCategories': [
      {
        'name': 'Casual Wear',
        'icon': '👗',
        'productTypes': [
          {'name': 'Kurti (Short)', 'icon': '👗'},
          {'name': 'Kurti (Long)', 'icon': '👗'},
          {'name': 'Tops / Tunics', 'icon': '👚'},
          {'name': 'T-Shirts', 'icon': '👕'},
        ],
      },
      {
        'name': 'Formal Wear',
        'icon': '💃',
        'productTypes': [
          {'name': '2 Piece Suit', 'icon': '🧥'},
          {'name': '3 Piece Suit', 'icon': '👔'},
          {'name': 'Office Wear', 'icon': '💼'},
        ],
      },
      {
        'name': 'Traditional Wear',
        'icon': '🕌',
        'productTypes': [
          {'name': 'Shalwar Kameez', 'icon': '🕌'},
          {'name': 'Lehenga', 'icon': '✨'},
          {'name': 'Gharara / Sharara', 'icon': '💃'},
        ],
      },
      {
        'name': 'Party / Wedding Wear',
        'icon': '✨',
        'productTypes': [
          {'name': 'Bridal Dresses', 'icon': '👰'},
          {'name': 'Maxi / Gown', 'icon': '💃'},
          {'name': 'Fancy Dresses', 'icon': '✨'},
        ],
      },
      {
        'name': 'Winter Wear',
        'icon': '❄️',
        'productTypes': [
          {'name': 'Shawls', 'icon': '🧣'},
          {'name': 'Sweaters', 'icon': '🧥'},
          {'name': 'Coats', 'icon': '🧥'},
        ],
      },
      {
        'name': 'Night Wear',
        'icon': '🌙',
        'productTypes': [
          {'name': 'Night Suits', 'icon': '😴'},
          {'name': 'Robes', 'icon': '👘'},
        ],
      },
    ],
  },
  {
    'id': 'cat002',
    'name': 'Men\'s Clothing',
    'icon': '👔',
    'subCategories': [
      {
        'name': 'Casual',
        'icon': '👕',
        'productTypes': [
          {'name': 'T-Shirts', 'icon': '👕'},
          {'name': 'Shirts', 'icon': '👔'},
        ],
      },
      {
        'name': 'Traditional',
        'icon': '🕌',
        'productTypes': [
          {'name': 'Kurta', 'icon': '👕'},
          {'name': 'Shalwar Kameez', 'icon': '🕌'},
          {'name': 'Waistcoat', 'icon': '🧥'},
        ],
      },
      {
        'name': 'Formal',
        'icon': '👔',
        'productTypes': [
          {'name': 'Dress Shirts', 'icon': '👔'},
          {'name': 'Pants', 'icon': '👖'},
        ],
      },
      {
        'name': 'Winter',
        'icon': '❄️',
        'productTypes': [
          {'name': 'Jackets', 'icon': '🧥'},
          {'name': 'Hoodies', 'icon': '🧥'},
        ],
      },
    ],
  },
  {
    'id': 'cat003',
    'name': 'Kids Clothing',
    'icon': '👶',
    'subCategories': [
      {
        'name': 'Baby Wear',
        'icon': '🍼',
        'productTypes': [
          {'name': '0–2 years', 'icon': '👶'},
        ],
      },
      {
        'name': 'Girls Wear',
        'icon': '👧',
        'productTypes': [
          {'name': 'Casual', 'icon': '👗'},
          {'name': 'Party', 'icon': '✨'},
        ],
      },
      {
        'name': 'Boys Wear',
        'icon': '👦',
        'productTypes': [
          {'name': 'Casual', 'icon': '👕'},
          {'name': 'Formal', 'icon': '👔'},
        ],
      },
      {
        'name': 'School Wear',
        'icon': '🎒',
        'productTypes': [
          {'name': 'Uniform', 'icon': '👔'},
        ],
      },
      {
        'name': 'Party Wear',
        'icon': '🎉',
        'productTypes': [
          {'name': 'Fancy', 'icon': '✨'},
        ],
      },
    ],
  },
  {
    'id': 'cat004',
    'name': 'Stitching Service',
    'icon': '🪡',
    'subCategories': [
      {
        'name': 'Women\'s Stitching',
        'icon': '👗',
        'productTypes': [
          {'name': 'Shalwar Kameez', 'icon': '🕌'},
          {'name': 'Kurti / Shirt', 'icon': '👕'},
          {'name': 'Frock / Maxi', 'icon': '👗'},
          {'name': 'Abaya / Hijab', 'icon': '🧕'},
          {'name': 'Lehenga / Saree', 'icon': '✨'},
        ],
      },
      {
        'name': 'Men\'s Stitching',
        'icon': '👔',
        'productTypes': [
          {'name': 'Shalwar Kameez', 'icon': '🕌'},
          {'name': 'Kurta / Pajama', 'icon': '👕'},
          {'name': 'Waistcoat', 'icon': '🧥'},
          {'name': 'Pant Coat', 'icon': '👔'},
        ],
      },
      {
        'name': 'Home Textile',
        'icon': '🏠',
        'productTypes': [
          {'name': 'Curtains', 'icon': '🪟'},
          {'name': 'Cushion Covers', 'icon': '🛋️'},
          {'name': 'Bed Sheets', 'icon': '🛏️'},
          {'name': 'Table Cloth', 'icon': '🍽️'},
        ],
      },
      {
        'name': 'Alterations',
        'icon': '✂️',
        'productTypes': [
          {'name': 'Resizing', 'icon': '📏'},
          {'name': 'Repairing', 'icon': '🪡'},
          {'name': 'Designing', 'icon': '🎨'},
        ],
      },
    ],
  },
  {
    'id': 'cat005',
    'name': 'Handcrafted Clothing',
    'icon': '🪡',
    'subCategories': [
      {
        'name': 'Hand Embroidered',
        'icon': '🪡',
        'productTypes': [
          {'name': 'Dresses', 'icon': '👗'},
          {'name': 'Shawls', 'icon': '🧣'},
        ],
      },
      {
        'name': 'Crochet',
        'icon': '🧶',
        'productTypes': [
          {'name': 'Tops', 'icon': '👚'},
          {'name': 'Baby sets', 'icon': '👶'},
        ],
      },
      {
        'name': 'Knitted',
        'icon': '🧶',
        'productTypes': [
          {'name': 'Sweaters', 'icon': '🧥'},
          {'name': 'Caps', 'icon': '🧶'},
        ],
      },
      {
        'name': 'Hand Painted',
        'icon': '🎨',
        'productTypes': [
          {'name': 'Dresses', 'icon': '👗'},
          {'name': 'Dupattas', 'icon': '🧣'},
        ],
      },
      {
        'name': 'Mirror Work',
        'icon': '🪞',
        'productTypes': [
          {'name': 'Dresses', 'icon': '👗'},
          {'name': 'Vests', 'icon': '🧥'},
        ],
      },
      {
        'name': 'Patchwork',
        'icon': '🧩',
        'productTypes': [
          {'name': 'Jackets', 'icon': '🧥'},
          {'name': 'Dresses', 'icon': '👗'},
        ],
      },
    ],
  },
  {
    'id': 'cat006',
    'name': 'Accessories',
    'icon': '👜',
    'subCategories': [
      {
        'name': 'Dupatta',
        'icon': '🧣',
        'productTypes': [
          {'name': 'Embroidered', 'icon': '🪡'},
          {'name': 'Net', 'icon': '🧣'},
          {'name': 'Silk', 'icon': '✨'},
        ],
      },
      {
        'name': 'Hijab / Scarf',
        'icon': '🧕',
        'productTypes': [
          {'name': 'Jersey', 'icon': '🧣'},
          {'name': 'Chiffon', 'icon': '🧣'},
        ],
      },
      {
        'name': 'Shawl',
        'icon': '🧣',
        'productTypes': [
          {'name': 'Pashmina', 'icon': '🧣'},
          {'name': 'Wool', 'icon': '🧶'},
        ],
      },
      {
        'name': 'Handbags',
        'icon': '👜',
        'productTypes': [
          {'name': 'Embroidered', 'icon': '🪡'},
          {'name': 'Leather', 'icon': '👜'},
        ],
      },
      {
        'name': 'Clutches',
        'icon': '👛',
        'productTypes': [
          {'name': 'Fancy', 'icon': '✨'},
          {'name': 'Casual', 'icon': '👛'},
        ],
      },
      {
        'name': 'Belts',
        'icon': '🎫',
        'productTypes': [
          {'name': 'Leather', 'icon': '🎫'},
          {'name': 'Fabric', 'icon': '🎫'},
        ],
      },
    ],
  },
  {
    'id': 'cat007',
    'name': 'Custom Stitching',
    'icon': '🧥',
    'subCategories': [
      {
        'name': 'Dress Stitching',
        'icon': '👗',
        'productTypes': [
          {'name': 'Casual', 'icon': '🧵'},
          {'name': 'Formal', 'icon': '🪡'},
        ],
      },
      {
        'name': 'Bridal Custom',
        'icon': '👰',
        'productTypes': [
          {'name': 'Lehenga', 'icon': '✨'},
          {'name': 'Maxi', 'icon': '💃'},
        ],
      },
      {
        'name': 'Kids Custom',
        'icon': '👶',
        'productTypes': [
          {'name': 'Boys', 'icon': '👦'},
          {'name': 'Girls', 'icon': '👧'},
        ],
      },
      {
        'name': 'Family Matching',
        'icon': '👨‍👩‍👧‍👦',
        'productTypes': [
          {'name': 'Mother-Daughter', 'icon': '👩‍👧'},
          {'name': 'Father-Son', 'icon': '👨‍👦'},
        ],
      },
    ],
  },
  {
    'id': 'cat008',
    'name': 'Embroidery Services',
    'icon': '🪡',
    'subCategories': [
      {
        'name': 'Hand Embroidery',
        'icon': '🪡',
        'productTypes': [
          {'name': 'Tilla', 'icon': '✨'},
          {'name': 'Mirror', 'icon': '🪞'},
          {'name': 'Beads', 'icon': '🔮'},
        ],
      },
      {
        'name': 'Machine Embroidery',
        'icon': '🧵',
        'productTypes': [
          {'name': 'Computerized', 'icon': '⚙️'},
          {'name': 'Simple', 'icon': '🧵'},
        ],
      },
      {
        'name': 'Lace Work',
        'icon': '🎀',
        'productTypes': [
          {'name': 'Fancy', 'icon': '✨'},
          {'name': 'Simple', 'icon': '🎀'},
        ],
      },
      {
        'name': 'Beads Work',
        'icon': '🔮',
        'productTypes': [
          {'name': 'Full Body', 'icon': '🔮'},
          {'name': 'Neckline', 'icon': '🔮'},
        ],
      },
      {
        'name': 'Custom Name',
        'icon': '📝',
        'productTypes': [
          {'name': 'Apparel', 'icon': '👕'},
          {'name': 'Gifts', 'icon': '🎁'},
        ],
      },
    ],
  },
];
