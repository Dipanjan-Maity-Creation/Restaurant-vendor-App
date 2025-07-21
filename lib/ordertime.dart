import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderActionWidget extends StatefulWidget {
  final int initialPrepMinutes;
  final String orderId; // Unique ID for the order
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTimeout;

  const OrderActionWidget({
    super.key,
    required this.initialPrepMinutes,
    required this.orderId,
    required this.onAccept,
    required this.onDecline,
    required this.onTimeout,
  });

  @override
  State<OrderActionWidget> createState() => _OrderActionWidgetState();
}

class _OrderActionWidgetState extends State<OrderActionWidget> {
  late int _prepMinutes;
  late Timer _timer;
  late int _remainingSeconds;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _prepMinutes = widget.initialPrepMinutes;
    _remainingSeconds = 600; // 30-second countdown for accepting the order
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onTimeout();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _updatePrepTimeInFirestore() async {
    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'prepMinutes': _prepMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating prep time: $e');
      // Optionally show a snackbar or dialog to inform the user
    }
  }

  void _increasePrepTime() {
    setState(() {
      _prepMinutes++;
    });
    _updatePrepTimeInFirestore();
  }

  void _decreasePrepTime() {
    setState(() {
      if (_prepMinutes > 1) {
        _prepMinutes--;
      }
    });
    _updatePrepTimeInFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.blue),
              onPressed: _decreasePrepTime,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '$_prepMinutes mins',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: _increasePrepTime,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: widget.onDecline,
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  _updatePrepTimeInFirestore(); // Save prep time before accepting
                  widget.onAccept();
                },
                child: Text('Accept (${_formatCountdown(_remainingSeconds)})'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}