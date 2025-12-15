import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hamrosaman/main.dart';
import 'package:hamrosaman/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
// import your supabase & ItemService here
// import 'package:hamrosaman/services/item_service.dart';
// import 'package:hamrosaman/main.dart'; // only if needed

class ItemFormPage extends StatefulWidget {
  final List<String> categories;
  final Map<String, dynamic>? existingItem;

  const ItemFormPage({super.key, required this.categories, this.existingItem});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  // Color palette
  static const Color kPrimary = Color(0xFF1E88E5);
  static const Color kAccent = Color(0xFFFFC107);
  static const Color kBackground = Color(0xFFF5F7FA);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  String? _selectedCategory;
  String? _selectedCondition;

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
    _locationController = TextEditingController(
      text: widget.existingItem?['location'] ?? '',
    );

    _selectedCategory = widget.existingItem?['category'];
    if (_selectedCategory == 'All') _selectedCategory = null;
    if (_selectedCategory == null && widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.firstWhere(
        (c) => c != 'All',
        orElse: () => '',
      );
    }

    _selectedCondition = widget.existingItem?['condition'] ?? 'New';

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
    _locationController.dispose();
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
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 82);
      if (!mounted) return;
      if (images.isNotEmpty) {
        final allowed = images.take(_maxImages - _pickedImages.length);
        setState(() {
          _pickedImages.addAll(allowed);
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
    setState(() => _pickedImages.removeAt(idx));
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final storage = StorageService();
      final uploadedUrls = await Future.wait(
        _pickedImages.map((img) => storage.uploadImage(img)),
      );

      final payload = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'description': _descriptionController.text.trim(),
        'images': uploadedUrls,
        'location': _locationController.text.trim(),
      };

      if (isEditMode) {
        final id = widget.existingItem!['id'];
        await supabase.from('items').update(payload).eq('id', id);
      } else {
        await ItemService().addItem(payload);
      }

      if (mounted) Navigator.of(context).pop(payload);
    } catch (e) {
      debugPrint('Error saving item: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLoadingOverlay() {
    return AbsorbPointer(
      absorbing: true, // blocks interaction
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 14),
              Text(
                'Uploading...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: kPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        isEditMode ? 'Edit Item' : 'Add Items',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      centerTitle: false,
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildImageCounter() {
    return Positioned(
      right: 12,
      top: 12,
      child: GestureDetector(
        onTap: _isLoading ? null : _pickImages,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_pickedImages.length} / $_maxImages',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isLoading,
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: _buildTopBar(),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// DETAILS
                      const Text(
                        'Details:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      /// ITEM NAME
                      const Text('Item Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(hint: 'Enter item name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 12),

                      /// PRICE
                      const Text('Price:-'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(hint: 'Rs'),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                            ? 'Enter valid price'
                            : null,
                      ),

                      const SizedBox(height: 18),

                      /// IMAGE PICKER
                      GestureDetector(
                        onTap: _isLoading ? null : _pickImages,
                        child: Container(
                          height: 190,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _pickedImages.isEmpty
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey.shade400,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 28,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Insert Images here',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Image.file(
                                      File(_pickedImages.first.path),
                                      fit: BoxFit.cover,
                                    ),

                              if (_pickedImages.isNotEmpty)
                                _buildImageCounter(),
                            ],
                          ),
                        ),
                      ),

                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            itemBuilder: (_, i) =>
                                _buildThumbnail(_pickedImages[i], i),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      /// CATEGORY + CONDITION
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: _inputDecoration(),
                              items: widget.categories
                                  .where((e) => e != 'All')
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCondition,
                              decoration: _inputDecoration(),
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
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedCondition = v),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      /// LOCATION
                      const Text('Location:-'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        decoration: _inputDecoration(hint: 'Enter location'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Location Required'
                            : null,
                      ),

                      const SizedBox(height: 18),

                      /// DESCRIPTION
                      const Text('Description:'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 5,
                        maxLines: 7,
                        decoration: _inputDecoration(
                          hint: 'Write item description...',
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// SUBMIT
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isEditMode ? 'Save Changes' : 'Submit',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            /// LOADING OVERLAY
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }
}
