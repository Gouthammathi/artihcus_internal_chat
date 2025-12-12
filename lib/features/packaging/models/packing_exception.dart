import 'package:equatable/equatable.dart';

enum ExceptionType {
  missing,
  damaged,
  wrongQuantity,
  wrongProduct,
  other;

  String get displayName {
    switch (this) {
      case ExceptionType.missing:
        return 'Missing Item';
      case ExceptionType.damaged:
        return 'Damaged';
      case ExceptionType.wrongQuantity:
        return 'Wrong Quantity';
      case ExceptionType.wrongProduct:
        return 'Wrong Product';
      case ExceptionType.other:
        return 'Other';
    }
  }

  String get dbValue {
    switch (this) {
      case ExceptionType.wrongQuantity:
        return 'wrong_quantity';
      case ExceptionType.wrongProduct:
        return 'wrong_product';
      default:
        return name;
    }
  }
}

class PackingException extends Equatable {
  final String id;
  final String orderId;
  final String? orderItemId;
  final String? productId;
  final ExceptionType exceptionType;
  final String description;
  final int? quantityAffected;
  final bool resolved;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime createdAt;
  final String? createdBy;

  const PackingException({
    required this.id,
    required this.orderId,
    this.orderItemId,
    this.productId,
    required this.exceptionType,
    required this.description,
    this.quantityAffected,
    this.resolved = false,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
    this.createdBy,
  });

  factory PackingException.fromJson(Map<String, dynamic> json) {
    return PackingException(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderItemId: json['order_item_id'] as String?,
      productId: json['product_id'] as String?,
      exceptionType: _typeFromString(json['exception_type'] as String),
      description: json['description'] as String,
      quantityAffected: json['quantity_affected'] as int?,
      resolved: json['resolved'] as bool? ?? false,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  static ExceptionType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'missing':
        return ExceptionType.missing;
      case 'damaged':
        return ExceptionType.damaged;
      case 'wrong_quantity':
        return ExceptionType.wrongQuantity;
      case 'wrong_product':
        return ExceptionType.wrongProduct;
      default:
        return ExceptionType.other;
    }
  }

  @override
  List<Object?> get props => [id, orderId, exceptionType, resolved];
}





