# 📦 Packaging Feature - Complete Development Guide

**Project:** Artihcus Internal Chat App - Packaging Module  
**Version:** 1.0  
**Last Updated:** December 2, 2025

---

## 📑 Table of Contents

1. [Overview](#overview)
2. [Features & Requirements](#features--requirements)
3. [Database Schema](#database-schema)
4. [App Architecture](#app-architecture)
5. [Implementation Steps](#implementation-steps)
6. [UI/UX Design](#uiux-design)
7. [Code Structure](#code-structure)
8. [Testing Guide](#testing-guide)
9. [Deployment Checklist](#deployment-checklist)
10. [User Guide](#user-guide)

---

## 🎯 Overview

### Purpose
Add a warehouse packaging/packing station feature to the existing Artihcus Internal Chat app. This feature allows warehouse staff to scan products, pack delivery orders, manage containers, and track packing operations.

### Key Objectives
- ✅ Keep existing attendance QR feature
- 📦 Add product scanning and packing workflow
- 📋 Track delivery orders and packing progress
- 🏷️ Manage shipping containers/handling units
- 📊 View packing history and analytics
- ⚠️ Handle packing exceptions

### Target Users
- **Warehouse Staff** - Pack orders
- **Supervisors** - Monitor operations
- **Admin** - Manage products and orders

---

## 🔧 Features & Requirements

### Core Features (MVP - Week 1-2)

#### 1. Order Management
- [ ] View list of pending delivery orders
- [ ] Filter orders by status (pending, in progress, completed)
- [ ] Search orders by order number or customer
- [ ] View order details (items, quantities, instructions)
- [ ] Assign order to current user
- [ ] Mark order as complete

#### 2. Product Scanning
- [ ] Scan product barcodes using camera
- [ ] Scan QR codes on products
- [ ] Manual product code entry (fallback)
- [ ] Display product details after scan
- [ ] Validate scanned product against order
- [ ] Audio/haptic feedback on successful scan

#### 3. Packing Workflow
- [ ] View items to pack for current order
- [ ] Check off items as they're packed
- [ ] Track packed vs. remaining quantities
- [ ] Display special packing instructions
- [ ] Verify all items packed before completion
- [ ] Real-time progress updates

#### 4. Container Management (HU - Handling Units)
- [ ] Create new shipping container
- [ ] Assign products to containers
- [ ] View container contents
- [ ] Track multiple containers per order
- [ ] Seal/close container
- [ ] Generate container label

#### 5. Packing History
- [ ] View completed orders
- [ ] See packing timestamps
- [ ] Track who packed each order
- [ ] View container details
- [ ] Export packing reports

### Advanced Features (Phase 2 - Week 3-4)

#### 6. Weight Verification
- [ ] Record package weight
- [ ] Compare with expected weight
- [ ] Weight tolerance validation
- [ ] Alert on weight mismatch

#### 7. Exception Handling
- [ ] Report missing items
- [ ] Report damaged products
- [ ] Report quantity mismatches
- [ ] Add notes to exceptions
- [ ] Notify supervisors
- [ ] Track exception resolution

#### 8. Label Printing
- [ ] Generate shipping labels (PDF)
- [ ] Print labels via mobile print
- [ ] QR code on labels
- [ ] Barcode generation

#### 9. Analytics Dashboard
- [ ] Orders packed per day
- [ ] Average packing time
- [ ] Efficiency metrics
- [ ] Exception rate tracking

---

## 💾 Database Schema

### SQL Schema for Supabase

```sql
-- ============================================
-- PACKAGING MODULE - DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Products Table
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  image_url TEXT,
  size VARCHAR(50),
  color VARCHAR(50),
  barcode VARCHAR(100) UNIQUE,
  qr_code VARCHAR(100),
  weight_kg DECIMAL(10,3),
  dimensions_cm VARCHAR(50), -- e.g., "30x20x10"
  category VARCHAR(100),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Delivery Orders Table
CREATE TABLE IF NOT EXISTS delivery_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  customer_id VARCHAR(100),
  delivery_address TEXT,
  special_instructions TEXT,
  status VARCHAR(50) DEFAULT 'pending', 
  -- Status: pending, assigned, in_progress, packed, shipped, cancelled
  priority INTEGER DEFAULT 0, -- Higher number = higher priority
  total_items INTEGER DEFAULT 0,
  packed_items INTEGER DEFAULT 0,
  assigned_to UUID REFERENCES users(id),
  assigned_at TIMESTAMP WITH TIME ZONE,
  started_at TIMESTAMP WITH TIME ZONE,
  packed_at TIMESTAMP WITH TIME ZONE,
  packed_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Order Items Table (Products in each order)
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES delivery_orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  position_number INTEGER, -- Line item number in order
  quantity_ordered INTEGER NOT NULL,
  quantity_packed INTEGER DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending', -- pending, partial, packed
  special_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Handling Units (Shipping Containers/Boxes)
CREATE TABLE IF NOT EXISTS handling_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hu_number VARCHAR(100) UNIQUE NOT NULL,
  order_id UUID REFERENCES delivery_orders(id),
  container_type VARCHAR(100), -- Box type: small, medium, large, pallet, etc.
  weight_kg DECIMAL(10,3),
  dimensions_cm VARCHAR(50),
  status VARCHAR(50) DEFAULT 'open', -- open, sealed, shipped
  tracking_number VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  sealed_at TIMESTAMP WITH TIME ZONE,
  sealed_by UUID REFERENCES users(id)
);

-- 5. Packed Items (Contents of each container)
CREATE TABLE IF NOT EXISTS packed_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hu_id UUID REFERENCES handling_units(id) ON DELETE CASCADE,
  order_item_id UUID REFERENCES order_items(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  packed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  packed_by UUID REFERENCES users(id)
);

-- 6. Packing Exceptions
CREATE TABLE IF NOT EXISTS packing_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES delivery_orders(id),
  order_item_id UUID REFERENCES order_items(id),
  product_id UUID REFERENCES products(id),
  exception_type VARCHAR(50) NOT NULL, 
  -- Types: missing, damaged, wrong_quantity, wrong_product, other
  description TEXT NOT NULL,
  quantity_affected INTEGER,
  resolved BOOLEAN DEFAULT FALSE,
  resolution_notes TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES users(id)
);

-- 7. Packing Activity Log (Audit trail)
CREATE TABLE IF NOT EXISTS packing_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES delivery_orders(id),
  user_id UUID REFERENCES users(id),
  activity_type VARCHAR(50) NOT NULL,
  -- Types: order_assigned, order_started, item_scanned, item_packed, 
  --        container_created, container_sealed, order_completed, exception_raised
  description TEXT,
  metadata JSONB, -- Store additional data as JSON
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_code ON products(product_code);
CREATE INDEX idx_delivery_orders_status ON delivery_orders(status);
CREATE INDEX idx_delivery_orders_number ON delivery_orders(order_number);
CREATE INDEX idx_delivery_orders_assigned ON delivery_orders(assigned_to);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_status ON order_items(status);
CREATE INDEX idx_handling_units_order ON handling_units(order_id);
CREATE INDEX idx_packed_items_hu ON packed_items(hu_id);
CREATE INDEX idx_packing_exceptions_order ON packing_exceptions(order_id);
CREATE INDEX idx_packing_exceptions_resolved ON packing_exceptions(resolved);
CREATE INDEX idx_activity_log_order ON packing_activity_log(order_id);
CREATE INDEX idx_activity_log_user ON packing_activity_log(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE handling_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE packed_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE packing_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE packing_activity_log ENABLE ROW LEVEL SECURITY;

-- Products: All authenticated users can read
CREATE POLICY "Products are viewable by authenticated users"
  ON products FOR SELECT
  TO authenticated
  USING (true);

-- Delivery Orders: Users can view assigned orders or all if admin/manager
CREATE POLICY "Users can view their assigned orders"
  ON delivery_orders FOR SELECT
  TO authenticated
  USING (
    assigned_to = auth.uid() 
    OR EXISTS (
      SELECT 1 FROM employees 
      WHERE id = auth.uid() 
      AND role IN ('admin', 'manager', 'lead')
    )
  );

-- Users can update their assigned orders
CREATE POLICY "Users can update their assigned orders"
  ON delivery_orders FOR UPDATE
  TO authenticated
  USING (assigned_to = auth.uid())
  WITH CHECK (assigned_to = auth.uid());

-- Order Items: Accessible if order is accessible
CREATE POLICY "Order items viewable with order"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM delivery_orders 
      WHERE id = order_items.order_id 
      AND (
        assigned_to = auth.uid() 
        OR EXISTS (
          SELECT 1 FROM employees 
          WHERE id = auth.uid() 
          AND role IN ('admin', 'manager', 'lead')
        )
      )
    )
  );

-- Users can update order items for their assigned orders
CREATE POLICY "Users can update order items for assigned orders"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM delivery_orders 
      WHERE id = order_items.order_id 
      AND assigned_to = auth.uid()
    )
  );

-- Handling Units: Viewable by order access
CREATE POLICY "Handling units viewable with order"
  ON handling_units FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM delivery_orders 
      WHERE id = handling_units.order_id 
      AND (
        assigned_to = auth.uid() 
        OR EXISTS (
          SELECT 1 FROM employees 
          WHERE id = auth.uid() 
          AND role IN ('admin', 'manager', 'lead')
        )
      )
    )
  );

-- Packed Items: Full access for authenticated users
CREATE POLICY "Packed items accessible to authenticated users"
  ON packed_items FOR ALL
  TO authenticated
  USING (true);

-- Packing Exceptions: Viewable by all, creatable by authenticated
CREATE POLICY "Exceptions viewable by authenticated users"
  ON packing_exceptions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create exceptions"
  ON packing_exceptions FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

-- Activity Log: Insert only for authenticated
CREATE POLICY "Activity log insertable by authenticated users"
  ON packing_activity_log FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Activity log viewable by authenticated users"
  ON packing_activity_log FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_delivery_orders_updated_at BEFORE UPDATE ON delivery_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_order_items_updated_at BEFORE UPDATE ON order_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE SEED DATA FOR TESTING
-- ============================================

-- Insert sample products
INSERT INTO products (product_code, name, description, barcode, size, weight_kg) VALUES
('M300-LPT1', 'Boxershorts 3-er Pack 3-Farb.', 'Colorful boxer shorts 3-pack', '1234567890001', 'M', 0.250),
('M300-LPT2', 'T-Shirt V-Auschnitt 2-er Pack', 'V-neck T-shirt 2-pack', '1234567890002', 'M', 0.300),
('M300-LPT4', 'T-Shirt V-Auschnitt 2-er Pack', 'V-neck T-shirt 2-pack', '1234567890004', 'L', 0.320),
('M300-LPT15', 'Boxershorts 3-er Pack Schwarz', 'Black boxer shorts 3-pack', '1234567890015', 'XL', 0.280),
('SOCK-001', 'Cotton Socks 6-pack', 'Comfortable cotton socks', '1234567890100', 'One Size', 0.150);

-- Sample delivery order will be created via app or manually

```

---

## 🏗️ App Architecture

### Folder Structure

```
lib/
├── features/
│   ├── attendance/          # ✅ Existing attendance feature
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── presentation/
│   │   └── services/
│   │
│   ├── packaging/           # 📦 NEW - Packaging feature
│   │   ├── controllers/
│   │   │   ├── packaging_controller.dart
│   │   │   ├── scanner_controller.dart
│   │   │   └── order_controller.dart
│   │   │
│   │   ├── models/
│   │   │   ├── product.dart
│   │   │   ├── delivery_order.dart
│   │   │   ├── order_item.dart
│   │   │   ├── handling_unit.dart
│   │   │   ├── packed_item.dart
│   │   │   └── packing_exception.dart
│   │   │
│   │   ├── services/
│   │   │   ├── packaging_service.dart
│   │   │   ├── scanner_service.dart
│   │   │   └── label_service.dart
│   │   │
│   │   └── presentation/
│   │       ├── orders_list_page.dart
│   │       ├── packing_station_page.dart
│   │       ├── scanner_page.dart
│   │       ├── container_management_page.dart
│   │       ├── packing_history_page.dart
│   │       ├── exceptions_page.dart
│   │       └── widgets/
│   │           ├── order_card.dart
│   │           ├── product_info_card.dart
│   │           ├── packing_progress_bar.dart
│   │           ├── item_checklist.dart
│   │           └── scan_overlay.dart
│   │
│   ├── auth/               # ✅ Existing
│   ├── home/               # ✅ Existing (update to add packaging card)
│   └── profile/            # ✅ Existing
│
├── core/
├── data/
└── shared/
```

---

## 🔨 Implementation Steps

### Phase 1: Database Setup (Day 1)

**Step 1.1: Run SQL Schema**
```bash
1. Open Supabase dashboard
2. Go to SQL Editor
3. Copy the entire schema from above
4. Run it
5. Verify all tables are created
```

**Step 1.2: Add Sample Data**
```bash
1. Use the sample INSERT statements
2. Or manually add products via Supabase Table Editor
3. Create 1-2 test delivery orders
```

---

### Phase 2: Create Data Models (Day 2)

**File: `lib/features/packaging/models/product.dart`**

```dart
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
```

**File: `lib/features/packaging/models/delivery_order.dart`**

```dart
import 'package:equatable/equatable.dart';

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
```

**File: `lib/features/packaging/models/order_item.dart`**

```dart
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
```

**File: `lib/features/packaging/models/handling_unit.dart`**

```dart
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
}

class HandlingUnit extends Equatable {
  final String id;
  final String huNumber;
  final String? orderId;
  final String? containerType;
  final double? weightKg;
  final String? dimensionsCm;
  final HUStatus status;
  final String? trackingNumber;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? sealedAt;
  final String? sealedBy;

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
  });

  factory HandlingUnit.fromJson(Map<String, dynamic> json) {
    return HandlingUnit(
      id: json['id'] as String,
      huNumber: json['hu_number'] as String,
      orderId: json['order_id'] as String?,
      containerType: json['container_type'] as String?,
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

  @override
  List<Object?> get props => [id, huNumber, status];
}
```

**File: `lib/features/packaging/models/packing_exception.dart`**

```dart
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
```

---

### Phase 3: Create Services (Day 3-4)

**File: `lib/features/packaging/services/packaging_service.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/delivery_order.dart';
import '../models/order_item.dart';
import '../models/handling_unit.dart';
import '../models/product.dart';
import '../models/packing_exception.dart';

class PackagingService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ==================== ORDERS ====================
  
  /// Fetch all delivery orders with optional status filter
  Future<List<DeliveryOrder>> fetchOrders({OrderStatus? status}) async {
    try {
      var query = _supabase
          .from('delivery_orders')
          .select()
          .order('created_at', ascending: false);

      if (status != null) {
        final statusStr = status.name.replaceAll('inProgress', 'in_progress');
        query = query.eq('status', statusStr);
      }

      final response = await query;
      return (response as List)
          .map((json) => DeliveryOrder.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Fetch single order by ID with items
  Future<DeliveryOrder> fetchOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_orders')
          .select()
          .eq('id', orderId)
          .single();

      return DeliveryOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Assign order to current user
  Future<void> assignOrder(String orderId, String userId) async {
    try {
      await _supabase.from('delivery_orders').update({
        'assigned_to': userId,
        'assigned_at': DateTime.now().toIso8601String(),
        'status': 'assigned',
      }).eq('id', orderId);

      // Log activity
      await _logActivity(
        orderId: orderId,
        userId: userId,
        activityType: 'order_assigned',
        description: 'Order assigned to user',
      );
    } catch (e) {
      throw Exception('Failed to assign order: $e');
    }
  }

  /// Start packing an order
  Future<void> startPacking(String orderId, String userId) async {
    try {
      await _supabase.from('delivery_orders').update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _logActivity(
        orderId: orderId,
        userId: userId,
        activityType: 'order_started',
        description: 'Started packing order',
      );
    } catch (e) {
      throw Exception('Failed to start packing: $e');
    }
  }

  /// Complete an order
  Future<void> completeOrder(String orderId, String userId) async {
    try {
      await _supabase.from('delivery_orders').update({
        'status': 'packed',
        'packed_at': DateTime.now().toIso8601String(),
        'packed_by': userId,
      }).eq('id', orderId);

      await _logActivity(
        orderId: orderId,
        userId: userId,
        activityType: 'order_completed',
        description: 'Order packing completed',
      );
    } catch (e) {
      throw Exception('Failed to complete order: $e');
    }
  }

  // ==================== ORDER ITEMS ====================

  /// Fetch items for an order
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    try {
      final response = await _supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId)
          .order('position_number');

      return (response as List)
          .map((json) => OrderItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch order items: $e');
    }
  }

  /// Update packed quantity for an item
  Future<void> updateItemPackedQuantity(
    String itemId,
    int packedQuantity,
  ) async {
    try {
      // Determine status
      final item = await _supabase
          .from('order_items')
          .select()
          .eq('id', itemId)
          .single();

      final orderedQty = item['quantity_ordered'] as int;
      String status;
      if (packedQuantity == 0) {
        status = 'pending';
      } else if (packedQuantity < orderedQty) {
        status = 'partial';
      } else {
        status = 'packed';
      }

      await _supabase.from('order_items').update({
        'quantity_packed': packedQuantity,
        'status': status,
      }).eq('id', itemId);

      // Update order totals
      await _updateOrderProgress(item['order_id'] as String);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Update order progress (packed_items count)
  Future<void> _updateOrderProgress(String orderId) async {
    try {
      final items = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      int totalItems = 0;
      int packedItems = 0;

      for (final item in items as List) {
        totalItems += item['quantity_ordered'] as int;
        packedItems += item['quantity_packed'] as int;
      }

      await _supabase.from('delivery_orders').update({
        'total_items': totalItems,
        'packed_items': packedItems,
      }).eq('id', orderId);
    } catch (e) {
      print('Warning: Failed to update order progress: $e');
    }
  }

  // ==================== PRODUCTS ====================

  /// Search product by barcode
  Future<Product?> findProductByBarcode(String barcode) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to find product: $e');
    }
  }

  /// Search product by code
  Future<Product?> findProductByCode(String code) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('product_code', code)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to find product: $e');
    }
  }

  // ==================== HANDLING UNITS ====================

  /// Create new handling unit
  Future<HandlingUnit> createHandlingUnit({
    required String huNumber,
    required String orderId,
    String? containerType,
    required String userId,
  }) async {
    try {
      final response = await _supabase.from('handling_units').insert({
        'hu_number': huNumber,
        'order_id': orderId,
        'container_type': containerType,
        'status': 'open',
        'created_by': userId,
      }).select().single();

      return HandlingUnit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create handling unit: $e');
    }
  }

  /// Fetch handling units for order
  Future<List<HandlingUnit>> fetchHandlingUnits(String orderId) async {
    try {
      final response = await _supabase
          .from('handling_units')
          .select()
          .eq('order_id', orderId)
          .order('created_at');

      return (response as List)
          .map((json) => HandlingUnit.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch handling units: $e');
    }
  }

  // ==================== EXCEPTIONS ====================

  /// Create packing exception
  Future<void> createException({
    required String orderId,
    String? orderItemId,
    String? productId,
    required ExceptionType type,
    required String description,
    int? quantityAffected,
    required String userId,
  }) async {
    try {
      await _supabase.from('packing_exceptions').insert({
        'order_id': orderId,
        'order_item_id': orderItemId,
        'product_id': productId,
        'exception_type': type.name.replaceAll('wrong', 'wrong_'),
        'description': description,
        'quantity_affected': quantityAffected,
        'created_by': userId,
      });

      await _logActivity(
        orderId: orderId,
        userId: userId,
        activityType: 'exception_raised',
        description: 'Exception: ${type.displayName}',
      );
    } catch (e) {
      throw Exception('Failed to create exception: $e');
    }
  }

  /// Fetch exceptions for order
  Future<List<PackingException>> fetchExceptions(String orderId) async {
    try {
      final response = await _supabase
          .from('packing_exceptions')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PackingException.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exceptions: $e');
    }
  }

  // ==================== ACTIVITY LOG ====================

  Future<void> _logActivity({
    required String orderId,
    required String userId,
    required String activityType,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('packing_activity_log').insert({
        'order_id': orderId,
        'user_id': userId,
        'activity_type': activityType,
        'description': description,
        'metadata': metadata,
      });
    } catch (e) {
      print('Warning: Failed to log activity: $e');
    }
  }
}
```

**File: `lib/features/packaging/services/scanner_service.dart`**

```dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class ScannerService {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );

  final AudioPlayer _audioPlayer = AudioPlayer();

  MobileScannerController get controller => _controller;

  /// Provide haptic feedback on successful scan
  Future<void> provideFeedback() async {
    try {
      // Vibrate
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }

      // Play beep sound
      // Note: You'll need to add a beep.mp3 to assets/sounds/
      // await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      print('Failed to provide feedback: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
  }
}
```

---

### Phase 4: Build UI Screens (Day 5-10)

**File: `lib/features/packaging/presentation/orders_list_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/brand_colors.dart';
import '../services/packaging_service.dart';
import '../models/delivery_order.dart';
import 'packing_station_page.dart';

// Provider for orders
final ordersProvider = FutureProvider<List<DeliveryOrder>>((ref) async {
  final service = PackagingService();
  return await service.fetchOrders();
});

class OrdersListPage extends ConsumerWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Orders'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final DeliveryOrder order;

  Color _getStatusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.assigned:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.packed:
        return Colors.green;
      case OrderStatus.shipped:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PackingStationPage(orderId: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.customerName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (order.specialInstructions != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.specialInstructions!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: order.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${order.packedItems}/${order.totalItems}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**File: `lib/features/packaging/presentation/packing_station_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/brand_colors.dart';
import '../services/packaging_service.dart';
import '../models/delivery_order.dart';
import '../models/order_item.dart';
import '../../auth/controllers/auth_controller.dart';
import 'scanner_page.dart';

// Providers
final currentOrderProvider = FutureProvider.family<DeliveryOrder, String>(
  (ref, orderId) async {
    final service = PackagingService();
    return await service.fetchOrderById(orderId);
  },
);

final orderItemsProvider = FutureProvider.family<List<OrderItem>, String>(
  (ref, orderId) async {
    final service = PackagingService();
    return await service.fetchOrderItems(orderId);
  },
);

class PackingStationPage extends ConsumerStatefulWidget {
  const PackingStationPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PackingStationPage> createState() => _PackingStationPageState();
}

class _PackingStationPageState extends ConsumerState<PackingStationPage> {
  final PackagingService _service = PackagingService();

  @override
  void initState() {
    super.initState();
    _startPackingIfNeeded();
  }

  Future<void> _startPackingIfNeeded() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final order = await ref.read(currentOrderProvider(widget.orderId).future);
    
    if (order.status == OrderStatus.pending || order.status == OrderStatus.assigned) {
      await _service.startPacking(widget.orderId, user.id);
      ref.invalidate(currentOrderProvider(widget.orderId));
    }
  }

  Future<void> _completeOrder() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Order?'),
        content: const Text('Mark this order as completely packed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.completeOrder(widget.orderId, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order completed!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(currentOrderProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing Station'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentOrderProvider(widget.orderId));
              ref.invalidate(orderItemsProvider(widget.orderId));
            },
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (order) => itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (items) => _buildContent(context, order, items),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DeliveryOrder order,
    List<OrderItem> items,
  ) {
    return Column(
      children: [
        // Order header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: BrandColors.primary.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                order.customerName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: order.progressPercentage / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  BrandColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.packedItems}/${order.totalItems} items packed',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Special instructions
        if (order.specialInstructions != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.specialInstructions!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ItemCard(
                item: item,
                onPackItem: () async {
                  final newQty = item.quantityPacked + 1;
                  if (newQty <= item.quantityOrdered) {
                    await _service.updateItemPackedQuantity(
                      item.id,
                      newQty,
                    );
                    ref.invalidate(currentOrderProvider(widget.orderId));
                    ref.invalidate(orderItemsProvider(widget.orderId));
                  }
                },
                onScan: () async {
                  final scannedCode = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScannerPage(),
                    ),
                  );

                  if (scannedCode != null && mounted) {
                    // Verify product matches
                    final product = await _service.findProductByBarcode(scannedCode);
                    if (product != null && product.id == item.productId) {
                      // Product matches, increment quantity
                      final newQty = item.quantityPacked + 1;
                      if (newQty <= item.quantityOrdered) {
                        await _service.updateItemPackedQuantity(
                          item.id,
                          newQty,
                        );
                        ref.invalidate(currentOrderProvider(widget.orderId));
                        ref.invalidate(orderItemsProvider(widget.orderId));
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item scanned successfully!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wrong product scanned!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Open scanner for any product
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScannerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Product'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: order.isComplete ? _completeOrder : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onPackItem,
    required this.onScan,
  });

  final OrderItem item;
  final VoidCallback onPackItem;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final isComplete = item.isComplete;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isComplete,
              onChanged: null,
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.displayName ?? 'Unknown Product',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product?.productCode ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.quantityPacked}/${item.quantityOrdered}',
                        style: TextStyle(
                          color: isComplete ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: item.progressPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton.outlined(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan',
                ),
                const SizedBox(height: 4),
                IconButton.filled(
                  onPressed: isComplete ? null : onPackItem,
                  icon: const Icon(Icons.add),
                  tooltip: 'Pack',
                  style: IconButton.styleFrom(
                    backgroundColor: BrandColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**File: `lib/features/packaging/presentation/scanner_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/brand_colors.dart';
import '../services/scanner_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ScannerService _scannerService = ScannerService();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      setState(() => _hasScanned = true);
      _scannerService.provideFeedback();
      
      // Return the scanned code
      Navigator.pop(context, barcode!.rawValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerService.controller,
            onDetect: _onDetect,
          ),
          
          // Scan area overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Position barcode within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 5: Update Home Page (Day 11)

**Update: `lib/features/home/presentation/home_page.dart`**

Add this to the feature cards grid:

```dart
// Add packaging card
FeatureCard(
  icon: Icons.inventory_2_outlined,
  title: 'Packaging',
  subtitle: 'Pack orders',
  color: Colors.deepOrange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrdersListPage(),
      ),
    );
  },
),
```

---

### Phase 6: Update pubspec.yaml (Day 11)

Add these dependencies:

```yaml
dependencies:
  # Existing...
  
  # NEW for packaging feature
  vibration: ^1.8.4
  audioplayers: ^5.2.1
  barcode_widget: ^2.0.4
  pdf: ^3.10.8
  printing: ^5.12.0
```

Then run:
```bash
flutter pub get
```

---

## 📱 Testing Guide

### Manual Testing Checklist

- [ ] **Orders List**
  - [ ] Orders load correctly
  - [ ] Can filter by status
  - [ ] Can tap order to open packing station
  
- [ ] **Packing Station**
  - [ ] Order details display correctly
  - [ ] Special instructions show up
  - [ ] Items list loads
  - [ ] Progress bar updates
  
- [ ] **Product Scanning**
  - [ ] Camera opens
  - [ ] Barcode detected
  - [ ] Vibration/feedback works
  - [ ] Wrong product rejected
  
- [ ] **Pack Items**
  - [ ] Can manually pack items
  - [ ] Quantity updates
  - [ ] Progress reflects changes
  - [ ] Complete button enables when done
  
- [ ] **Complete Order**
  - [ ] Confirmation dialog shows
  - [ ] Order marked as complete
  - [ ] Returns to orders list

---

## 🚀 Deployment Checklist

- [ ] Run database migrations in production Supabase
- [ ] Add seed data (products)
- [ ] Test on physical devices
- [ ] Configure RLS policies
- [ ] Add error logging
- [ ] Train warehouse staff
- [ ] Create user manual
- [ ] Monitor for issues

---

## 📖 User Guide

### For Warehouse Staff

**How to Pack an Order:**

1. **Open App** → Tap "Packaging" card
2. **Select Order** → Tap order from list
3. **Start Packing** → Order automatically starts
4. **For each item:**
   - Tap "Scan" button
   - Scan product barcode
   - Or tap "+" to manually pack
5. **Review Progress** → Check all items packed
6. **Complete** → Tap "Complete" button
7. **Confirmation** → Confirm order completion

**Tips:**
- Read special instructions carefully
- Double-check quantities
- Report exceptions immediately
- Ask supervisor if unsure

---

## 🔄 Future Enhancements

### Phase 2 Features (Backlog)

- [ ] Multi-container support
- [ ] Weight verification
- [ ] Label printing
- [ ] Batch scanning
- [ ] Voice commands
- [ ] Offline mode
- [ ] Analytics dashboard
- [ ] Integration with ERP systems
- [ ] Photo capture for exceptions
- [ ] Supervisor dashboard

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue: Camera won't open**
- Check camera permissions
- Restart app
- Try different device

**Issue: Barcode not scanning**
- Ensure good lighting
- Clean barcode
- Try manual entry

**Issue: Can't complete order**
- Verify all items packed
- Check for exceptions
- Contact supervisor

---

## 📝 Notes

- Keep this document updated as features change
- Document all customizations
- Track bugs and feature requests
- Review security regularly

---

**Document Version:** 1.0  
**Last Updated:** December 2, 2025  
**Maintained By:** Development Team



