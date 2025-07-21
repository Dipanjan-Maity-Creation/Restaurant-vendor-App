import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart'; // Replace with your actual import
import 'analytics_screen.dart'; // Replace with your actual import
import 'profile_page.dart'; // Replace with your actual import
import 'earning_screen.dart'; // Replace with your actual import
import 'package:loading_animation_widget/loading_animation_widget.dart';

class _MenuItemData {
  final String? docId;
  final String name;
  final String price;
  final String description;
  final String prepTime;
  final XFile? image;
  final String category;
  final String? imageUrl;
  final String? storagePath;

  _MenuItemData({
    this.docId,
    required this.name,
    required this.price,
    required this.description,
    required this.prepTime,
    required this.image,
    required this.category,
    this.imageUrl,
    this.storagePath,
  });

  _MenuItemData copyWith({
    String? docId,
    String? name,
    String? price,
    String? description,
    String? prepTime,
    XFile? image,
    String? category,
    String? imageUrl,
    String? storagePath,
  }) {
    return _MenuItemData(
      docId: docId ?? this.docId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      prepTime: prepTime ?? this.prepTime,
      image: image ?? this.image,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      storagePath: storagePath ?? this.storagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'prepTime': prepTime,
      'category': category,
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  static _MenuItemData fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return _MenuItemData(
      docId: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? '',
      description: data['description'] ?? '',
      prepTime: data['prepTime'] ?? '',
      category: data['category'] ?? 'Veg Items',
      image: null,
      imageUrl: data['imageUrl'],
      storagePath: data['storagePath'],
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.trimLines = 2,
  });

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (_expanded) {
      return Text(
        widget.text,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.text,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.trimLines,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        if (!textPainter.didExceedMaxLines) {
          return Text(
            widget.text,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
          );
        }

        final linkText = ' ...more';
        final linkSpan = TextSpan(
          text: linkText,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        );
        final linkPainter = TextPainter(
          text: linkSpan,
          textDirection: TextDirection.ltr,
        );
        linkPainter.layout(maxWidth: constraints.maxWidth);
        final linkWidth = linkPainter.size.width;

        int endIndex = widget.text.length;
        String truncatedText = widget.text;
        while (true) {
          final currentText = widget.text.substring(0, endIndex);
          final currentSpan = TextSpan(
            text: currentText,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
          );
          final tp = TextPainter(
            text: currentSpan,
            maxLines: widget.trimLines,
            textDirection: TextDirection.ltr,
          );
          tp.layout(maxWidth: constraints.maxWidth - linkWidth);
          if (!tp.didExceedMaxLines) {
            truncatedText = currentText;
            break;
          }
          endIndex--;
          if (endIndex <= 0) break;
        }

        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
            children: [
              TextSpan(text: truncatedText),
              TextSpan(
                text: linkText,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    setState(() {
                      _expanded = true;
                    });
                  },
              ),
            ],
          ),
        );
      },
    );
  }
}

class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  String _selectedCategory = 'Veg Items';
  int _selectedBottomIndex = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  XFile? _selectedImage;
  String? _existingImageUrl;
  final List<_MenuItemData> _menuItems = [];
  static const Color _purpleColor = Color(0xFF1B6FF5);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  String get _addItemButtonText {
    switch (_selectedCategory) {
      case 'Veg Items':
        return 'Add Veg Item';
      case 'Non-Veg':
        return 'Add Non-Veg Item';
      case 'Desserts':
        return 'Add Dessert Item';
      case 'Drinks':
        return 'Add Drink Item';
      default:
        return 'Add Item';
    }
  }

  bool _areFieldsValid() {
    return _nameController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        (_selectedImage != null ||
            (_existingImageUrl != null && _existingImageUrl!.isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryColor: _purpleColor,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leadingWidth: 40,
          titleSpacing: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeWidget()),
              );
            },
          ),
          title: const Text(
            'Add Menu Items',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                cursorColor: Colors.black,
                cursorWidth: 0.9,
                decoration: InputDecoration(
                  hintText: 'Search for food...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryBox(
                    label: 'Veg Items',
                    icon: Icons.eco,
                    iconColor: Colors.green,
                  ),
                  _buildCategoryBox(
                    label: 'Non-Veg',
                    icon: Icons.set_meal,
                    iconColor: Colors.redAccent,
                  ),
                  _buildCategoryBox(
                    label: 'Desserts',
                    icon: Icons.cake,
                    iconColor: Colors.pink,
                  ),
                  _buildCategoryBox(
                    label: 'Drinks',
                    icon: Icons.local_bar,
                    iconColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purpleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showAddItemBottomSheet,
                  child: Text(
                    _addItemButtonText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildMenuItemsList()),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // White background
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade400, // Grey line
                width: 0.2, // 0.4 weight
              ),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFFFFFFFF), // Ensure white background
            currentIndex: _selectedBottomIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _purpleColor,
            unselectedItemColor: Colors.black54,
            onTap: (index) => _onBottomNavTap(index),
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/Order.svg', // Updated to SVG
                  width: 24,
                  height: 24,
                  color:
                      _selectedBottomIndex == 0 ? _purpleColor : Colors.black54,
                ),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/Menu.svg', // Updated to SVG
                  width: 24,
                  height: 24,
                  color:
                      _selectedBottomIndex == 1 ? _purpleColor : Colors.black54,
                ),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/report.svg', // Updated to SVG
                  width: 24,
                  height: 24,
                  color:
                      _selectedBottomIndex == 2 ? _purpleColor : Colors.black54,
                ),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/wallet.svg', // Updated to SVG
                  width: 24,
                  height: 24,
                  color:
                      _selectedBottomIndex == 3 ? _purpleColor : Colors.black54,
                ),
                label: 'Earnings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeWidget()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnalysisWidget()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Group2541Widget()),
        );
        break;
    }
  }

  Widget _buildCategoryBox({
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    final bool isSelected = (_selectedCategory == label);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          border: Border.all(
            color: isSelected ? _purpleColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemsList() {
    final filteredItems =
        _menuItems.where((item) => item.category == _selectedCategory).toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SizedBox(
                            width: 120,
                            height: 120,
                            child: Center(
                              child: LoadingAnimationWidget.twoRotatingArc(
                                color: const Color(0xFF1B6FF5),
                                size: 50,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.error),
                          ),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fastfood),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹ ${item.price}',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ExpandableText(text: item.description),
                      const SizedBox(height: 2),
                      Text(
                        'Prepared in ~${item.prepTime} min',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/edit.svg',
                      width: 30,
                      height: 30,
                      color: const Color(0xFFA09F9F),
                    ),
                    onPressed: () => _showEditItemBottomSheet(item, index),
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/circle-trash.svg',
                      width: 30,
                      height: 30,
                      color: const Color(0xFFA09F9F),
                    ),
                    onPressed: () => _showDeleteConfirmationDialog(index),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/leaf.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 12),
          const Text(
            'No item added.',
            style: TextStyle(
              fontFamily: 'BAUHAUSM',
              fontSize: 23,
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a category and add your first menu item.',
            style: TextStyle(
              fontFamily: 'BAUHAUSM',
              fontSize: 18,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCCCC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/trash.svg',
                    width: 28,
                    height: 28,
                    color: Color(0xFFDA1313),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Delete Confirmation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BAUHAUSM',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BAUHAUSM',
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'BAUHAUSM',
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteItem(index);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: 'BAUHAUSM',
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddItemBottomSheet() async {
    _nameController.clear();
    _priceController.clear();
    _descController.clear();
    _prepTimeController.clear();
    _selectedImage = null;
    _existingImageUrl = null;
    _isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add Menu Item',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadSection(setModalState: setModalState),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Item Name',
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _prepTimeController,
                      label: 'Preparation Time',
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descController,
                      label: 'Description',
                      maxLines: 2,
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black54,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: Navigator.of(context).pop,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purpleColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _areFieldsValid() && !_isSaving
                                ? () async {
                                    setModalState(() {
                                      _isSaving = true;
                                    });
                                    await _handleAddItem();
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1B6FF5),
                                    ),
                                  )
                                : Text(
                                    'Add',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  Future<_MenuItemData> _handleAddItem() async {
    final newItem = _MenuItemData(
      docId: null,
      name: _nameController.text.trim(),
      price: _priceController.text.trim(),
      description: _descController.text.trim(),
      prepTime: _prepTimeController.text.trim(),
      image: _selectedImage,
      category: _selectedCategory,
    );

    final savedItem = await _saveMenuItem(newItem);

    setState(() {
      _menuItems.add(savedItem);
    });
    return savedItem;
  }

  Future<void> _showEditItemBottomSheet(_MenuItemData item, int index) async {
    _nameController.text = item.name;
    _priceController.text = item.price;
    _descController.text = item.description;
    _prepTimeController.text = item.prepTime;
    _selectedImage = null;
    _existingImageUrl = item.imageUrl;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Edit Menu Item',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadSection(
                      isEdit: true,
                      setModalState: setModalState,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Item Name',
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _prepTimeController,
                      label: 'Preparation Time',
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descController,
                      label: 'Description',
                      maxLines: 2,
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black54,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: Navigator.of(context).pop,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purpleColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _areFieldsValid()
                                ? () {
                                    _handleSaveItem(index);
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            child: Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _handleSaveItem(int index) async {
    final oldItem = _menuItems[index];
    String? newDownloadUrl = oldItem.imageUrl;
    String? newStoragePath = oldItem.storagePath;

    if (_selectedImage != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      newStoragePath = 'menu_images/$fileName';
      final ref = FirebaseStorage.instance.ref().child(newStoragePath);
      await ref.putFile(File(_selectedImage!.path));
      newDownloadUrl = await ref.getDownloadURL();

      if (oldItem.storagePath != null && oldItem.storagePath!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(oldItem.storagePath!).delete();
        } catch (e) {
          debugPrint('Error deleting old image from storage: $e');
        }
      }
    }

    final updatedItem = oldItem.copyWith(
      name: _nameController.text.trim(),
      price: _priceController.text.trim(),
      description: _descController.text.trim(),
      prepTime: _prepTimeController.text.trim(),
      image: _selectedImage,
      imageUrl: newDownloadUrl,
      storagePath: newStoragePath,
    );

    setState(() {
      _menuItems[index] = updatedItem;
    });

    if (updatedItem.docId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('RestaurantUsers')
              .doc(user.uid)
              .collection('RestaurantDetails')
              .doc(user.uid)
              .collection('MenuItems')
              .doc(updatedItem.docId)
              .update(updatedItem.toMap());

          await FirebaseFirestore.instance
              .collection('RestaurantUsers')
              .doc(user.uid)
              .collection('Inventory')
              .doc(updatedItem.docId)
              .update({
            'name': updatedItem.name,
            'price': updatedItem.price,
            'imageUrl': newDownloadUrl,
          });
        } catch (e) {
          debugPrint('Error updating menu item in Firestore: $e');
        }
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final item = _menuItems[index];

    setState(() {
      _menuItems.removeAt(index);
    });

    if (item.docId != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('RestaurantUsers')
              .doc(user.uid)
              .collection('RestaurantDetails')
              .doc(user.uid)
              .collection('MenuItems')
              .doc(item.docId)
              .delete();

          await FirebaseFirestore.instance
              .collection('RestaurantUsers')
              .doc(user.uid)
              .collection('Inventory')
              .doc(item.docId)
              .delete();
        }
      } catch (e) {
        debugPrint('Error deleting item from Firestore: $e');
      }
    }

    if (item.storagePath != null && item.storagePath!.isNotEmpty) {
      try {
        await FirebaseStorage.instance.ref(item.storagePath!).delete();
      } catch (e) {
        debugPrint('Error deleting image from Storage: $e');
      }
    }
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
      setModalState(() {});
    }
  }

  Future<void> _loadItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid)
          .collection('RestaurantDetails')
          .doc(user.uid)
          .collection('MenuItems')
          .get();

      final loadedItems = querySnapshot.docs.map((doc) {
        return _MenuItemData.fromDoc(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
      }).toList();

      setState(() {
        _menuItems
          ..clear()
          ..addAll(loadedItems);
      });
    } catch (e) {
      debugPrint('Error loading menu items: $e');
    }
  }

  Future<_MenuItemData> _saveMenuItem(_MenuItemData item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user signed in')),
        );
        return item;
      }

      String? downloadUrl;
      String? storagePath;

      if (item.image != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        storagePath = 'menu_images/$fileName';
        final ref = FirebaseStorage.instance.ref().child(storagePath);
        await ref.putFile(File(item.image!.path));
        downloadUrl = await ref.getDownloadURL();
        print('Image uploaded to $storagePath, URL: $downloadUrl');
      }

      final menuItemData = item
          .copyWith(
        imageUrl: downloadUrl,
        storagePath: storagePath,
      )
          .toMap();

      final docRef = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid)
          .collection('RestaurantDetails')
          .doc(user.uid)
          .collection('MenuItems')
          .add(menuItemData);

      await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid)
          .collection('Inventory')
          .doc(docRef.id)
          .set({
        'menuItemId': docRef.id,
        'name': item.name,
        'category': item.category,
        'price': item.price,
        'quantity': 0,
        'isActive': false,
        'imageUrl': downloadUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Successfully saved menu item: ${docRef.id}');
      return item.copyWith(
        docId: docRef.id,
        imageUrl: downloadUrl,
        storagePath: storagePath,
      );
    } catch (e) {
      print('Error saving menu item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save menu item: $e')),
      );
      return item;
    }
  }

  Widget _buildImageUploadSection({
    bool isEdit = false,
    required StateSetter setModalState,
  }) {
    final bool hasLocalImage = (_selectedImage != null);
    final bool hasNetworkImage =
        isEdit && (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: () => _pickImage(setModalState),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: hasLocalImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
              )
            : hasNetworkImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _existingImageUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.error),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          color: Colors.grey.shade700, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        isEdit ? 'Change Item Photo' : 'Add Item Photo',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          cursorColor: Colors.black,
          cursorWidth: 0.9,
          style: GoogleFonts.poppins(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(const MenuWidget());
}