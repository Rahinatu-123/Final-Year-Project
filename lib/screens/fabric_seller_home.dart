import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/fabric.dart';
import '../models/fabric_order.dart';
import '../services/fabric_seller_service.dart';
import 'fabric_seller_inventory.dart';
import 'fabric_seller_orders.dart';
import 'fabric_seller_shop_profile.dart';
import 'fabric_seller_dashboard.dart';
import 'fabric_seller_explore.dart';
import 'add_fabric_listing.dart';

class FabricSellerHome extends StatefulWidget {
  const FabricSellerHome({super.key});

  @override
  State<FabricSellerHome> createState() => _FabricSellerHomeState();
}

class _FabricSellerHomeState extends State<FabricSellerHome> {
  int _selectedIndex = 0;
  final FabricSellerService _fabricService = FabricSellerService();
  late String _sellerId;

  @override
  void initState() {
    super.initState();
    _sellerId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Fabric',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return FabricSellerExplore(sellerId: _sellerId);
      case 1:
        return FabricSellerDashboard(sellerId: _sellerId);
      case 2:
        return AddFabricListing(
          sellerId: _sellerId,
          onFabricAdded: () {
            // Refresh inventory after adding
            setState(() {});
          },
        );
      case 3:
        return FabricSellerInventory(sellerId: _sellerId);
      case 4:
        return FabricSellerShopProfile(sellerId: _sellerId);
      default:
        return FabricSellerDashboard(sellerId: _sellerId);
    }
  }
}
