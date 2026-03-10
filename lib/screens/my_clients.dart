import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/tailor_client.dart';
import '../models/custom_order.dart';
import '../services/tailor_client_service.dart';
import '../services/custom_order_service.dart';
import '../theme/app_theme.dart';
import 'orders.dart';
import 'style_gallery.dart';

class MyClientsScreen extends StatefulWidget {
  final String tailorId;
  final String tailorName;

  const MyClientsScreen({
    Key? key,
    required this.tailorId,
    required this.tailorName,
  }) : super(key: key);

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends State<MyClientsScreen> {
  late TailorClientService clientService;
  late CustomOrderService orderService;
  List<TailorClient> clients = [];
  Map<String, int> _clientOrderCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    clientService = TailorClientService();
    orderService = CustomOrderService();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final loadedClients = await clientService.getClientsByTailorId(
        widget.tailorId,
      );

      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('custom_orders')
          .where('tailorId', isEqualTo: widget.tailorId)
          .get();

      final Map<String, int> counts = {};
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final clientId = (data['clientId'] as String?) ?? '';
        if (clientId.isEmpty) continue;
        counts[clientId] = (counts[clientId] ?? 0) + 1;
      }

      setState(() {
        clients = loadedClients;
        _clientOrderCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading clients: $e')));
      }
    }
  }

  void _showAddClientForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AddClientForm(tailorId: widget.tailorId, onClientAdded: _loadClients),
    );
  }

  void _openClientOrders(TailorClient client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdersScreen(
          tailorId: widget.tailorId,
          clientId: client.id,
          clientName: client.name,
        ),
      ),
    ).then((_) => _loadClients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
        backgroundColor: AppColors.primary,
        elevation: 1,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No clients yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add clients to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                return ClientCard(
                  client: clients[index],
                  orderCount: _clientOrderCounts[clients[index].id] ?? 0,
                  onTap: () => _openClientOrders(clients[index]),
                  onDelete: () async {
                    final confirm = await _showDeleteConfirmation();
                    if (confirm) {
                      try {
                        await clientService.deleteClient(
                          widget.tailorId,
                          clients[index].id,
                        );
                        _loadClients();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Client'),
            content: const Text('Are you sure you want to remove this client?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class ClientCard extends StatelessWidget {
  final TailorClient client;
  final int orderCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ClientCard({
    Key? key,
    required this.client,
    required this.orderCount,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child:
                  client.profileImageUrl != null &&
                      client.profileImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        client.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            client.name.isEmpty
                                ? '?'
                                : client.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        client.name.isEmpty
                            ? '?'
                            : client.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Client Name & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Orders: $orderCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((client.phone ?? '').isNotEmpty)
                        Text(
                          client.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete Button
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 18),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class AddClientForm extends StatefulWidget {
  final String tailorId;
  final VoidCallback onClientAdded;

  const AddClientForm({
    Key? key,
    required this.tailorId,
    required this.onClientAdded,
  }) : super(key: key);

  @override
  State<AddClientForm> createState() => _AddClientFormState();
}

class _AddClientFormState extends State<AddClientForm> {
  late TailorClientService clientService;
  late CustomOrderService orderService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form Controllers
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _styleController = TextEditingController();
  final _priceController = TextEditingController();

  // Images
  File? _profileImage;
  File? _styleImage;
  String? _styleImageUrl; // URL from style gallery

  // Measurements
  final Map<String, TextEditingController> _measurementControllers = {
    'Chest': TextEditingController(),
    'Waist': TextEditingController(),
    'Length': TextEditingController(),
    'Sleeve': TextEditingController(),
    'Hip': TextEditingController(),
  };
  final List<Map<String, TextEditingController>> _customMeasurements = [];

  int _daysToDeliver = 7;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    clientService = TailorClientService();
    orderService = CustomOrderService();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _styleController.dispose();
    _priceController.dispose();
    for (var controller in _measurementControllers.values) {
      controller.dispose();
    }
    for (var custom in _customMeasurements) {
      custom.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  void _showImagePickerOptions(bool isProfilePhoto) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isProfilePhoto ? 'Add Profile Photo' : 'Add Style Image',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (isProfilePhoto) ...[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(isProfilePhoto, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(isProfilePhoto, ImageSource.camera);
                  },
                ),
              ] else ...[
                // Style image options
                ListTile(
                  leading: const Icon(Icons.collections),
                  title: const Text('Style Gallery'),
                  subtitle: const Text('Browse from style collection'),
                  onTap: () {
                    Navigator.pop(context);
                    _openStyleGallery();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Upload from Phone'),
                  subtitle: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(isProfilePhoto, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(isProfilePhoto, ImageSource.camera);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isProfilePhoto, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isProfilePhoto) {
            _profileImage = File(pickedFile.path);
          } else {
            _styleImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _openStyleGallery() async {
    final selectedStyle = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(0),
        child: _StyleGallerySelector(
          onStyleSelected: (styleImageUrl) {
            Navigator.pop(context, styleImageUrl);
          },
        ),
      ),
    );

    if (selectedStyle != null && selectedStyle.isNotEmpty) {
      setState(() {
        _styleImageUrl = selectedStyle;
        _styleImage = null; // Clear local file selection
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName =
          '$folder/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
      return null;
    }
  }

  String _buildMeasurementsString() {
    List<String> measurements = [];
    _measurementControllers.forEach((label, controller) {
      if (controller.text.trim().isNotEmpty) {
        measurements.add('$label: ${controller.text.trim()}"');
      }
    });
    for (var custom in _customMeasurements) {
      final label = custom['label']?.text.trim() ?? '';
      final value = custom['value']?.text.trim() ?? '';
      if (label.isNotEmpty && value.isNotEmpty) {
        measurements.add('$label: $value"');
      }
    }
    return measurements.join(', ');
  }

  void _addCustomMeasurement() {
    setState(() {
      _customMeasurements.add({
        'label': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomMeasurement(int index) {
    setState(() {
      _customMeasurements[index].values.forEach((c) => c.dispose());
      _customMeasurements.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_clientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter client name')));
      return;
    }

    if (_styleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter style')));
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter price')));
      return;
    }

    if (_buildMeasurementsString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one measurement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create TailorClient
      final client = TailorClient(
        id: '',
        tailorId: widget.tailorId,
        name: _clientNameController.text.trim(),
        phone: _clientPhoneController.text.trim(),
        email: _clientEmailController.text.trim(),
        profileImageUrl: null,
        createdAt: DateTime.now(),
      );

      final clientId = await clientService.createOrGetClientForOrder(client);

      // Determine style image URL
      String? styleImageUrl;

      // Priority: Gallery selection first, then uploaded image
      if (_styleImageUrl != null && _styleImageUrl!.isNotEmpty) {
        styleImageUrl = _styleImageUrl;
      } else if (_styleImage != null) {
        styleImageUrl = await _uploadImage(_styleImage!, 'style_photos');
      }

      // Create CustomOrder
      final order = CustomOrder(
        id: '',
        tailorId: widget.tailorId,
        clientName: _clientNameController.text.trim(),
        clientId: clientId,
        style: _styleController.text.trim(),
        basePrice: double.parse(_priceController.text.trim()),
        measurements: _buildMeasurementsString(),
        daysToDeliver: _daysToDeliver,
        styleImageUrl: styleImageUrl,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: _daysToDeliver)),
      );

      await orderService.createCustomOrder(order);

      if (mounted) {
        Navigator.pop(context);
        widget.onClientAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Name
                  TextFormField(
                    controller: _clientNameController,
                    decoration: InputDecoration(
                      labelText: 'Client Name *',
                      hintText: 'Enter client name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Client Phone (recommended)',
                      hintText: 'e.g., 0241234567',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Client Email (optional)',
                      hintText: 'e.g., client@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Order Details
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Style
                  TextFormField(
                    controller: _styleController,
                    decoration: InputDecoration(
                      labelText: 'Style *',
                      hintText: 'e.g., Dress, Suit, Shirt',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Style Image
                  GestureDetector(
                    onTap: () => _showImagePickerOptions(false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _styleImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _styleImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _styleImage = null),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _styleImageUrl != null && _styleImageUrl!.isNotEmpty
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _styleImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                size: 36,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Error loading image',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _styleImageUrl = null),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap to add style image',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Price
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Price (GH₵) *',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // Section: Measurements
                  const Text(
                    'Measurements',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.5,
                    children: _measurementControllers.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: entry.value,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g., 40',
                              suffix: const Text(
                                '"',
                                style: TextStyle(fontSize: 11),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  // Custom Measurements
                  if (_customMeasurements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._customMeasurements.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, TextEditingController> measurement =
                          entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: measurement['label'],
                                decoration: InputDecoration(
                                  hintText: 'Label',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: measurement['value'],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'Value',
                                  suffix: const Text(
                                    '"',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeCustomMeasurement(index),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _addCustomMeasurement,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 4),
                          Text('Add Custom Measurement'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Section: Delivery
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Days to Deliver: $_daysToDeliver days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Slider(
                        value: _daysToDeliver.toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59,
                        label: '$_daysToDeliver days',
                        onChanged: (value) {
                          setState(() => _daysToDeliver = value.toInt());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Footer Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Style Gallery Selector widget for selecting styles
class _StyleGallerySelector extends StatefulWidget {
  final Function(String) onStyleSelected;

  const _StyleGallerySelector({required this.onStyleSelected});

  @override
  State<_StyleGallerySelector> createState() => _StyleGallerySelectorState();
}

class _StyleGallerySelectorState extends State<_StyleGallerySelector> {
  int _selectedCategoryIndex = 0;

  List<String> get categories {
    return [
      'All',
      'long dress',
      'short dress',
      'ladies top',
      'top and down',
      'bridal kenta',
      'jumpsuit',
      'lace',
      'kaba and slit',
      'men',
      'couple',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Style",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(child: _buildStyleGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              alignment: Alignment.center,
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleGrid() {
    final selectedCategory = categories[_selectedCategoryIndex];

    return StreamBuilder<QuerySnapshot>(
      stream: selectedCategory == 'All'
          ? FirebaseFirestore.instance.collection('styles').snapshots()
          : FirebaseFirestore.instance
                .collection('styles')
                .where('category', isEqualTo: selectedCategory)
                .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final styles = snapshot.data!.docs;

        if (styles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No styles found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: styles.length,
          itemBuilder: (context, index) {
            final style = styles[index].data() as Map<String, dynamic>;
            final imageUrl = (style['imageUrl'] as String?) ?? '';

            return GestureDetector(
              onTap: imageUrl.isNotEmpty
                  ? () {
                      widget.onStyleSelected(imageUrl);
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.primary.withOpacity(0.1),
                                    child: Icon(
                                      Icons.error_outline,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            )
                          : Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                    // Category label
                    if (style['category'] != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            style['category'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
