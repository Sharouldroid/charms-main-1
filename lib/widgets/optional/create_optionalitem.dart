import 'dart:typed_data';
import 'package:charms/models/optionalitem.dart';
import 'package:charms/providers/optionalitems.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreateOptionalItem extends StatefulWidget {
  const CreateOptionalItem({
    super.key,
    required this.userid,
    required this.hostname,
    required this.item,
    required this.itemid,
    this.index = 0,
  });

  final int userid;
  final String hostname;
  final List<Optionalitem> item;
  final int itemid;
  final int index;

  @override
  State<CreateOptionalItem> createState() => _CreateOptionalItemState();
}

class _CreateOptionalItemState extends State<CreateOptionalItem> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;

  var _newItem = const Optionalitem(
    id: 0,
    name: '',
    desc: '',
    price: 0,
    status: 1,
    picture: '',
  );

  var _initValues = {
    'id': '',
    'name': '',
    'desc': '',
    'price': '',
    'status': '',
    'picture': '',
  };

  var _isLoading = false;
  var _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.itemid != 0 && widget.item.isNotEmpty) {
        if (widget.index < widget.item.length) {
          final currentItem = widget.item[widget.index];
          _initValues = {
            'id': currentItem.id.toString(),
            'name': currentItem.name,
            'desc': currentItem.desc,
            'price': currentItem.price.toString(),
            'status': currentItem.status.toString(),
            'picture': currentItem.picture,
          };
          _existingImageUrl = currentItem.picture;
          
          _newItem = Optionalitem(
            id: currentItem.id,
            name: currentItem.name,
            desc: currentItem.desc,
            price: currentItem.price,
            picture: currentItem.picture,
            status: currentItem.status,
          );
        }
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // --- FIXED: Image URL Logic for Edit Screen ---
  String _constructImageUrl(String picturePath) {
    if (picturePath.isEmpty || picturePath == 'none') return '';
    if (picturePath.startsWith('http')) return picturePath;

    String baseUrl = widget.hostname;
    if (baseUrl.endsWith('api/')) {
      baseUrl = baseUrl.replaceAll('api/', '');
    } else if (baseUrl.endsWith('api')) {
      baseUrl = baseUrl.replaceAll('api', '');
    }

    if (!baseUrl.endsWith('/')) {
      baseUrl = '$baseUrl/';
    }

    if (!baseUrl.endsWith('public/')) {
      baseUrl = '${baseUrl}public/';
    }

    String cleanPath = picturePath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    return '$baseUrl$cleanPath';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedImage = pickedFile;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _showErrorDialog(String message, int type) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 1 ? 'Warning' : 'Message'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });

    try {
      String finalPicturePath = _newItem.picture;
      
      if (_pickedImage != null) {
        final uploadedPath = await Provider.of<Optionalitems>(context, listen: false)
            .uploadImage(widget.hostname, _pickedImage!);
        
        if (uploadedPath != null) {
          finalPicturePath = uploadedPath;
        }
      } else {
        // Keep old picture if no new one selected
        if (widget.itemid != 0 && finalPicturePath.isEmpty) {
             finalPicturePath = _initValues['picture'] ?? '';
        }
      }

      final itemToSave = Optionalitem(
        id: _newItem.id,
        name: _newItem.name,
        desc: _newItem.desc,
        price: _newItem.price,
        status: _newItem.status,
        picture: finalPicturePath,
      );

      if (widget.itemid == 0) {
        await Provider.of<Optionalitems>(context, listen: false)
            .createOptionalItem(widget.hostname, itemToSave, widget.userid);
      } else {
        await Provider.of<Optionalitems>(context, listen: false)
            .updateOptionalItem(
          widget.hostname,
          itemToSave,
          widget.itemid,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    } catch (error) {
      await _showErrorDialog(error.toString(), 1);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.itemid == 0 ? Icons.add_box : Icons.edit_note,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(widget.itemid == 0 ? 'Create New Add-On' : 'Edit Add-On'),
          ],
        ),
        centerTitle: false,
        elevation: 2,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Image',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select an image from your gallery',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _pickedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    _pickedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty && _existingImageUrl != 'none')
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        _constructImageUrl(_existingImageUrl!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (ctx, err, stack) => Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 60, color: Colors.grey.shade400),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Image not found',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tap to add image',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recommended: 800x800px',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    initialValue: _initValues['name'],
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'e.g., T-Shirt, Cap, Water Bottle',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter item name' : null,
                    onSaved: (value) {
                      _newItem = Optionalitem(
                        id: _newItem.id,
                        name: value!,
                        desc: _newItem.desc,
                        price: _newItem.price,
                        picture: _newItem.picture,
                        status: _newItem.status,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _initValues['desc'],
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the item details...',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    maxLines: 4,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter item description' : null,
                    onSaved: (value) {
                      _newItem = Optionalitem(
                        id: _newItem.id,
                        name: _newItem.name,
                        desc: value!,
                        price: _newItem.price,
                        picture: _newItem.picture,
                        status: _newItem.status,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _initValues['price'],
                    decoration: InputDecoration(
                      labelText: 'Price (RM)',
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      prefixText: 'RM ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter item price';
                      if (int.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                    onSaved: (value) {
                      _newItem = Optionalitem(
                        id: _newItem.id,
                        name: _newItem.name,
                        desc: _newItem.desc,
                        price: int.parse(value!),
                        picture: _newItem.picture,
                        status: _newItem.status,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        widget.itemid == 0 ? Icons.save : Icons.update,
                        size: 22,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      label: Text(
                        widget.itemid == 0 ? 'Create Item' : 'Update Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
    );
  }
}