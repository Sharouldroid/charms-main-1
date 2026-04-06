import 'package:charms/providers/boats.dart';
import 'package:charms/widgets/boat/add_boat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BoatManagement extends StatelessWidget {
  const BoatManagement({
    super.key,
    required this.hostname,
    required this.companyid,
    required this.userid,
  });

  final String hostname;
  final int companyid;
  final int userid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Provider.of<Boats>(context, listen: false)
            .fetchBoatData(hostname, companyid),
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
                builder: (ctx, boatData, child) {
                  return boatData.boatRecord.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: boatData.boatRecord.length,
                          itemBuilder: (_, i) => ExpansionTile(
                            title: Text(
                                '${boatData.boatRecord[i].name} (${boatData.boatRecord[i].capacity} pax)'),
                            subtitle: Text(boatData.boatRecord[i].status == 1
                                ? 'Aktif'
                                : 'Tidak Aktif'),
                            trailing: IconButton(
                                onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (ctx) => AddBoat(
                                        boatid: boatData.boatRecord[i].id,
                                        hostname: hostname,
                                        boatdata: boatData.boatRecord,
                                        companyid: companyid,
                                        index: i,
                                      ),
                                    )),
                                icon: const Icon(Icons.edit)),
                            children: [
                              // ListTile(
                              //     title: Text(
                              //         'Pemandu: ${boatData.boatRecord[i].driver}'),
                              //     subtitle: Text(
                              //         'Telefon: ${boatData.boatRecord[i].driverphone}')),
                              // ListTile(
                              //     title: Text(
                              //         'Pembantu Pemandu: ${boatData.boatRecord[i].codriver}'),
                              //     subtitle: Text(
                              //         'Telefon: ${boatData.boatRecord[i].codriverphone}')),
                              // IconButton(
                              //     onPressed: () {},
                              //     icon: const Icon(Icons.toggle_off))
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tiada Rekod Bot'),
                            TextButton.icon(
                              label: const Text('Tambah'),
                              onPressed: () =>
                                  Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => AddBoat(
                                  boatid: 0,
                                  hostname: hostname,
                                  boatdata: const [],
                                  companyid: companyid,
                                ),
                              )),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        );
                },
              );
            }
          }
        });
  }
}
