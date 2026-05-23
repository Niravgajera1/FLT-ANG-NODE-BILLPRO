class ItemCategoryModel {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const ItemCategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) => ItemCategoryModel(
        id: json['_id'] ?? '',
        companyId: json['companyId'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
      };
}
