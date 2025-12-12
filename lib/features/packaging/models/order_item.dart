import 'package:equatable/equatable.dart';
import 'product.dart';

enum ItemStatus {
  pending,
  partial,
  packed;

  String get displayName {
    switch (this) {
      case ItemStatus.pending:
        return 'Pending';
      case ItemStatus.partial:
        return 'Partial';
      case ItemStatus.packed:
        return 'Packed';
    }
  }
}

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final Product? product; // Joined product data
  final int? positionNumber;
  final int quantityOrdered;
  final int quantityPacked;
  final ItemStatus status;
  final String? specialNotes;
  final DateTime createdAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.product,
    this.positionNumber,
    required this.quantityOrdered,
    this.quantityPacked = 0,
    required this.status,
    this.specialNotes,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      product: json['products'] != null 
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
      positionNumber: json['position_number'] as int?,
      quantityOrdered: json['quantity_ordered'] as int,
      quantityPacked: json['quantity_packed'] as int? ?? 0,
      status: _statusFromString(json['status'] as String),
      specialNotes: json['special_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static ItemStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ItemStatus.pending;
      case 'partial':
        return ItemStatus.partial;
      case 'packed':
        return ItemStatus.packed;
      default:
        return ItemStatus.pending;
    }
  }

  int get remainingQuantity => quantityOrdered - quantityPacked;
  
  bool get isComplete => quantityPacked >= quantityOrdered;
  
  double get progressPercentage => (quantityPacked / quantityOrdered) * 100;

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        quantityOrdered,
        quantityPacked,
        status,
      ];
}





