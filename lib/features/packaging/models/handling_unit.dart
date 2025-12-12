import 'package:equatable/equatable.dart';

enum HUStatus {
  open,
  sealed,
  shipped;

  String get displayName {
    switch (this) {
      case HUStatus.open:
        return 'Open';
      case HUStatus.sealed:
        return 'Sealed';
      case HUStatus.shipped:
        return 'Shipped';
    }
  }

  String get dbValue => name;
}

enum ContainerType {
  smallBox,
  mediumBox,
  largeBox,
  pallet,
  custom;

  String get displayName {
    switch (this) {
      case ContainerType.smallBox:
        return 'Small Box';
      case ContainerType.mediumBox:
        return 'Medium Box';
      case ContainerType.largeBox:
        return 'Large Box';
      case ContainerType.pallet:
        return 'Pallet';
      case ContainerType.custom:
        return 'Custom';
    }
  }

  String get dbValue {
    switch (this) {
      case ContainerType.smallBox:
        return 'small_box';
      case ContainerType.mediumBox:
        return 'medium_box';
      case ContainerType.largeBox:
        return 'large_box';
      case ContainerType.pallet:
        return 'pallet';
      case ContainerType.custom:
        return 'custom';
    }
  }

  static ContainerType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'small_box':
        return ContainerType.smallBox;
      case 'medium_box':
        return ContainerType.mediumBox;
      case 'large_box':
        return ContainerType.largeBox;
      case 'pallet':
        return ContainerType.pallet;
      default:
        return ContainerType.custom;
    }
  }
}

class HandlingUnit extends Equatable {
  final String id;
  final String huNumber;
  final String? orderId;
  final ContainerType? containerType;
  final double? weightKg;
  final String? dimensionsCm;
  final HUStatus status;
  final String? trackingNumber;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? sealedAt;
  final String? sealedBy;
  final int itemCount; // Number of items in this container

  const HandlingUnit({
    required this.id,
    required this.huNumber,
    this.orderId,
    this.containerType,
    this.weightKg,
    this.dimensionsCm,
    required this.status,
    this.trackingNumber,
    required this.createdAt,
    this.createdBy,
    this.sealedAt,
    this.sealedBy,
    this.itemCount = 0,
  });

  factory HandlingUnit.fromJson(Map<String, dynamic> json) {
    return HandlingUnit(
      id: json['id'] as String,
      huNumber: json['hu_number'] as String,
      orderId: json['order_id'] as String?,
      containerType: json['container_type'] != null
          ? ContainerType.fromString(json['container_type'] as String)
          : null,
      weightKg: json['weight_kg'] != null
          ? double.parse(json['weight_kg'].toString())
          : null,
      dimensionsCm: json['dimensions_cm'] as String?,
      status: _statusFromString(json['status'] as String),
      trackingNumber: json['tracking_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
      sealedAt: json['sealed_at'] != null
          ? DateTime.parse(json['sealed_at'] as String)
          : null,
      sealedBy: json['sealed_by'] as String?,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  static HUStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return HUStatus.open;
      case 'sealed':
        return HUStatus.sealed;
      case 'shipped':
        return HUStatus.shipped;
      default:
        return HUStatus.open;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hu_number': huNumber,
      'order_id': orderId,
      'container_type': containerType?.dbValue,
      'weight_kg': weightKg,
      'dimensions_cm': dimensionsCm,
      'status': status.dbValue,
      'tracking_number': trackingNumber,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'sealed_at': sealedAt?.toIso8601String(),
      'sealed_by': sealedBy,
    };
  }

  bool get isOpen => status == HUStatus.open;
  bool get isSealed => status == HUStatus.sealed;

  @override
  List<Object?> get props => [id, huNumber, status, itemCount];
}

class PackedItem extends Equatable {
  final String id;
  final String huId;
  final String? orderItemId;
  final String productId;
  final int quantity;
  final DateTime packedAt;
  final String? packedBy;

  const PackedItem({
    required this.id,
    required this.huId,
    this.orderItemId,
    required this.productId,
    required this.quantity,
    required this.packedAt,
    this.packedBy,
  });

  factory PackedItem.fromJson(Map<String, dynamic> json) {
    return PackedItem(
      id: json['id'] as String,
      huId: json['hu_id'] as String,
      orderItemId: json['order_item_id'] as String?,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      packedAt: DateTime.parse(json['packed_at'] as String),
      packedBy: json['packed_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hu_id': huId,
      'order_item_id': orderItemId,
      'product_id': productId,
      'quantity': quantity,
      'packed_at': packedAt.toIso8601String(),
      'packed_by': packedBy,
    };
  }

  @override
  List<Object?> get props => [id, huId, productId, quantity];
}



