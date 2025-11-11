import 'dart:io';
import 'package:flutter/material.dart';

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? ''),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedItem = await Navigator.pushNamed(
                context,
                '/editItem',
                arguments: item,
              );
              if (updatedItem != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Item updated!')));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (item['image'] != null)
              Image.file(File(item['image']), height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(
              item['name'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Category: ${item['category'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Price: Rs ${item['price'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              item['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
