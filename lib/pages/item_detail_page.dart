import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_form_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String currentUser;
  final void Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onDelete;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.index,
    required this.currentUser,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late Map<String, dynamic> item;
  bool isFavorite = false;

  // support multiple images
  late List<String> images;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    item = Map<String, dynamic>.from(widget.item);
    isFavorite = item['favorite'] == true;

    // initialize images list: prefer `images` field, fallback to single `image`
    final rawImages = item['images'];
    if (rawImages is List) {
      images = rawImages.whereType<String>().toList();
    } else {
      final single = item['image'] as String?;
      images = single != null && single.isNotEmpty ? [single] : <String>[];
    }
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _editItem() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormPage(
          categories: const ['All', 'Electronics', 'Appliances', 'Tools'],
          existingItem: item,
        ),
      ),
    );
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        item = Map<String, dynamic>.from(res);
        isFavorite = item['favorite'] == true;
        final rawImages = item['images'];
        if (rawImages is List) {
          images = rawImages.whereType<String>().toList();
        } else {
          final single = item['image'] as String?;
          images = single != null && single.isNotEmpty ? [single] : <String>[];
        }
      });
      widget.onUpdate(item);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // notify parent / data store
      widget.onDelete();

      // close detail page and return a signal (optional) so previous screen can refresh
      // pop the detail page (dialog already closed)
      Navigator.pop(context, true);
    }
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      item['favorite'] = isFavorite;
    });
    widget.onUpdate(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
      ),
    );
  }

  void _shareItem() {
    // minimal placeholder for share. Replace with share package if desired.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share link: ${item['name'] ?? 'item'}')),
    );
  }

  void _openImagePreview(String path) {
    final f = File(path);
    if (!f.existsSync()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black),
          backgroundColor: Colors.black,
          body: Center(child: InteractiveViewer(child: Image.file(f))),
        ),
      ),
    );
  }

  // ===========================================
  // UPDATED INFO CARD (supports both Icon & SVG)
  // ===========================================
  Widget _infoCard(
    dynamic icon, // <--- changed from IconData to dynamic
    String title,
    String subtitle, {
    Color? color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // If IconData → show Icon
            // If Widget (SVG) → show directly
            icon is IconData
                ? Icon(icon, color: color ?? Theme.of(context).primaryColor)
                : icon,

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),

            const SizedBox(height: 6),

            Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = item['owner'] == widget.currentUser;

    // determine if image files exist
    final validImages = images
        .where((p) => p.isNotEmpty && File(p).existsSync())
        .toList();
    final hasImages = validImages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? 'Item'),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareItem),
          if (isOwner)
            IconButton(icon: const Icon(Icons.edit), onPressed: _editItem),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      // wrap with SafeArea to avoid bottom overflow and respect system insets
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            // Image carousel / single image area (constrained to avoid overflow)
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (hasImages)
                      PageView.builder(
                        controller: _pageController,
                        itemCount: validImages.length,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                        itemBuilder: (ctx, i) {
                          final imgPath = validImages[i];
                          return Hero(
                            tag:
                                'item_image_${widget.index}_${item['name']}_$i',
                            child: InkWell(
                              onTap: () => _openImagePreview(imgPath),
                              child: Image.file(
                                File(imgPath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No image available',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                    // page indicator (no owner-only local-path controls)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          validImages.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: _currentPage == i ? 10 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? Colors.white
                                  : Colors.white70,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // thumbnails row (if images exist) - no local-path remove control
            if (hasImages)
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: validImages.length,
                  itemBuilder: (ctx, i) {
                    final p = validImages[i];
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 72,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: i == _currentPage
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(p)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (hasImages) const SizedBox(height: 12),

            // Title card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['subtitle'] ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      backgroundColor: const Color(0xFFE3F2FD),
                      label: Text(
                        item['status'] ?? 'Available',
                        style: const TextStyle(color: Color(0xFF1E88E5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Individual small cards: use Wrap so they flow on small screens instead of overflowing
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _infoCard(
                    Icons.category,
                    'Category',
                    item['category'] ?? 'N/A',
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _infoCard(
                    SvgPicture.asset(
                      'assets/icons/nepali_rupee_filled.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.green,
                        BlendMode.srcIn,
                      ),
                    ),
                    'Price',
                    'Rs ${item['price'] ?? '0'}',
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _infoCard(
                    Icons.person,
                    'Owner',
                    item['owner'] ?? 'Unknown',
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _infoCard(
                    Icons.app_settings_alt,
                    'Condition',
                    item['condition'] ?? 'Good',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(item['description'] ?? 'No description provided.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Action buttons: responsive layout to avoid overflow on small screens
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 420;
                if (narrow) {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: isOwner
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Book Item'),
                                    content: Text(
                                      'Request booking for "${item['name']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Booking requested',
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Request'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          isOwner ? 'Cannot book your own item' : 'Book Item',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOwner
                              ? Colors.grey
                              : const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isOwner
                            ? _editItem
                            : () {
                                final owner = item['owner'] ?? 'Owner';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Contacted $owner (placeholder)',
                                    ),
                                  ),
                                );
                              },
                        icon: Icon(isOwner ? Icons.edit : Icons.message),
                        label: Text(isOwner ? 'Edit' : 'Contact Owner'),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isOwner
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Book Item'),
                                      content: Text(
                                        'Request booking for "${item['name']}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Booking requested',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Request'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.shopping_cart),
                          label: Text(
                            isOwner ? 'Cannot book your own item' : 'Book Item',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOwner
                                ? Colors.grey
                                : const Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isOwner
                              ? _editItem
                              : () {
                                  final owner = item['owner'] ?? 'Owner';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Contacted $owner (placeholder)',
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(isOwner ? Icons.edit : Icons.message),
                          label: Text(isOwner ? 'Edit' : 'Contact Owner'),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
