import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/brand_colors.dart';
import '../models/handling_unit.dart';
import '../models/delivery_order.dart';
import '../services/packaging_service.dart';
import '../../auth/controllers/auth_controller.dart';

// Provider for handling units
final handlingUnitsProvider = FutureProvider.family<List<HandlingUnit>, String>(
  (ref, orderId) async {
    final service = PackagingService();
    return await service.fetchHandlingUnits(orderId);
  },
);

class ContainerManagementPage extends ConsumerStatefulWidget {
  const ContainerManagementPage({
    super.key,
    required this.orderId,
    required this.order,
  });

  final String orderId;
  final DeliveryOrder order;

  @override
  ConsumerState<ContainerManagementPage> createState() =>
      _ContainerManagementPageState();
}

class _ContainerManagementPageState
    extends ConsumerState<ContainerManagementPage> {
  final PackagingService _service = PackagingService();

  Future<void> _createContainer(ContainerType type) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    try {
      await _service.createHandlingUnit(
        orderId: widget.orderId,
        containerType: type,
        userId: user.id,
      );

      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Refresh list
      ref.invalidate(handlingUnitsProvider(widget.orderId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${type.displayName} created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sealContainer(String huId, String huNumber) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seal Container?'),
        content: Text('Seal container $huNumber?\n\nYou cannot add more items after sealing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Seal'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.sealHandlingUnit(huId, user.id);
        
        HapticFeedback.mediumImpact();
        
        ref.invalidate(handlingUnitsProvider(widget.orderId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔒 Container sealed!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCreateContainerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Container'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select container type:'),
            const SizedBox(height: 16),
            ...ContainerType.values.map((type) => ListTile(
                  leading: Icon(_getContainerIcon(type)),
                  title: Text(type.displayName),
                  onTap: () {
                    Navigator.pop(context);
                    _createContainer(type);
                  },
                )),
          ],
        ),
      ),
    );
  }

  IconData _getContainerIcon(ContainerType type) {
    switch (type) {
      case ContainerType.smallBox:
        return Icons.inbox;
      case ContainerType.mediumBox:
        return Icons.inventory_2;
      case ContainerType.largeBox:
        return Icons.inventory;
      case ContainerType.pallet:
        return Icons.view_module;
      case ContainerType.custom:
        return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final containersAsync = ref.watch(handlingUnitsProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Container Management'),
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(handlingUnitsProvider(widget.orderId)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Order info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: BrandColors.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.order.orderNumber}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  widget.order.customerName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Containers list
          Expanded(
            child: containersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (containers) {
                if (containers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No containers yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('Create your first container to start packing'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: containers.length,
                  itemBuilder: (context, index) {
                    final container = containers[index];
                    return _ContainerCard(
                      container: container,
                      onSeal: () => _sealContainer(
                        container.id,
                        container.huNumber,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateContainerDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Container'),
        backgroundColor: BrandColors.secondary,
      ),
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({
    required this.container,
    required this.onSeal,
  });

  final HandlingUnit container;
  final VoidCallback onSeal;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(),
                  size: 32,
                  color: statusColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        container.huNumber,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        container.containerType?.displayName ?? 'Custom',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    container.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.inventory_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${container.itemCount} items',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (container.weightKg != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.scale, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${container.weightKg} kg',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
            if (container.isOpen) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSeal,
                  icon: const Icon(Icons.lock),
                  label: const Text('Seal Container'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (container.status) {
      case HUStatus.open:
        return Colors.green;
      case HUStatus.sealed:
        return Colors.orange;
      case HUStatus.shipped:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    if (container.isSealed) return Icons.lock;
    return Icons.inventory_2;
  }
}

