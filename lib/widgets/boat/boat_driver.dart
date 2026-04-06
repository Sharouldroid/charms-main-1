import 'package:charms/providers/boats.dart';
import 'package:charms/widgets/boat/add_driver.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BoatDriver extends StatelessWidget {
  const BoatDriver({
    super.key,
    required this.hostname,
    required this.companyid,
  });

  final String hostname;
  final int companyid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemandu Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => AddDriver(
                      hostname: hostname,
                      driverdata: const [],
                      companyid: companyid,
                      driverid: 0,
                    ))),
          ),
        ],
      ),
      body: FutureBuilder(
          future: Provider.of<Boats>(context, listen: false)
              .fetchBoatDriver(hostname, companyid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              if (snapshot.error != null) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                return Consumer<Boats>(
                  builder: (ctx, driverData, child) {
                    return driverData.driverRecord.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            itemCount: driverData.driverRecord.length,
                            itemBuilder: (_, i) => ExpansionTile(
                              title: Text(driverData.driverRecord[i].fullname),
                              subtitle: Text(driverData.driverRecord[i].phone),
                              trailing: IconButton(
                                  onPressed: () => Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (ctx) => AddDriver(
                                            hostname: hostname,
                                            driverdata: driverData.driverRecord,
                                            companyid: companyid,
                                            driverid:
                                                driverData.driverRecord[i].id),
                                      )),
                                  icon: const Icon(Icons.edit)),
                              children: [
                                // ListTile(
                                //     title: Text(
                                //         'Pemandu: ${driverData.driverRecord[i].driver}'),
                                //     subtitle: Text(
                                //         'Telefon: ${driverData.driverRecord[i].driverphone}')),
                                // ListTile(
                                //     title: Text(
                                //         'Pembantu Pemandu: ${driverData.driverRecord[i].codriver}'),
                                //     subtitle: Text(
                                //         'Telefon: ${driverData.driverRecord[i].codriverphone}')),
                                // IconButton(
                                //     onPressed: () {},
                                //     icon: const Icon(Icons.toggle_off))
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Tiada Rekod Pemandu'),
                                TextButton.icon(
                                  label: const Text('Tambah'),
                                  onPressed: () => Navigator.of(context)
                                      .push(MaterialPageRoute(
                                    builder: (ctx) => AddDriver(
                                      hostname: hostname,
                                      driverdata: const [],
                                      companyid: companyid,
                                      driverid: 0,
                                    ),
                                  )),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          );
                  },
                );
              }
            }
          }),
    );
  }
}
