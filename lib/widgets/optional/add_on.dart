import 'package:charms/models/optionalitem_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/optionalitems.dart';
import 'package:charms/screens/checkout_screen.dart';
import 'package:charms/screens/specialcheckout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';

class AddOn extends StatelessWidget {
  const AddOn({
    super.key,
    required this.hostname,
    required this.confirmnum,
    required this.pax,
    required this.ischecked,
    required this.user,
    required this.eventid,
    required this.booktype,
    this.shirtsize = '',
    required this.staff,
    required this.volres,
    required this.isRSS,
    required this.startdate,
    required this.enddate,
    required this.needboat,
    this.affiliatetitle = '',
    this.department = '',
    this.institution = '',
    this.location = '',
    this.filename = '',
  });

  final String hostname;
  final int confirmnum;
  final int pax;
  final String ischecked;
  final User user;
  final int eventid;
  final int booktype;
  final String shirtsize;
  final bool staff;
  final int volres;
  final int isRSS;
  final String startdate;
  final String enddate;
  final int needboat;
  final String affiliatetitle;
  final String department;
  final String institution;
  final String location;
  final String filename;

  // --- HELPER: Construct Correct Image URL ---
  String _getValidImageUrl(String picturePath) {
    if (picturePath.isEmpty || picturePath == 'none') return '';
    if (picturePath.startsWith('http')) return picturePath;

    String baseUrl = hostname;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.shopping_bag),
              SizedBox(width: 8),
              Text('Buy Add Ons'),
            ],
          ),
          elevation: 0,
        ),
        body: FutureBuilder(
            future: Provider.of<Optionalitems>(context, listen: false)
                .fetchOptionalItemsbyStatus(hostname, 1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.error != null) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  return Consumer<Optionalitems>(
                    builder: (ctx, itemdata, child) {
                      return itemdata.itemlist.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: itemdata.itemlist.length,
                              itemBuilder: (_, i) {
                                final product = itemdata.itemlist[i];
                                final imageUrl = _getValidImageUrl(product.picture);

                                // NEW: Wrap individual item in Cart Consumer
                                return Consumer<OptionalItemCartOut>(
                                  builder: (context, cart, child) {
                                    var cartItem = cart.items.containsKey(product.id.toString())
                                        ? cart.items[product.id.toString()]
                                        : null;
                                    int quantity = cartItem != null ? cartItem.quantity : 0;

                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // --- LEADING IMAGE ---
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Colors.grey.shade100,
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: imageUrl.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, stack) =>
                                                            const Icon(Icons.broken_image, size: 35, color: Colors.grey),
                                                      ),
                                                    )
                                                  : const Icon(Icons.image, size: 35, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 12),
                                            // --- CONTENT ---
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product.desc,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.shade50,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: Colors.green.shade200),
                                                        ),
                                                        child: Text(
                                                          'RM ${product.price.toStringAsFixed(2)}',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: Colors.green.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                      // --- QUANTITY CONTROLS ---
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade50,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Colors.grey.shade300),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            InkWell(
                                                              onTap: quantity > 0
                                                                  ? () {
                                                                      cart.removeSingleItem(product.id.toString());
                                                                    }
                                                                  : null,
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: Container(
                                                                padding: const EdgeInsets.all(6),
                                                                child: Icon(
                                                                  Icons.remove,
                                                                  size: 18,
                                                                  color: quantity > 0 ? Colors.red : Colors.grey,
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              constraints: const BoxConstraints(minWidth: 32),
                                                              alignment: Alignment.center,
                                                              child: Text(
                                                                '$quantity',
                                                                style: const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap: () {
                                                                cart.addItem(
                                                                  '${product.id}',
                                                                  product.name,
                                                                  product.price,
                                                                  1,
                                                                );
                                                                showSimpleNotification(
                                                                  const Text(
                                                                    'Item added',
                                                                    style: TextStyle(color: Colors.white),
                                                                  ),
                                                                  background: Colors.green,
                                                                  duration: const Duration(seconds: 1),
                                                                );
                                                              },
                                                              borderRadius: BorderRadius.circular(8),
                                                              child: Container(
                                                                padding: const EdgeInsets.all(6),
                                                                child: const Icon(
                                                                  Icons.add,
                                                                  size: 18,
                                                                  color: Colors.green,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Add-Ons Available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check back later for optional items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                    },
                  );
                }
              }
            }),
        bottomNavigationBar: Consumer<OptionalItemCartOut>(
          builder: (context, cart, child) {
            final totalAmount = cart.totalAmount.toStringAsFixed(2);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Amount Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${cart.itemCount} item(s)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            'RM $totalAmount',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => isRSS == 0
                  ? Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => CheckoutScreen(
                            confirmnum: confirmnum,
                            hostname: hostname,
                            pax: pax,
                            ischecked: ischecked,
                            user: user,
                            eventid: eventid,
                            booktype: booktype,
                            shirtsize: shirtsize,
                            staff: staff,
                            volres: volres,
                          )))
                  : Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => SpecialCheckoutScreen(
                            hostname: hostname,
                            pax: pax,
                            ischecked: ischecked,
                            user: user,
                            startdate: startdate,
                            enddate: enddate,
                            needboat: needboat,
                            affiliatetitle: affiliatetitle,
                            department: department,
                            institution: institution,
                            location: location,
                            filename: filename,
                          ))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}