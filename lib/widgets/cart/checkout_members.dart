import 'package:charms/models/groupmembers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutMembers extends StatefulWidget {
  final String id;
  final String name;
  final String email;
  final String idnum;
  final String shirtsize;
  final int ischild;

  const CheckoutMembers({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.idnum,
    required this.shirtsize,
    required this.ischild,
  });

  @override
  State<CheckoutMembers> createState() => _CheckoutMembersState();
}

class _CheckoutMembersState extends State<CheckoutMembers> {
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
          Provider.of<GroupMembersOut>(context, listen: false)
              .removeItem(widget.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  widget.name,
                  style: const TextStyle(fontSize: 20),
                  maxLines: 3,
                ),
                subtitle: Text(
                  'Email: ${widget.email}',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: widget.shirtsize.isNotEmpty
                    ? Text(
                        'T-shirt Size:${widget.shirtsize}',
                        style: const TextStyle(fontSize: 18),
                      )
                    : null,
              )
            ],
          ),
        ),
      ),
    );
  }
}
