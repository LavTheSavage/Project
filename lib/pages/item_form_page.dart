import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ItemFormPage extends StatefulWidget {
  final List<String> categories;
  final Map<String, dynamic>? existingItem;

  const ItemFormPage({super.key, required this.categories, this.existingItem});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;

  String? _selectedCategory;
  XFile? _pickedImage;

  bool _isLoading = false;

  bool get isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.existingItem?['name'] ?? '',
    );

    _priceController = TextEditingController(
      text: widget.existingItem?['price'] ?? '',
    );

    _selectedCategory =
        widget.existingItem?['category'] ??
        (widget.categories.length > 1
            ? widget.categories[1]
            : widget.categories.first);

    // Load existing image if editing
    if (widget.existingItem != null &&
        widget.existingItem!['image'] != null &&
        widget.existingItem!['image'] is String) {
      _pickedImage = XFile(widget.existingItem!['image']);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return;

      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = {
        'name': _nameController.text,
        'price': _priceController.text,
        'category': _selectedCategory,
        'description': widget.existingItem?['description'] ?? '',
        'image': _pickedImage?.path,
        'owner': widget.existingItem?['owner'],
      };

      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Item' : 'Add Item'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE PREVIEW
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                          image: _pickedImage != null
                              ? DecorationImage(
                                  image: FileImage(File(_pickedImage!.path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _pickedImage == null
                            ? const Icon(Icons.photo, size: 60)
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // PICK IMAGE BUTTON
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickImage,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: const Text("Upload Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter item name' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter price';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Enter valid number';
                    if (parsed <= 0) return 'Price must be > 0';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories
                      .where((c) => c != 'All')
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),

                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 15,
                      ),
                    ),
                    child: Text(isEditMode ? 'Save Changes' : 'Add Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
