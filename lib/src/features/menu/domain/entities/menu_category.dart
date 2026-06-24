class MenuCategory {
  const MenuCategory({this.id, required this.name});

  final int? id;
  final String name;

  MenuCategory copyWith({int? id, String? name}) {
    return MenuCategory(id: id ?? this.id, name: name ?? this.name);
  }
}
