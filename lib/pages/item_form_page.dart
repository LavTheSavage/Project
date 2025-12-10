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
  // Color palette (from user)
  static const Color kPrimary = Color(0xFF1E88E5);
  static const Color kAccent = Color(0xFFFFC107);
  static const Color kBackground = Color(0xFFF5F7FA);
  static const Color kText = Color(0xFF263238);
  // static const Color kSecondary = Color(0xFF90CAF9);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String? _selectedCategory;
  String? _selectedCondition;

  // images
  List<XFile> _pickedImages = [];
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

    _selectedCategory = widget.existingItem?['category'];

    if (_selectedCategory == 'All') {
      _selectedCategory = null; // or set to first valid category
    }

    if (_selectedCategory == null && widget.categories.isNotEmpty) {
      // pick first non-All category
      _selectedCategory = widget.categories.firstWhere(
        (c) => c != 'All',
        orElse: () => '',
      );
    }

    // Add condition field default (since user requested it)
    _selectedCondition = widget.existingItem?['condition'] ?? 'New';

    // Load existing images if editing (support 'images' list or single 'image')
    if (widget.existingItem != null) {
      final raw = widget.existingItem!['images'];
      if (raw is List) {
        _pickedImages = raw.whereType<String>().map((p) => XFile(p)).toList();
      } else if (widget.existingItem!['image'] != null &&
          widget.existingItem!['image'] is String) {
        _pickedImages = [XFile(widget.existingItem!['image'])];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      final List<XFile>? images = await picker.pickMultiImage(imageQuality: 82);
      if (!mounted) return;
      if (images != null && images.isNotEmpty) {
        final allowed = images.take(_maxImages - _pickedImages.length);
        setState(() {
          final wasEmpty = _pickedImages.isEmpty;
          _pickedImages.addAll(allowed);
          // if previously empty, keep first as cover naturally
          if (wasEmpty && _pickedImages.isNotEmpty) {
            // nothing else needed
          }
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

  void _removeImage(int idx) {
    if (idx < 0 || idx >= _pickedImages.length) return;
    setState(() {
      _pickedImages.removeAt(idx);
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
            child: InteractiveViewer(child: Image.file(File(img.path))),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final imagesPaths = _pickedImages.map((x) => x.path).toList();
    final result = {
      'name': _nameController.text.trim(),
      'price': _priceController.text.trim(),
      'category': _selectedCategory,
      'condition': _selectedCondition,
      'description': _descriptionController.text.trim(),
      'images': imagesPaths,
      'image': imagesPaths.isNotEmpty ? imagesPaths[0] : null,
      'owner': widget.existingItem?['owner'],
    };

    Navigator.of(context).pop(result);
  }

  Widget _buildThumbnail(XFile file, int index) {
    final isCover = index == 0;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => _previewImage(file, index),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(file.path),
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
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
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: kPrimary,
      padding: const EdgeInsets.only(top: 18, bottom: 18, left: 12),
      child: Row(
        children: [
          // circular back icon
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isEditMode ? 'Edit Item' : 'Add Item',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? label}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Details:" label like screenshot
                      const Text(
                        'Details:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Name + Price fields (stacked)
                      Container(
                        decoration: BoxDecoration(color: Colors.transparent),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                label: 'Item Name',
                                hint: 'Enter item name',
                              ),
                              style: const TextStyle(color: kText),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter item name'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                label: 'Price (Rs)',
                                hint: '0',
                              ),
                              style: const TextStyle(color: kText),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter price';
                                }
                                final p = double.tryParse(v);
                                if (p == null) return 'Enter valid number';
                                if (p <= 0) return 'Price must be > 0';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Image insert big box
                      GestureDetector(
                        onTap: _isLoading ? null : _pickImages,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (_pickedImages.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: kText.withOpacity(0.18),
                                            width: 2.5,
                                          ),
                                          color: Colors.white,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.add,
                                          size: 30,
                                          color: kText.withOpacity(0.45),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Insert Images here',
                                        style: TextStyle(
                                          color: kText.withOpacity(0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                // preview first image as big background
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(_pickedImages[0].path),
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              // top-right counter
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_pickedImages.length}/$_maxImages',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Thumbnails row
                      if (_pickedImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            itemBuilder: (ctx, i) =>
                                _buildThumbnail(_pickedImages[i], i),
                          ),
                        ),

                      const SizedBox(height: 18),

                      // Category & Condition side-by-side
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category:',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    decoration: const InputDecoration.collapsed(
                                      hintText: '',
                                    ),
                                    items: widget.categories
                                        .where((c) => c != 'All')
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedCategory = v),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Select category'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Condition:',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCondition,
                                    decoration: const InputDecoration.collapsed(
                                      hintText: '',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'New',
                                        child: Text('New'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Like New',
                                        child: Text('Like New'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Fair',
                                        child: Text('Fair'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Fairly Used',
                                        child: Text('Fairly Used'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedCondition = v),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Select condition'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Description large box
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 5,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText:
                              'Provide details: accessories, pickup/delivery, contact notes...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a description'
                            : null,
                      ),

                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 6,
                          ),
                          child: Text(
                            isEditMode ? 'Save Changes' : 'Submit',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],
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
