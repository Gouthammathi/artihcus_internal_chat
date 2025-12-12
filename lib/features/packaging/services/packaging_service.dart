import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/delivery_order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import '../models/packing_exception.dart';
import '../models/handling_unit.dart';

class PackagingService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ==================== ORDERS ====================
  
  /// Create a new delivery order with items
  Future<DeliveryOrder> createOrder({
    required String orderNumber,
    required String customerName,
    String? customerId,
    String? deliveryAddress,
    String? specialInstructions,
    int priority = 0,
    required List<Map<String, dynamic>> items, // [{productId, quantity, positionNumber}]
    required String userId,
  }) async {
    try {
      // Create the order
      final orderResponse = await _supabase
          .from('delivery_orders')
          .insert({
            'order_number': orderNumber,
            'customer_name': customerName,
            'customer_id': customerId,
            'delivery_address': deliveryAddress,
            'special_instructions': specialInstructions,
            'priority': priority,
            'status': 'pending',
            'total_items': items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int)),
            'packed_items': 0,
          })
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // Create order items
      for (final item in items) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item['productId'] as String,
          'quantity_ordered': item['quantity'] as int,
          'quantity_packed': 0,
          'position_number': item['positionNumber'] as int?,
          'status': 'pending',
        });
      }

      // Log activity
      await _logActivity(
        orderId: orderId,
        userId: userId,
        activityType: 'order_created',
        description: 'Order created by admin',
      );

      return DeliveryOrder.fromJson(orderResponse);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Fetch all delivery orders with optional status filter
  Future<List<DeliveryOrder>> fetchOrders({OrderStatus? status}) async {
    try {
      final query = _supabase
          .from('delivery_orders')
          .select();

      final response = await (status != null 
          ? query
              .eq('status', status.name == 'inProgress' ? 'in_progress' : status.name)
              .order('created_at', ascending: false)
          : query.order('created_at', ascending: false));
      return (response as List)
          .map((json) => DeliveryOrder.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Fetch single order by ID
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
      // Get item details first
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

      // Update item
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

  /// Search products by name or code
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) {
        // Return all active products if query is empty
        final response = await _supabase
            .from('products')
            .select()
            .eq('active', true)
            .order('name')
            .limit(50);

        return (response as List)
            .map((json) => Product.fromJson(json))
            .toList();
      }

      // Search by name or product code
      final response = await _supabase
          .from('products')
          .select()
          .eq('active', true)
          .or('name.ilike.%$query%,product_code.ilike.%$query%')
          .order('name')
          .limit(50);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Fetch all active products
  Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('active', true)
          .order('name');

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
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
        'exception_type': type.dbValue,
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

  // ==================== HANDLING UNITS (CONTAINERS) ====================

  /// Create new handling unit/container
  Future<HandlingUnit> createHandlingUnit({
    required String orderId,
    required ContainerType containerType,
    required String userId,
  }) async {
    try {
      // Generate HU number (simple timestamp-based for now)
      final huNumber = 'HU${DateTime.now().millisecondsSinceEpoch}';

      final response = await _supabase.from('handling_units').insert({
        'hu_number': huNumber,
        'order_id': orderId,
        'container_type': containerType.dbValue,
        'status': 'open',
        'created_by': userId,
      }).select().single();

      await _logActivity(
        orderId: orderId,
        userId: userId,
        activityType: 'container_created',
        description: 'Created container $huNumber',
      );

      return HandlingUnit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create handling unit: $e');
    }
  }

  /// Fetch handling units for an order with item counts
  Future<List<HandlingUnit>> fetchHandlingUnits(String orderId) async {
    try {
      final response = await _supabase
          .from('handling_units')
          .select('*, packed_items(count)')
          .eq('order_id', orderId)
          .order('created_at');

      return (response as List).map((json) {
        // Count items in this HU
        final itemCount = json['packed_items'] != null && json['packed_items'] is List
            ? (json['packed_items'] as List).length
            : 0;
        
        return HandlingUnit.fromJson({
          ...json,
          'item_count': itemCount,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch handling units: $e');
    }
  }

  /// Seal a container
  Future<void> sealHandlingUnit(String huId, String userId) async {
    try {
      await _supabase.from('handling_units').update({
        'status': 'sealed',
        'sealed_at': DateTime.now().toIso8601String(),
        'sealed_by': userId,
      }).eq('id', huId);
    } catch (e) {
      throw Exception('Failed to seal handling unit: $e');
    }
  }

  /// Add item to container
  Future<void> addItemToContainer({
    required String huId,
    required String orderItemId,
    required String productId,
    required int quantity,
    required String userId,
  }) async {
    try {
      await _supabase.from('packed_items').insert({
        'hu_id': huId,
        'order_item_id': orderItemId,
        'product_id': productId,
        'quantity': quantity,
        'packed_by': userId,
      });
    } catch (e) {
      throw Exception('Failed to add item to container: $e');
    }
  }

  /// Get items in a container
  Future<List<PackedItem>> fetchContainerItems(String huId) async {
    try {
      final response = await _supabase
          .from('packed_items')
          .select()
          .eq('hu_id', huId)
          .order('packed_at');

      return (response as List)
          .map((json) => PackedItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch container items: $e');
    }
  }

  /// Update item packed quantity WITH container tracking
  Future<void> updateItemPackedQuantityWithContainer({
    required String itemId,
    required int packedQuantity,
    String? huId,
    required String userId,
  }) async {
    try {
      // Get item details first
      final item = await _supabase
          .from('order_items')
          .select()
          .eq('id', itemId)
          .single();

      final orderedQty = item['quantity_ordered'] as int;
      final currentPacked = item['quantity_packed'] as int? ?? 0;
      final increment = packedQuantity - currentPacked;

      String status;
      if (packedQuantity == 0) {
        status = 'pending';
      } else if (packedQuantity < orderedQty) {
        status = 'partial';
      } else {
        status = 'packed';
      }

      // Update item
      await _supabase.from('order_items').update({
        'quantity_packed': packedQuantity,
        'status': status,
      }).eq('id', itemId);

      // If HU is specified and increment > 0, add to packed_items
      if (huId != null && increment > 0) {
        await addItemToContainer(
          huId: huId,
          orderItemId: itemId,
          productId: item['product_id'] as String,
          quantity: increment,
          userId: userId,
        );
      }

      // Update order totals
      await _updateOrderProgress(item['order_id'] as String);
    } catch (e) {
      throw Exception('Failed to update item: $e');
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

