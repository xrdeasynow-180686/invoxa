class Item {
  String name;
  int quantity;
  double price;

  Item({
    this.name = '',
    this.quantity = 1,
    this.price = 0.0,
  });

  double get total => quantity * price;
}
