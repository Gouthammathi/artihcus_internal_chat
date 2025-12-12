import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/brand_colors.dart';
import '../models/product.dart';
import '../services/packaging_service.dart';
import '../../auth/controllers/auth_controller.dart';

// Provider for product search
final productSearchProvider = FutureProvider.family<List<Product>, String>(
  (ref, query) async {
    final service = PackagingService();
    return await service.searchProducts(query);
  },
);

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerIdController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  
  final List<_OrderItemInput> _items = [];
  final PackagingService _service = PackagingService();
  bool _isSaving = false;

  @override
  void dispose() {
    _orderNumberController.dispose();
    _customerNameController.dispose();
    _customerIdController.dispose();
    _deliveryAddressController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  int get _totalItems => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  Future<void> _showProductSearch() async {
    final selectedProducts = await showDialog<List<Product>>(
      context: context,
      builder: (context) => _ProductSearchDialog(),
    );

    if (selectedProducts != null && selectedProducts.isNotEmpty) {
      setState(() {
        for (final product in selectedProducts) {
          // Check if product already added
          if (!_items.any((item) => item.productId == product.id)) {
            _items.add(_OrderItemInput(
              productId: product.id,
              product: product,
              quantity: 1,
            ));
          }
        }
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    setState(() {
      _items[index].quantity = newQuantity;
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create orders'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final itemsData = _items.asMap().entries.map((entry) {
        return {
          'productId': entry.value.productId,
          'quantity': entry.value.quantity,
          'positionNumber': entry.key + 1,
        };
      }).toList();

      await _service.createOrder(
        orderNumber: _orderNumberController.text.trim(),
        customerName: _customerNameController.text.trim(),
        customerId: _customerIdController.text.trim().isEmpty
            ? null
            : _customerIdController.text.trim(),
        deliveryAddress: _deliveryAddressController.text.trim().isEmpty
            ? null
            : _deliveryAddressController.text.trim(),
        specialInstructions: _specialInstructionsController.text.trim().isEmpty
            ? null
            : _specialInstructionsController.text.trim(),
        items: itemsData,
        userId: user.id,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Create Order',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'Capture order details and products',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GlassCard(
              title: 'Order Details',
              child: Column(
                children: [
                  _LabeledField(
                    controller: _orderNumberController,
                    label: 'Order Number *',
                    hint: 'e.g., ORD-1001',
                    icon: Icons.tag,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Order number is required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _customerNameController,
                    label: 'Customer Name *',
                    hint: 'e.g., John Doe',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Customer name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _customerIdController,
                    label: 'Customer ID (optional)',
                    hint: 'e.g., CUST-123',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _deliveryAddressController,
                    label: 'Delivery Address (optional)',
                    hint: '123 Main St, City, Country',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _specialInstructionsController,
                    label: 'Special Instructions (optional)',
                    hint: 'e.g., Pack carefully, gift wrap',
                    icon: Icons.info_outline,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _GlassCard(
              title: 'Products',
              trailing: _PillLabel(text: 'Total: $_totalItems items'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _showProductSearch,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Products'),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products added',
                      subtitle: 'Tap "Add Products" to get started',
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _ProductItemCard(
                        item: item,
                        onRemove: () => _removeItem(index),
                        onQuantityChanged: (newQty) => _updateQuantity(index, newQty),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: _isSaving ? null : _saveOrder,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OrderItemInput {
  final String productId;
  final Product product;
  int quantity;

  _OrderItemInput({
    required this.productId,
    required this.product,
    this.quantity = 1,
  });
}

class _ProductItemCard extends StatelessWidget {
  const _ProductItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final _OrderItemInput item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
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
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: BrandColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: BrandColors.primary),
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.productCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: item.quantity > 1
                    ? () => onQuantityChanged(item.quantity - 1)
                    : null,
                color: BrandColors.primary,
              ),
              Container(
                width: 42,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onQuantityChanged(item.quantity + 1),
                color: BrandColors.primary,
              ),
            ],
          ),

          // Remove Button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _ProductSearchDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends ConsumerState<_ProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedProductIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text;
    final productsAsync = ref.watch(productSearchProvider(searchQuery));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            _DialogSearchField(
              controller: _searchController,
              onChanged: () => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // Products List
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text('No products found'),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isSelected = _selectedProductIds.contains(product.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? BrandColors.primary.withOpacity(0.4)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedProductIds.add(product.id);
                              } else {
                                _selectedProductIds.remove(product.id);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(product.displayName),
                          subtitle: Text(
                            '${product.productCode}${product.size != null ? ' • Size ${product.size}' : ''}',
                          ),
                          secondary: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image),
                                  ),
                                )
                              : const Icon(Icons.inventory_2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedProductIds.length} selected',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: _selectedProductIds.isEmpty
                            ? null
                            : () {
                                final selectedProducts = productsAsync.value
                                    ?.where((p) => _selectedProductIds.contains(p.id))
                                    .toList();
                                Navigator.pop(context, selectedProducts);
                              },
                        child: const Text('Add Selected'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BrandColors.primary.withOpacity(0.6)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DialogSearchField extends StatelessWidget {
  const _DialogSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: 'Search by name or code...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

