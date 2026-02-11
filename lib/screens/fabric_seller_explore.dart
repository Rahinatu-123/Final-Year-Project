import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/fabric.dart';
import '../services/fabric_seller_service.dart';

class FabricSellerExplore extends StatefulWidget {
  final String sellerId;

  const FabricSellerExplore({super.key, required this.sellerId});

  @override
  State<FabricSellerExplore> createState() => _FabricSellerExploreState();
}

class _FabricSellerExploreState extends State<FabricSellerExplore> {
  final FabricSellerService _fabricService = FabricSellerService();
  final TextEditingController _searchController = TextEditingController();
  FabricType? _selectedType;
  List<Fabric> _allFabrics = [];
  List<Fabric> _filteredFabrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFabrics();
  }

  Future<void> _loadFabrics() async {
    setState(() => _isLoading = true);
    try {
      // Load fabrics from other sellers or marketplace
      // For now, we'll show an empty state with instructions
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading fabrics: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Market'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search fabrics, sellers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => _filterFabrics(),
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FabricType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(type.toString().split('.').last),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type : null;
                          _filterFabrics();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Fabrics Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFabrics.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
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
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No fabrics found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Browse trending fabrics and market insights',
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
          // Fabric Image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey[200],
              ),
              child: fabric.imageUrls.isNotEmpty
                  ? Image.network(fabric.imageUrls[0], fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.image_not_supported)),
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
                    'By: ${fabric.sellerName}',
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filterFabrics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFabrics = _allFabrics.where((fabric) {
        final matchesSearch =
            fabric.color.toLowerCase().contains(query) ||
            fabric.pattern.toLowerCase().contains(query) ||
            fabric.sellerName.toLowerCase().contains(query);
        final matchesType =
            _selectedType == null || fabric.fabricType == _selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
