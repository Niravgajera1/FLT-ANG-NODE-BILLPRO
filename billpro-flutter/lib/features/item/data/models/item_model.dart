class ItemModel {
  final String id;
  final String companyId;
  final String? itemCode;
  final String name;
  final String? description;
  final String itemType; // product | service
  final String? hsnCode;
  final String? sacCode;
  final String? category;
  final String? brand;
  final String unit;
  final double sellingPrice;
  final double purchasePrice;
  final double mrp;
  final bool priceInclGST;
  final double gstRate;
  final double cessRate;
  final bool isExempt;
  final String? itcEligibility; // full | partial | none | ineligible
  final bool trackInventory;
  final double openingStock;
  final double currentStock;
  final double reorderLevel;
  final double reorderQuantity;
  final String? warehouseLocation;
  final bool batchTracking;
  final String valuationMethod; // WAC | FIFO | LIFO
  final double avgCost;
  final bool isActive;
  final bool isSelling;
  final String? image;
  final String? notes;
  final String? createdAt;

  const ItemModel({
    required this.id,
    required this.companyId,
    this.itemCode,
    required this.name,
    this.description,
    required this.itemType,
    this.hsnCode,
    this.sacCode,
    this.category,
    this.brand,
    required this.unit,
    this.sellingPrice = 0,
    this.purchasePrice = 0,
    this.mrp = 0,
    this.priceInclGST = false,
    this.gstRate = 0,
    this.cessRate = 0,
    this.isExempt = false,
    this.itcEligibility,
    this.trackInventory = false,
    this.openingStock = 0,
    this.currentStock = 0,
    this.reorderLevel = 0,
    this.reorderQuantity = 0,
    this.warehouseLocation,
    this.batchTracking = false,
    this.valuationMethod = 'WAC',
    this.avgCost = 0,
    this.isActive = true,
    this.isSelling = true,
    this.image,
    this.notes,
    this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        id: json['_id'] ?? '',
        companyId: json['companyId'] ?? '',
        itemCode: json['itemCode'],
        name: json['name'] ?? '',
        description: json['description'],
        itemType: json['itemType'] ?? 'product',
        hsnCode: json['hsnCode'],
        sacCode: json['sacCode'],
        category: json['category'],
        brand: json['brand'],
        unit: json['unit'] ?? 'pcs',
        sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
        purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
        mrp: (json['mrp'] ?? 0).toDouble(),
        priceInclGST: json['priceInclGST'] ?? false,
        gstRate: (json['gstRate'] ?? 0).toDouble(),
        cessRate: (json['cessRate'] ?? 0).toDouble(),
        isExempt: json['isExempt'] ?? false,
        itcEligibility: json['itcEligibility'],
        trackInventory: json['trackInventory'] ?? false,
        openingStock: (json['openingStock'] ?? 0).toDouble(),
        currentStock: (json['currentStock'] ?? 0).toDouble(),
        reorderLevel: (json['reorderLevel'] ?? 0).toDouble(),
        reorderQuantity: (json['reorderQuantity'] ?? 0).toDouble(),
        warehouseLocation: json['warehouseLocation'],
        batchTracking: json['batchTracking'] ?? false,
        valuationMethod: json['valuationMethod'] ?? 'WAC',
        avgCost: (json['avgCost'] ?? 0).toDouble(),
        isActive: json['isActive'] ?? true,
        isSelling: json['is_selling'] ?? false,
        image: json['image'],
        notes: json['notes'],
        createdAt: json['createdAt'],
      );

  bool get isLowStock =>
      trackInventory && currentStock <= reorderLevel && reorderLevel > 0;

  ItemModel copyWith({bool? isActive}) => ItemModel(
        id: id,
        companyId: companyId,
        itemCode: itemCode,
        name: name,
        description: description,
        itemType: itemType,
        hsnCode: hsnCode,
        sacCode: sacCode,
        category: category,
        brand: brand,
        unit: unit,
        sellingPrice: sellingPrice,
        purchasePrice: purchasePrice,
        mrp: mrp,
        priceInclGST: priceInclGST,
        gstRate: gstRate,
        cessRate: cessRate,
        isExempt: isExempt,
        itcEligibility: itcEligibility,
        trackInventory: trackInventory,
        openingStock: openingStock,
        currentStock: currentStock,
        reorderLevel: reorderLevel,
        reorderQuantity: reorderQuantity,
        warehouseLocation: warehouseLocation,
        batchTracking: batchTracking,
        valuationMethod: valuationMethod,
        avgCost: avgCost,
        isActive: isActive ?? this.isActive,
        isSelling: isSelling,
        image: image,
        notes: notes,
        createdAt: createdAt,
      );
}
