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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = '';
  XFile? _pickedImage;
  bool _isLoading = false;
  bool get isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    final available = widget.categories.where((c) => c != 'All').toList();
    _selectedCategory = available.isNotEmpty
        ? available.first
        : (widget.categories.isNotEmpty ? widget.categories.first : 'All');

    if (isEditMode) {
      final item = widget.existingItem!;
      _nameController.text = item['name'] ?? '';
      _priceController.text = item['price'] ?? '';
      _descController.text = item['description'] ?? '';
      _selectedCategory = item['category'] ?? _selectedCategory;
      if (item['image'] != null) {
        _pickedImage = XFile(item['image']);
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return;

      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final newItem = {
        'name': _nameController.text,
        'price': _priceController.text,
        'description': _descController.text,
        'category': _selectedCategory,
        'image': _pickedImage?.path,
      };
      Navigator.pop(context, newItem);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
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
              children: [
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
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter price';
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Price must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter item description'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories
                      .where((cat) => cat != 'All')
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),
                if (_pickedImage != null)
                  Image.file(File(_pickedImage!.path), height: 100),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(_isLoading ? 'Loading...' : 'Pick Image'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveItem,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
