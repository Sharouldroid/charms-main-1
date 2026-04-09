import 'package:charms/models/groupmembers.dart';
import 'package:charms/models/specialbooking_cart.dart';
import 'package:charms/widgets/cart/checkout_members.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CheckoutItemSpecial extends StatefulWidget {
  final String id;
  final String eventname;
  final int price;
  final int pax;
  final String indemnities;
  final int eventprice;
  final int boatprice;
  final String startdate;
  final String enddate;

  const CheckoutItemSpecial({
    super.key,
    required this.id,
    required this.eventname,
    required this.price,
    required this.pax,
    required this.indemnities,
    required this.eventprice,
    required this.boatprice,
    required this.startdate,
    required this.enddate,
  });

  @override
  State<CheckoutItemSpecial> createState() => _CheckoutItemSpecialState();
}

class _CheckoutItemSpecialState extends State<CheckoutItemSpecial> {
  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    final cartG = Provider.of<GroupMembersOut>(context, listen: false);
    final int days = DateTime.parse(widget.enddate)
        .difference(DateTime.parse(widget.startdate))
        .inDays;

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
          Provider.of<SpecialBookingCartOut>(context, listen: false)
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
                    'Applied Date: ${f.format(DateTime.parse(widget.startdate))} - ${f.format(DateTime.parse(widget.enddate))}'),
                trailing: Text(
                  'RM${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
                children: [
                  Text('Total Pax: ${widget.pax}'),
                  Text('Total Days: $days days'),
                  Text(
                      'Price Per Pax: RM ${(widget.eventprice / widget.pax).toStringAsFixed(2)}'),
                  Text(
                      'Boat Charge Per Pax: RM ${(widget.boatprice / widget.pax).toStringAsFixed(2)}'),
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
