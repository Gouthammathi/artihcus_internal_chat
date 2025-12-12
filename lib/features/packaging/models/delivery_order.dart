import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  assigned,
  inProgress,
  packed,
  shipped,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case OrderStatus.assigned:
        return const Color(0xFF2196F3); // Blue
      case OrderStatus.inProgress:
        return const Color(0xFF9C27B0); // Purple
      case OrderStatus.packed:
        return const Color(0xFF4CAF50); // Green
      case OrderStatus.shipped:
        return const Color(0xFF009688); // Teal
      case OrderStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }
}

class DeliveryOrder extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerId;
  final String? deliveryAddress;
  final String? specialInstructions;
  final OrderStatus status;
  final int priority;
  final int totalItems;
  final int packedItems;
  final String? assignedTo;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? packedAt;
  final String? packedBy;
  final DateTime createdAt;

  const DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerId,
    this.deliveryAddress,
    this.specialInstructions,
    required this.status,
    this.priority = 0,
    this.totalItems = 0,
    this.packedItems = 0,
    this.assignedTo,
    this.assignedAt,
    this.startedAt,
    this.packedAt,
    this.packedBy,
    required this.createdAt,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerName: json['customer_name'] as String,
      customerId: json['customer_id'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      status: _statusFromString(json['status'] as String),
      priority: json['priority'] as int? ?? 0,
      totalItems: json['total_items'] as int? ?? 0,
      packedItems: json['packed_items'] as int? ?? 0,
      assignedTo: json['assigned_to'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      packedAt: json['packed_at'] != null
          ? DateTime.parse(json['packed_at'] as String)
          : null,
      packedBy: json['packed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static OrderStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'assigned':
        return OrderStatus.assigned;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'packed':
        return OrderStatus.packed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case OrderStatus.inProgress:
        return 'in_progress';
      default:
        return status.name;
    }
  }

  double get progressPercentage {
    if (totalItems == 0) return 0.0;
    return (packedItems / totalItems) * 100;
  }

  bool get isComplete => packedItems >= totalItems;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        packedItems,
        totalItems,
      ];
}

