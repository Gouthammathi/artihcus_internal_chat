import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/brand_colors.dart';
import '../models/delivery_order.dart';
import '../models/order_item.dart';
import '../models/handling_unit.dart';
import '../services/packaging_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'scanner_page.dart';
import 'container_management_page.dart';

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

final orderContainersProvider = FutureProvider.family<List<HandlingUnit>, String>(
  (ref, orderId) async {
    final service = PackagingService();
    return await service.fetchHandlingUnits(orderId);
  },
);

class PackingStationPage extends ConsumerStatefulWidget {
  const PackingStationPage({
    super.key,
    required this.orderId,
  });

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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
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
    final containersAsync = ref.watch(orderContainersProvider(widget.orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Packing Station',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Scan, pack, and seal containers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentOrderProvider(widget.orderId));
              ref.invalidate(orderItemsProvider(widget.orderId));
              ref.invalidate(orderContainersProvider(widget.orderId));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (order) => itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (items) => containersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (containers) => _buildContent(context, order, items, containers),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DeliveryOrder order,
    List<OrderItem> items,
    List<HandlingUnit> containers,
  ) {
    final progress = order.progressPercentage / 100;
    final isComplete = order.isComplete;
    final openContainers = containers.where((c) => c.isOpen).length;
    final sealedContainers = containers.where((c) => c.isSealed).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _HeaderCard(
            order: order,
            progress: progress,
            isComplete: isComplete,
          ),
        ),
        if (containers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InfoRowCard(
              icon: Icons.inventory_2,
              color: BrandColors.primary,
              text: '$openContainers open, $sealedContainers sealed containers',
              actionLabel: 'Manage',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContainerManagementPage(
                      orderId: widget.orderId,
                      order: order,
                    ),
                  ),
                ).then((_) {
                  ref.invalidate(orderContainersProvider(widget.orderId));
                });
              },
            ),
          ),
        if (order.specialInstructions != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _InfoRowCard(
              icon: Icons.info_outline,
              color: Colors.amber.shade700,
              text: order.specialInstructions!,
              actionLabel: null,
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ItemCard(
                item: item,
                onPackItem: () async {
                  final newQty = item.quantityPacked + 1;
                  if (newQty <= item.quantityOrdered) {
                    HapticFeedback.lightImpact();

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
                    final product = await _service.findProductByBarcode(scannedCode);
                    if (product != null && product.id == item.productId) {
                      final newQty = item.quantityPacked + 1;
                      if (newQty <= item.quantityOrdered) {
                        HapticFeedback.mediumImpact();

                        await _service.updateItemPackedQuantity(
                          item.id,
                          newQty,
                        );
                        ref.invalidate(currentOrderProvider(widget.orderId));
                        ref.invalidate(orderItemsProvider(widget.orderId));

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Item scanned successfully!'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Wrong product scanned!'),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContainerManagementPage(
                              orderId: widget.orderId,
                              order: order,
                            ),
                          ),
                        ).then((_) {
                          ref.invalidate(orderContainersProvider(widget.orderId));
                        });
                      },
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Containers'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScannerPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isComplete ? _completeOrder : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete Order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
    final progress = item.progressPercentage / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete ? Colors.green : BrandColors.primary.withOpacity(0.12),
            ),
            child: Icon(
              isComplete ? Icons.check : Icons.inventory_2,
              color: isComplete ? Colors.white : BrandColors.primary,
            ),
          ),
          const SizedBox(width: 14),
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
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PillLabel(
                      text: '${item.quantityPacked}/${item.quantityOrdered}',
                      color: isComplete ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton.outlined(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan',
                style: IconButton.styleFrom(
                  side: BorderSide(color: BrandColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              IconButton.filled(
                onPressed: isComplete ? null : onPackItem,
                icon: const Icon(Icons.add),
                tooltip: 'Pack',
                style: IconButton.styleFrom(
                  backgroundColor: BrandColors.secondary,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.order,
    required this.progress,
    required this.isComplete,
  });

  final DeliveryOrder order;
  final double progress;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrandColors.primary.withOpacity(0.12),
            BrandColors.primary.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
              ),
              const Spacer(),
              _PillLabel(
                text: order.status.displayName,
                color: order.status.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.6),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : BrandColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${order.packedItems}/${order.totalItems} items packed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowCard extends StatelessWidget {
  const _InfoRowCard({
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (actionLabel != null && onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text, this.color = Colors.black87});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}



