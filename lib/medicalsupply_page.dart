import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class MedicalSupplyPage extends StatefulWidget {
  const MedicalSupplyPage({super.key});

  @override
  State<MedicalSupplyPage> createState() => _MedicalSupplyPageState();
}

class _MedicalSupplyPageState extends State<MedicalSupplyPage> {
  List<MedicalItem> _medicalSupplies = [];
  final List<String> _categories = ['All', 'Wound Care', 'Medication', 'Specialized', 'Equipment'];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  final String apiUrl = 'https://devcms.com.my/charmsAPI/api/medical-supplies';

  @override
  void initState() {
    super.initState();
    fetchSupplies();
  }

  Future<void> fetchSupplies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final items = data.map((e) => MedicalItem.fromJson(e)).toList();
        setState(() {
          _medicalSupplies = items.cast<MedicalItem>();
        });
      } else {
        setState(() => _errorMessage = '❌ Failed to load data (status ${response.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = '❌ Error fetching data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addOrUpdateItem(MedicalItem item) async {
    final isUpdate = item.id != null;
    final url = isUpdate ? '$apiUrl/${item.id}' : apiUrl;
    final uri = Uri.parse(url);

    final bodyData = {
      if (item.id != null) 'id': item.id,
      'name': item.name,
      'quantity': item.quantity,
      'category': item.category,
      'threshold': item.threshold,
      'last_restocked': item.lastRestocked.toIso8601String(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          showMessage('✅ Item ${isUpdate ? "updated" : "added"} successfully');
          await fetchSupplies();
          Navigator.pop(context);
        } else {
          showMessage('⚠️ Failed to save item: ${result['message'] ?? 'Unknown error'}');
        }
      } else {
        showMessage('❌ Error saving item (status ${response.statusCode})');
      }
    } catch (e) {
      Navigator.pop(context);
      showMessage('❌ Network error: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 200) {
      showMessage('🗑️ Item deleted');
      fetchSupplies();
    } else {
      showMessage('❌ Failed to delete item');
    }
  }

  Future<void> _saveReport() async {
    const reportUrl = 'https://devcms.com.my/charmsAPI/api/medical-supplies/report';

    try {
      final response = await http.get(Uri.parse(reportUrl));
      if (response.statusCode == 200) {
        final dir = Directory('/storage/emulated/0/Download');
        final filePath =
            '${dir.path}/medical_supplies_report_${DateTime.now().millisecondsSinceEpoch}.html';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Report saved to: $filePath')),
          );
        }
      } else {
        showMessage('❌ Failed: ${response.body}');
      }
    } catch (e) {
      showMessage('⚠️ Error: $e');
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showItemDialog({MedicalItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '1');
    final thresholdController = TextEditingController(text: item?.threshold.toString() ?? '1');
    String selectedCategory = item?.category ?? _categories[1];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item == null ? '➕ Add Item' : '✏️ Edit Item',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: _categories
                    .where((c) => c != 'All')
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Threshold',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF05179),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newItem = MedicalItem(
                id: item?.id,
                name: nameController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? 1,
                category: selectedCategory,
                threshold: int.tryParse(thresholdController.text) ?? 1,
                lastRestocked: DateTime.now(),
              );
              addOrUpdateItem(newItem);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _medicalSupplies
        : _medicalSupplies.where((i) => i.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
appBar: AppBar(
  backgroundColor: const Color(0xFFF05179),
  foregroundColor: Colors.white,
  centerTitle: false, // ✅ align left, full width
  title: const Text(
    '🩺 Medical Supplies',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  actions: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF05179),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _saveReport,
        icon: const Icon(Icons.file_download, size: 16),
        label: const Text("Report"),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.add_circle, size: 28),
      tooltip: 'Add Item',
      onPressed: () => _showItemDialog(),
    ),
  ],
),

      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              children: _categories.map((c) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    selectedColor: const Color(0xFFF05179),
                    labelStyle: TextStyle(
                        color: _selectedCategory == c ? Colors.white : Colors.black87),
                    onSelected: (_) async {
                      setState(() {
                        _selectedCategory = c;
                        _isLoading = true;
                      });
                      await Future.delayed(const Duration(milliseconds: 400));
                      setState(() => _isLoading = false);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('📭 No items found for this category',
                                style: TextStyle(fontSize: 16)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  title: Text(item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Text(
                                    'Qty: ${item.quantity}   •   Min: ${item.threshold}',
                                    style: TextStyle(
                                        color: item.quantity <= item.threshold
                                            ? Colors.red
                                            : Colors.grey[700]),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showItemDialog(item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteItem(item.id!),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          )
        ],
      ),
    );
  }
}

class MedicalItem {
  final String? id;
  final String name;
  final int quantity;
  final String category;
  final DateTime lastRestocked;
  final int threshold;

  MedicalItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.category,
    required this.lastRestocked,
    required this.threshold,
  });

  factory MedicalItem.fromJson(Map<String, dynamic> json) {
    return MedicalItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      category: json['category'] ?? '',
      lastRestocked: DateTime.tryParse(json['last_restocked'] ?? '') ?? DateTime.now(),
      threshold: int.tryParse(json['threshold'].toString()) ?? 0,
    );
  }
}
