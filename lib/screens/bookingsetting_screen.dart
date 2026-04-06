// import 'package:charms/models/bookingsetting.dart';
import 'package:charms/providers/bookingsettings.dart';
import 'package:charms/widgets/settings/create_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/responsive_helper.dart';

class BookingSettingScreen extends StatelessWidget {
  const BookingSettingScreen({
    super.key,
    required this.hostname,
    required this.settingtype,
  });

  final String hostname;
  final int settingtype;

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Settings'),
        // actions: [
        //   IconButton(
        //       onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        //           builder: (ctx) => CreateItem(
        //                 hostname: hostname,
        //                 settingdata: Bookingsetting(
        //                     id: 0, item: '', price: 0, itemtype: settingtype),
        //                 settingdataid: 0,
        //               ))),
        //       icon: const Icon(Icons.add)),
        // ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FutureBuilder(
        future: Provider.of<BookingSettings>(context, listen: false)
            .fetchSettingbytype(hostname, settingtype, 1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.error != null) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return Consumer<BookingSettings>(
                  builder: (ctx, itemdata, child) => ListView.builder(
                      shrinkWrap: true,
                      itemCount: itemdata.itemlist.length,
                      itemBuilder: (_, i) => ListTile(
                            title: Text(itemdata.itemlist[i].item),
                            subtitle: Text('RM ${itemdata.itemlist[i].price}'),
                            trailing: IconButton(
                                onPressed: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (ctx) => CreateItem(
                                              hostname: hostname,
                                              settingdata: itemdata.itemlist[i],
                                              settingdataid:
                                                  itemdata.itemlist[i].id,
                                            ))),
                                icon: const Icon(Icons.edit)),
                          )));
            }
          }
        },
      ),
        ),
      ),
    );
  }
}
