class InventoryItem {
  final int id;
  final int siteId;
  final String itemName;
  final String category;
  final int quantity;
  final int? totalCapacity;
  final String unit;
  final String status; // 'healthy', 'low_stock', 'reorder'
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.siteId,
    required this.itemName,
    required this.category,
    required this.quantity,
    this.totalCapacity,
    required this.unit,
    required this.status,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      siteId: json['site_id'],
      itemName: json['item_name'],
      category: json['category'],
      quantity: json['quantity'],
      totalCapacity: json['total_capacity'],
      unit: json['unit'],
      status: json['status'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'total_capacity': totalCapacity,
      'unit': unit,
      'status': status,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  bool get isLowStock => status == 'low_stock' || status == 'reorder';
  bool get isHealthy => status == 'healthy';
  
  double? get stockPercentage {
    if (totalCapacity == null || totalCapacity == 0) return null;
    return quantity / totalCapacity!;
  }
}
