import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/fabric.dart';
import '../services/fabric_seller_service.dart';

class FabricSellerInventory extends StatefulWidget {
  final String sellerId;

  const FabricSellerInventory({super.key, required this.sellerId});

  @override
  State<FabricSellerInventory> createState() => _FabricSellerInventoryState();
}

class _FabricSellerInventoryState extends State<FabricSellerInventory> {
  final FabricSellerService _fabricService = FabricSellerService();
  bool _isLoading = true;
  bool _isGridView = true;
  List<Fabric> _allFabrics = [];
  List<Fabric> _filteredFabrics = [];
  FabricType? _selectedType;
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    _loadFabrics();
  }

  Future<void> _loadFabrics() async {
    setState(() => _isLoading = true);
    try {
      final fabrics = await _fabricService.getSellerFabrics(widget.sellerId);
      setState(() {
        _allFabrics = fabrics;
        _filteredFabrics = fabrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading inventory: $e')));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredFabrics = _allFabrics;

      // Filter by type
      if (_selectedType != null) {
        _filteredFabrics = _filteredFabrics
            .where((fabric) => fabric.fabricType == _selectedType)
            .toList();
      }

      // Sort
      switch (_selectedSort) {
        case 'newest':
          _filteredFabrics.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'price-low':
          _filteredFabrics.sort(
            (a, b) => a.pricePerYard.compareTo(b.pricePerYard),
          );
          break;
        case 'price-high':
          _filteredFabrics.sort(
            (a, b) => b.pricePerYard.compareTo(a.pricePerYard),
          );
          break;
        case 'stock':
          _filteredFabrics.sort(
            (a, b) => b.quantityAvailable.compareTo(a.quantityAvailable),
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_3x3),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Filter
                      Text(
                        'Filter by Type',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All Types'),
                              selected: _selectedType == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedType = null;
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...FabricType.values.map((type) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(type.toString().split('.').last),
                                  selected: _selectedType == type,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedType = selected ? type : null;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sort Dropdown
                      DropdownButton<String>(
                        value: _selectedSort,
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value ?? 'newest';
                            _applyFilters();
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'price-low',
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: 'price-high',
                            child: Text('Price: High to Low'),
                          ),
                          DropdownMenuItem(
                            value: 'stock',
                            child: Text('Stock Level'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Fabrics List/Grid
                Expanded(
                  child: _filteredFabrics.isEmpty
                      ? _buildEmptyState()
                      : _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _filteredFabrics.length,
                          itemBuilder: (context, index) {
                            return _buildFabricCard(_filteredFabrics[index]);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFabrics.length,
                          itemBuilder: (context, index) {
                            return _buildFabricListTile(
                              _filteredFabrics[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No fabrics in inventory',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add new fabric listings to your catalog',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFabricCard(Fabric fabric) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fabric Image with Stock Status
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: fabric.imageUrls.isNotEmpty
                      ? Image.network(
                          fabric.imageUrls[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                        )
                      : const Center(child: Icon(Icons.image_not_supported)),
                ),
                // Stock Status Badge
                Positioned(top: 8, right: 8, child: _buildStockBadge(fabric)),
              ],
            ),
          ),
          // Fabric Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fabric.color,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fabric.getFabricTypeString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${fabric.pricePerYard.toStringAsFixed(2)}/yard',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${fabric.quantityAvailable}',
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabricListTile(Fabric fabric) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: fabric.imageUrls.isNotEmpty
              ? Image.network(
                  fabric.imageUrls[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                )
              : const Center(child: Icon(Icons.image_not_supported)),
        ),
        title: Text(fabric.color),
        subtitle: Text(fabric.getFabricTypeString()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${fabric.pricePerYard.toStringAsFixed(2)}/yard',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildStockStatusText(fabric),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge(Fabric fabric) {
    late Color badgeColor;
    late Color textColor;

    if (fabric.isOutOfStock) {
      badgeColor = Colors.red;
      textColor = Colors.white;
    } else if (fabric.isLowStock()) {
      badgeColor = Colors.orange;
      textColor = Colors.white;
    } else {
      badgeColor = Colors.green;
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        fabric.getStockStatus(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStockStatusText(Fabric fabric) {
    late Color textColor;

    if (fabric.isOutOfStock) {
      textColor = Colors.red;
    } else if (fabric.isLowStock()) {
      textColor = Colors.orange;
    } else {
      textColor = Colors.green;
    }

    return Text(
      fabric.getStockStatus(),
      style: TextStyle(
        fontSize: 12,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
