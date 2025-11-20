import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class FlightManagementScreen extends StatefulWidget {
  const FlightManagementScreen({super.key});

  @override
  State<FlightManagementScreen> createState() => _FlightManagementScreenState();
}

class _FlightManagementScreenState extends State<FlightManagementScreen> {
  final flightsRef = FirebaseFirestore.instance.collection('flights');

  Future<void> _showEditDialog([DocumentSnapshot? doc]) async {
    final idCtrl = TextEditingController(text: doc?.get('flightNumber') ?? '');
    final fromCtrl = TextEditingController(text: doc?.get('from') ?? '');
    final toCtrl = TextEditingController(text: doc?.get('to') ?? '');
    final priceCtrl = TextEditingController(text: doc?.get('price')?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? 'Add Flight' : 'Edit Flight', style: GoogleFonts.poppins()),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Flight Number')),
          TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'From')),
          TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To')),
          TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(
            onPressed: () async {
              final flight = {
                'flightNumber': idCtrl.text.trim(),
                'from': fromCtrl.text.trim(),
                'to': toCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text) ?? 0,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (doc == null) {
                await flightsRef.add({...flight, 'createdAt': FieldValue.serverTimestamp()});
              } else {
                await doc.reference.update(flight);
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(title: Text('Flight Management', style: GoogleFonts.poppins()), backgroundColor: primary),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        backgroundColor: primary,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: flightsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No flights'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              return ListTile(
                tileColor: Colors.white,
                title: Text('${data['flightNumber'] ?? '-'} • ${data['from'] ?? '-'} → ${data['to'] ?? '-'}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('₱${data['price'] ?? '-'}', style: GoogleFonts.poppins()),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditDialog(d)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Delete flight?', style: GoogleFonts.poppins()),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: GoogleFonts.poppins())),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete', style: GoogleFonts.poppins())),
                          ],
                        ),
                      );
                      if (ok == true) await d.reference.delete();
                    },
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}