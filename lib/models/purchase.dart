class Purchase {
  final int? id;
  final String name;
  final double cost;
  final String purchaseDate;
  final String category;
  final int expectedLifespan;

  Purchase({this.id, required this.name, required this.cost, required this.purchaseDate, required this.category, required this.expectedLifespan});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'cost': cost,
    'purchaseDate': purchaseDate,
    'category': category,
    'expectedLifespan': expectedLifespan,
  };

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
    id: map['id'],
    name: map['name'],
    cost: map['cost'],
    purchaseDate: map['purchaseDate'],
    category: map['category'],
    expectedLifespan: map['expectedLifespan'],
  );
}
