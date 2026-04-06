import 'package:charms/providers/optionalitems.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PurchasedItems extends StatelessWidget {
  const PurchasedItems({
    super.key,
    required this.hostname,
    required this.confirmnum,
  });

  final String hostname;
  final int confirmnum;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<Optionalitems>(context, listen: false)
          .fetchPurchasedItems(hostname, confirmnum),
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
                builder: (ctx, itemData, child) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemData.purchaseditem.length,
                    itemBuilder: (_, i) => itemData.purchaseditem.isNotEmpty
                        ? ListTile(
                            title: Text(itemData.purchaseditem[i].name),
                            trailing: Text(
                                'Price: RM ${itemData.purchaseditem[i].price}'),
                            subtitle: Text(
                                'Quantity: ${itemData.purchaseditem[i].quantity}'),
                          )
                        : const Text('No Add Ons')));
          }
        }
      },
    );
  }
}
