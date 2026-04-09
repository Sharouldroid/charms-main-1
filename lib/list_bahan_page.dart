import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ListBahanPage extends StatefulWidget {
  const ListBahanPage({super.key});

  @override
  State<ListBahanPage> createState() => _ListBahanPageState();
}

class _ListBahanPageState extends State<ListBahanPage> {
  List<BahanItem> bahanList = [];
  String searchQuery = "";
  bool isSaving = false;
  String selectedProgram = "4D3N";

  @override
  void initState() {
    super.initState();
    loadIngredients();
  }

  /// LOAD INGREDIENT
  void loadIngredients() {
    bahanList = [
      /// SAYUR
      BahanItem(name: "Tomato", category: "Sayur", baseQty: 5),
      BahanItem(name: "Carrot", category: "Sayur", baseQty: 4),
      BahanItem(name: "Timun Batang", category: "Sayur", baseQty: 4),
      BahanItem(name: "Bunga Kubis", category: "Sayur", baseQty: 2),
      BahanItem(name: "Kentang", category: "Sayur", baseQty: 6),

      /// BASAH
      BahanItem(name: "Ayam", category: "Makanan Basah", baseQty: 5),
      BahanItem(name: "Daging", category: "Makanan Basah", baseQty: 4),
      BahanItem(name: "Telur", category: "Makanan Basah", baseQty: 20),

      /// KERING
      BahanItem(name: "Beras", category: "Makanan Kering", baseQty: 3),
      BahanItem(name: "Maggi Kari", category: "Makanan Kering", baseQty: 10),
      BahanItem(name: "Bihun", category: "Makanan Kering", baseQty: 5),

      /// MINUMAN
      BahanItem(name: "Milo", category: "Minuman", baseQty: 2),
      BahanItem(name: "Teh Uncang", category: "Minuman", baseQty: 1),
      BahanItem(name: "Nescafe", category: "Minuman", baseQty: 1),

      /// PERASA
      BahanItem(name: "Gula", category: "Perasa", baseQty: 1),
      BahanItem(name: "Garam", category: "Perasa", baseQty: 1),
      BahanItem(name: "Kicap Masin", category: "Perasa", baseQty: 1),
    ];
    autoCalculate();
  }

  /// AUTO CALCULATE PROGRAM
  void autoCalculate() {
    int multiplier = selectedProgram == "5D4N" ? 2 : 1;
    for (var item in bahanList) {
      item.quantity = item.baseQty * multiplier;
    }
    setState(() {});
  }

  /// GROUP BY CATEGORY
  Map<String, List<BahanItem>> groupByCategory() {
    Map<String, List<BahanItem>> grouped = {};
    for (var item in bahanList) {
      if (searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        continue;
      }
      grouped.putIfAbsent(item.category, () => []);
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  /// TOTAL ITEMS SELECTED
  int totalSelected() {
    int total = 0;
    for (var item in bahanList) {
      if (item.isChecked) {
        total += item.quantity;
      }
    }
    return total;
  }

  /// SAVE DATABASE
  Future saveData() async {
    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse("https://devcms.com.my/charmsAPI/api/save-bahan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bahanList.map((e) => e.toJson()).toList()),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Checklist saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error saving data"),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => isSaving = false);
  }

  /// EXPORT PDF
  Future exportPDF() async {
    final pdf = pw.Document();
    List<BahanItem> selected = bahanList.where((e) => e.isChecked).toList();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Grocery List ($selectedProgram)",
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              ...selected.map(
                (e) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.name),
                    pw.Text(e.quantity.toString()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// QUANTITY STEPPER
  Widget quantityStepper(BahanItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            setState(() {
              if (item.quantity > 0) item.quantity--;
            });
          },
        ),
        Text(
          item.quantity.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            setState(() {
              item.quantity++;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingredients Checklist"),
        backgroundColor: const Color(0xFFF05179), // requested color
        foregroundColor: Colors.white, // white text/icons
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          /// PROGRAM SELECT
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButtonFormField(
              initialValue: selectedProgram,
              items: const [
                DropdownMenuItem(value: "4D3N", child: Text("4D3N Program")),
                DropdownMenuItem(value: "5D4N", child: Text("5D4N Program")),
              ],
              onChanged: (v) {
                selectedProgram = v!;
                autoCalculate();
              },
              decoration: const InputDecoration(
                labelText: "Program Duration",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search ingredient...",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  searchQuery = v;
                });
              },
            ),
          ),

          /// TOTAL ITEMS
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Total Items Selected: ${totalSelected()}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          Expanded(
            child: ListView(
              children: grouped.keys.map((category) {
                final items = grouped[category]!;
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: items.map((item) {
                      return ListTile(
                        leading: Checkbox(
                          value: item.isChecked,
                          onChanged: (v) {
                            setState(() {
                              item.isChecked = v!;
                            });
                          },
                        ),
                        title: Text(item.name),
                        trailing: quantityStepper(item),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15),
        child: ElevatedButton.icon(
          icon: isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.save),
          label: Text(isSaving ? "Saving..." : "Save Checklist"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white, // ensures white text
          ),
          onPressed: isSaving ? null : saveData,
        ),
      ),
    );
  }
}

class BahanItem {
  String name;
  String category;
  int quantity;
  int baseQty;
  bool isChecked;

  BahanItem({
    required this.name,
    required this.category,
    this.quantity = 0,
    this.baseQty = 1,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "category": category,
      "quantity": quantity,
      "checked": isChecked,
    };
  }
}