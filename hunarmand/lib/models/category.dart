class AppCategory {
  final String id;
  final String name;
  final String nameUrdu;
  final String icon;
  final int productCount;
  final String image;
  final List<String> subCategories;

  const AppCategory({
    required this.id,
    required this.name,
    required this.nameUrdu,
    required this.icon,
    required this.productCount,
    required this.image,
    required this.subCategories,
  });

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'],
      name: map['name'],
      nameUrdu: map['nameUrdu'],
      icon: map['icon'],
      productCount: map['productCount'],
      image: map['image'],
      subCategories: List<String>.from(map['subCategories']),
    );
  }
}
