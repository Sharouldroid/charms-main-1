import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/optionalitems.dart';
import 'package:charms/widgets/optional/create_optionalitem.dart';
import 'package:charms/models/optionalitem.dart';

class ManageOptionalitemScreen extends StatelessWidget {
  const ManageOptionalitemScreen({
    super.key,
    required this.userid,
    required this.hostname,
  });

  final int userid;
  final String hostname;

  Future<void> _refreshItems(BuildContext context) async {
    await Provider.of<Optionalitems>(context, listen: false)
        .fetchAllOptionalItems(hostname);
  }

  // --- FIXED: Construct Correct Image URL with 'public' ---
  String _getValidImageUrl(String picturePath) {
    if (picturePath.isEmpty || picturePath == 'none') return '';
    if (picturePath.startsWith('http')) return picturePath;

    // 1. Get base URL (remove 'api/')
    // Ex: https://devcms.com.my/charmsAPI/api/ -> https://devcms.com.my/charmsAPI/
    String baseUrl = hostname;
    if (baseUrl.endsWith('api/')) {
      baseUrl = baseUrl.replaceAll('api/', ''); 
    } else if (baseUrl.endsWith('api')) {
      baseUrl = baseUrl.replaceAll('api', '');
    }

    // 2. Ensure base ends with /
    if (!baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    // 3. Add 'public/' if your server requires it (based on your URL)
    if (!baseUrl.endsWith('public/')) {
      baseUrl = '${baseUrl}public/';
    }

    // 4. Clean picture path (remove leading /)
    String cleanPath = picturePath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // 5. Combine
    // Result: https://devcms.com.my/charmsAPI/public/uploads/addon/filename.jpg
    return '$baseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.inventory_2, size: 24),
            SizedBox(width: 8),
            Text('Manage Add-Ons'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _navigateToCreateItem(context),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshItems(context),
        child: FutureBuilder(
          future: _refreshItems(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(context, snapshot.error.toString());
            }

            return Consumer<Optionalitems>(
              builder: (ctx, itemdata, child) {
                if (itemdata.itemlist.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildItemList(context, itemdata);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _refreshItems(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'No Add-Ons Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first optional item to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text('Create First Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _navigateToCreateItem(context),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, Optionalitems itemdata) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: itemdata.itemlist.length,
      itemBuilder: (_, index) => _buildItemTile(context, itemdata, index),
    );
  }

  Widget _buildItemTile(BuildContext context, Optionalitems itemdata, int index) {
    final item = itemdata.itemlist[index];
    final imageUrl = _getValidImageUrl(item.picture);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.status == 1 ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      color: item.status == 1 ? null : Colors.grey.shade50,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: (imageUrl.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, loading) {
                      if (loading == null) return child;
                      return const Center(
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      );
                    },
                    errorBuilder: (ctx, err, stack) {
                      print('Failed to load image: $imageUrl'); // Debug
                      return const Icon(Icons.broken_image, size: 24, color: Colors.grey);
                    },
                  ),
                )
              : const Icon(Icons.image, color: Colors.grey, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  decoration: item.status == 1 ? null : TextDecoration.lineThrough,
                  color: item.status == 1 ? null : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (item.status == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Inactive',
                  style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            'RM ${item.price}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 14,
            ),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _navigateToEditItem(context, itemdata, index),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: Icon(
                    item.status == 1 ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(item.status == 1 ? 'Deactivate' : 'Activate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: item.status == 1 ? Colors.orange : Colors.green,
                    side: BorderSide(
                      color: item.status == 1 ? Colors.orange : Colors.green,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final newStatus = item.status == 1 ? 0 : 1;
                    final updatedItem = Optionalitem(
                      id: item.id,
                      name: item.name,
                      desc: item.desc,
                      price: item.price,
                      picture: item.picture,
                      status: newStatus,
                    );

                    try {
                      await Provider.of<Optionalitems>(context, listen: false)
                          .updateOptionalItem(hostname, updatedItem, item.id);
                      
                      if (context.mounted) {
                        _refreshItems(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newStatus == 1 ? 'Item Activated' : 'Item Deactivated'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreateItem(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CreateOptionalItem(
          userid: userid,
          hostname: hostname,
          item: const [],
          itemid: 0,
        ),
      ),
    );
    if (context.mounted) {
      _refreshItems(context);
    }
  }

  Future<void> _navigateToEditItem(BuildContext context, Optionalitems itemdata, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CreateOptionalItem(
          userid: userid,
          hostname: hostname,
          item: itemdata.itemlist,
          itemid: itemdata.itemlist[index].id,
          index: index,
        ),
      ),
    );
    if (context.mounted) {
      _refreshItems(context);
    }
  }
}