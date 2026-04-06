import 'package:charms/providers/receipts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddonFuture extends StatefulWidget {
  const AddonFuture({
    super.key,
    required this.hostname,
    required this.confirmnum,
    required this.volres,
  });

  final String hostname;
  final int confirmnum;
  final int volres;

  @override
  State<AddonFuture> createState() => _AddonFutureState();
}

class _AddonFutureState extends State<AddonFuture> {
  late Future<void> _addonFuture;

  @override
  void initState() {
    super.initState();
    _addonFuture = widget.volres == 1
        ? Provider.of<Receipts>(context, listen: false)
            .fetchBookingAddon(widget.hostname, widget.confirmnum)
        : Provider.of<Receipts>(context, listen: false)
            .fetchResAddon(widget.hostname, widget.confirmnum);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _addonFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Consumer<Receipts>(
              builder: (ctx, receiptdata, child) => receiptdata
                      .addons.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: receiptdata.addons.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(receiptdata.addons[i].item),
                        subtitle: Text(
                            'RM ${receiptdata.addons[i].price.toStringAsFixed(2)}'),
                        trailing:
                            Text('Quantity: ${receiptdata.addons[i].quantity}'),
                      ),
                    )
                  : const Text('No Add Ons'),
            );
          }
        }
      },
    );
  }
}
