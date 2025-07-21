import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart'; // Replace with your actual import
import 'package:loading_animation_widget/loading_animation_widget.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final user = FirebaseAuth.instance.currentUser;

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    if (difference.inDays > 0) {
      return 'Updated: ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return 'Updated: ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return 'Updated: ${difference.inMinutes}m ago';
    } else {
      return 'Updated: just now';
    }
  }

  Widget _buildInventoryItem(Map<String, dynamic> itemData, String docId) {
    final String name = itemData['name'] ?? 'Unnamed Item';
    final double price =
        double.tryParse(itemData['price']?.toString() ?? '0') ?? 0;
    final int quantity = itemData['quantity'] ?? 0;
    final bool isActive = itemData['isActive'] ?? false;
    final Timestamp? lastUpdatedTimestamp =
        itemData['lastUpdated'] as Timestamp?;
    final DateTime lastUpdated =
        lastUpdatedTimestamp?.toDate() ?? DateTime.now();
    final String imageUrl = itemData['imageUrl'] ?? '';

    final Widget imageWidget = imageUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: LoadingAnimationWidget.twoRotatingArc(
                    color: const Color(0xFF1B6FF5),
                    size: 40,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.fastfood,
                color: Colors.grey,
                size: 30,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          imageWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: $quantity portions',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatLastUpdated(lastUpdated),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              CustomToggleSwitch(
                value: isActive,
                onChanged: (value) async {
                  await FirebaseFirestore.instance
                      .collection('RestaurantUsers')
                      .doc(user!.uid)
                      .collection('Inventory')
                      .doc(docId)
                      .update({
                    'isActive': value,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });
                },
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.grey),
                    onPressed: () async {
                      if (quantity > 0) {
                        await FirebaseFirestore.instance
                            .collection('RestaurantUsers')
                            .doc(user!.uid)
                            .collection('Inventory')
                            .doc(docId)
                            .update({
                          'quantity': quantity - 1,
                          'lastUpdated': FieldValue.serverTimestamp(),
                          'isActive': (quantity - 1) > 0,
                        });
                      }
                    },
                  ),
                  Text(
                    quantity.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.grey),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('RestaurantUsers')
                          .doc(user!.uid)
                          .collection('Inventory')
                          .doc(docId)
                          .update({
                        'quantity': quantity + 1,
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateInventoryStats(List<QueryDocumentSnapshot> docs) {
    int totalItems = docs.length;
    int availableItems = docs.where((doc) => doc['isActive'] == true).length;
    int unavailableItems = totalItems - availableItems;
    return {
      'total': totalItems,
      'available': availableItems,
      'unavailable': unavailableItems,
    };
  }

  void _markAllAsAvailable() async {
    final uid = user!.uid;
    final inventoryRef = FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('Inventory');
    final snapshot = await inventoryRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'isActive': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _markAllAsUnavailable() async {
    final uid = user!.uid;
    final inventoryRef = FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('Inventory');
    final snapshot = await inventoryRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'isActive': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Text(
          'Inventory',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('RestaurantUsers')
              .doc(user!.uid)
              .collection('Inventory')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error loading inventory'));
            }
            if (!snapshot.hasData) {
              return Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: const Color(0xFF1B6FF5),
                  size: 50,
                ),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/empty-box.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your inventory is empty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'BAUHAUSM', // Use Bauhaus font
                        fontSize: 25,
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final inventoryStats = _calculateInventoryStats(docs);

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        cursorColor: Colors.black,
                        cursorWidth: 0.9,
                        decoration: InputDecoration(
                          hintText: 'Search for food...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF1B6FF5)),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Updated to 12
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Updated to 12
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontFamily: 'BAUHAUSM',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${inventoryStats['total']}',
                                  style: TextStyle(
                                    fontFamily: 'BAUHAUSM',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Available',
                                  style: TextStyle(
                                    fontFamily: 'BAUHAUSM',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${inventoryStats['available']}',
                                  style: TextStyle(
                                    fontFamily: 'BAUHAUSM',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    fontFamily: 'BAUHAUSM',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${inventoryStats['unavailable']}',
                                  style: TextStyle(
                                    fontFamily: 'BAUHAUSM',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return _buildInventoryItem(
                                doc.data() as Map<String, dynamic>, doc.id);
                          },
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B6FF5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // Updated to 12
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _markAllAsAvailable,
                          child: Text(
                            'Mark All Available',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // Updated to 12
                              side: const BorderSide(color: Colors.black),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _markAllAsUnavailable,
                          child: Text(
                            'Mark All Unavailable',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CustomToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? const Color(0xFF1B6FF5) : Colors.grey.shade200,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: InventoryPage(),
    debugShowCheckedModeBanner: false,
  ));
}
