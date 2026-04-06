import 'package:charms/models/booking_cart.dart';
import 'package:charms/models/groupmembers.dart';
import 'package:charms/utils/responsive_helper.dart';
import 'package:charms/widgets/cart/checkout_members.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutItem extends StatefulWidget {
  final String id;
  final String eventname;
  final double price;
  final int confirmnum;
  final int userid;
  final int pax;
  final int booktype;
  // final List<int> indemnities;
  final String indemnities;
  final String shirtsize;

  const CheckoutItem({
    super.key,
    required this.id,
    required this.eventname,
    required this.price,
    required this.confirmnum,
    required this.userid,
    required this.pax,
    required this.booktype,
    required this.indemnities,
    required this.shirtsize,
  });

  @override
  State<CheckoutItem> createState() => _CheckoutItemState();
}

class _CheckoutItemState extends State<CheckoutItem> {
  @override
  Widget build(BuildContext context) {
    final cartG = Provider.of<GroupMembersOut>(context, listen: false);

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
          Provider.of<BookingCartOut>(context, listen: false)
              .removeItem(widget.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            shrinkWrap: true,
            children: [
              ExpansionTile(
                title: Text(
                  widget.eventname,
                  style: const TextStyle(fontSize: 20),
                  maxLines: 3,
                ),
                subtitle: Text(
                  widget.booktype == 1 ? 'Individual Booking' : 'Group Booking',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: Text(
                  'RM${(widget.price * widget.pax).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
                children: [
                  widget.shirtsize != ''
                      ? Text('T-Shirt Size: ${widget.shirtsize}')
                      : const SizedBox.shrink(),
                  const SizedBox(height: 20),
                  widget.booktype != 1
                      ? Text(
                          widget.booktype == 2
                              ? 'Group Members'
                              : widget.booktype == 3
                                  ? 'Children'
                                  : '',
                          style: const TextStyle(fontSize: 20),
                        )
                      : const Text(''),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartG.itemCount,
                    itemBuilder: (_, i) => CheckoutMembers(
                      id: cartG.items.keys.toList()[i],
                      name: cartG.items.values.toList()[i].name,
                      email: cartG.items.values.toList()[i].email,
                      idnum: cartG.items.values.toList()[i].id,
                      shirtsize: cartG.items.values.toList()[i].shirtsize,
                      ischild: cartG.items.values.toList()[i].ischild,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
