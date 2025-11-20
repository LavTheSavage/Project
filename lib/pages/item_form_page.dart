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
  late TextEditingController _descriptionController;

  String? _selectedCategory;

  // images & cover
  List<XFile> _pickedImages = [];
  int _coverIndex = 0;

  bool _isLoading = false;
  static const int _maxImages = 5;

  bool get isEditMode => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.existingItem?['name'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existingItem?['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingItem?['description'] ?? '',
    );

    _selectedCategory =
        widget.existingItem?['category'] ??
        (widget.categories.length > 1
            ? widget.categories[1]
            : widget.categories.first);

    // Load existing images if editing (support 'images' list or single 'image')
    if (widget.existingItem != null) {
      final raw = widget.existingItem!['images'];
      if (raw is List) {
        _pickedImages = raw.whereType<String>().map((p) => XFile(p)).toList();
      } else if (widget.existingItem!['image'] != null &&
          widget.existingItem!['image'] is String) {
        _pickedImages = [XFile(widget.existingItem!['image'])];
      }
      _coverIndex = widget.existingItem?['coverIndex'] is int
          ? widget.existingItem!['coverIndex']
          : 0;
      if (_coverIndex >= _pickedImages.length) _coverIndex = 0;
    }
  }

  Future<void> _pickImages() async {
    if (_pickedImages.length >= _maxImages) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Max 5 images allowed')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final List<XFile>? images = await picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      if (images != null && images.isNotEmpty) {
        final allowed = images.take(_maxImages - _pickedImages.length);
        setState(() {
          final wasEmpty = _pickedImages.isEmpty;
          _pickedImages.addAll(allowed);
          // first picked (existing or newly added) is the cover by design
          if (wasEmpty && _pickedImages.isNotEmpty) _coverIndex = 0;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removePickedImage(int index) {
    if (index < 0 || index >= _pickedImages.length) return;
    setState(() {
      _pickedImages.removeAt(index);
      if (_coverIndex >= _pickedImages.length) _coverIndex = 0;
    });
  }

  void _previewImage(XFile img, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
          body: Center(
            child: Hero(
              tag: 'item_form_img_$index',
              child: InteractiveViewer(child: Image.file(File(img.path))),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final imagesPaths = _pickedImages.map((x) => x.path).toList();
      final result = {
        'name': _nameController.text.trim(),
        'price': _priceController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'images': imagesPaths,
        // first image is cover by design
        'image': imagesPaths.isNotEmpty ? imagesPaths[0] : null,
        'coverIndex': imagesPaths.isNotEmpty ? 0 : null,
        'owner': widget.existingItem?['owner'],
      };

      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildThumbnail(XFile img, int index) {
    final isCover = index == 0; // first image is cover
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _previewImage(img, index),
        child: Stack(
          children: [
            Hero(
              tag: 'item_form_img_$index',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(img.path),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: () => _removePickedImage(index),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
            if (isCover)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Cover',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Item' : 'Add Item'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BASIC DETAILS SECTION (moved up for better flow)
                _sectionHeader('Basic details'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 32" LED TV',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter item name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price (Rs)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter price';
                            }
                            final parsed = double.tryParse(value);
                            if (parsed == null) return 'Enter valid number';
                            if (parsed <= 0) return 'Price must be > 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // IMAGES SECTION (moved below basic details)
                _sectionHeader('Photos'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[100],
                          ),
                          child: _pickedImages.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.photo,
                                    size: 60,
                                    color: Colors.black26,
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _pickedImages.length,
                                  itemBuilder: (ctx, i) =>
                                      _buildThumbnail(_pickedImages[i], i),
                                ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Recommended: high-resolution photos. Max 5 images. Avoid heavy compression.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickImages,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library),
                              label: Text(
                                'Select Images (${_pickedImages.length}/$_maxImages)',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black26,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // CATEGORY SECTION
                _sectionHeader('Category'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose category',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: widget.categories
                          .where((c) => c != 'All')
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select category' : null,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // DESCRIPTION SECTION
                _sectionHeader('Description'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText:
                            'Provide details: accessories, pickup/delivery, contact notes...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      minLines: 4,
                      maxLines: 8,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a description'
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // SAVE BUTTON
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
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
