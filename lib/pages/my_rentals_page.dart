import 'package:flutter/material.dart';

class MyRentalsPage extends StatelessWidget {
  final List<Map<String, dynamic>> rentals;
  const MyRentalsPage({super.key, this.rentals = const []});

  @override
  Widget build(BuildContext context) {
    final r = rentals.where((it) => it['rentedBy'] != null).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Rentals"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: r.isEmpty
          ? const Center(child: Text("You have not rented any items yet."))
          : ListView.builder(
              itemCount: r.length,
              itemBuilder: (context, i) {
                final item = r[i];
                return ListTile(
                  title: Text(item['name'] ?? ''),
                  subtitle: Text('Rented by: ${item['rentedBy']}'),
                );
              },
            ),
    );
  }
}
