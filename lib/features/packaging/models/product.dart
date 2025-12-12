import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String productCode;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? size;
  final String? color;
  final String? barcode;
  final String? qrCode;
  final double? weightKg;
  final String? dimensionsCm;
  final String? category;
  final bool active;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.productCode,
    required this.name,
    this.description,
    this.imageUrl,
    this.size,
    this.color,
    this.barcode,
    this.qrCode,
    this.weightKg,
    this.dimensionsCm,
    this.category,
    this.active = true,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      productCode: json['product_code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      size: json['size'] as String?,
      color: json['color'] as String?,
      barcode: json['barcode'] as String?,
      qrCode: json['qr_code'] as String?,
      weightKg: json['weight_kg'] != null 
          ? double.parse(json['weight_kg'].toString()) 
          : null,
      dimensionsCm: json['dimensions_cm'] as String?,
      category: json['category'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_code': productCode,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'size': size,
      'color': color,
      'barcode': barcode,
      'qr_code': qrCode,
      'weight_kg': weightKg,
      'dimensions_cm': dimensionsCm,
      'category': category,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName {
    final sizePart = size != null ? ', Size $size' : '';
    final colorPart = color != null ? ', $color' : '';
    return '$name$sizePart$colorPart';
  }

  @override
  List<Object?> get props => [
        id,
        productCode,
        name,
        barcode,
        size,
        color,
      ];
}





