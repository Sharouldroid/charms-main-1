import 'package:charms/models/optionalitem_cart.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutAddon extends StatefulWidget {
  final String id;
  final String itemname;
  final int price;
  final int quantity;

  const CheckoutAddon({
    super.key,
    required this.id,
    required this.itemname,
    required this.price,
    required this.quantity,
  });

  @override
  State<CheckoutAddon> createState() => _CheckoutAddonState();
}

class _CheckoutAddonState extends State<CheckoutAddon> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Dismissible(
        key: ValueKey(widget.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 4,
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 40,
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          Provider.of<OptionalItemCartOut>(context, listen: false)
              .removeItem(widget.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  widget.itemname,
                  style: const TextStyle(fontSize: 20),
                  maxLines: 3,
                ),
                subtitle: Text(
                  'Qty: ${widget.quantity}',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: Text(
                  'RM${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
