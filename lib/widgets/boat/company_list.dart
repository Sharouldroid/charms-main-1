import 'package:charms/providers/boats.dart';
import 'package:charms/widgets/boat/history.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompanyList extends StatelessWidget {
  const CompanyList({
    super.key,
    required this.hostname,
    required this.userid,
    required this.isAdmin,
  });

  final String hostname;
  final int userid;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boat Management'),
      ),
      body: FutureBuilder(
        future:
            Provider.of<Boats>(context, listen: false).fetchCompany(hostname),
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
                  builder: (ctx, companyData, child) => ListView.builder(
                        itemCount: companyData.companyRecord.length,
                        itemBuilder: (_, i) => companyData
                                .companyRecord.isNotEmpty
                            ? ExpansionTile(
                                title: Text(
                                    companyData.companyRecord[i].companyname),
                                subtitle: Text(companyData
                                    .companyRecord[i].registrationno),
                                trailing: IconButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (ctx) => History(
                                                  hostname: hostname,
                                                  isAdmin: isAdmin,
                                                ))),
                                    icon: const Icon(Icons.receipt_long)),
                                children: [
                                  Text(
                                      'Address: ${companyData.companyRecord[i].address}'),
                                  Text(
                                      'Phone: ${companyData.companyRecord[i].phone}'),
                                  Text(
                                      'Email: ${companyData.companyRecord[i].email}'),
                                  Text(
                                      'Boat Count: ${companyData.companyRecord[i].boatcount}'),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'No Data',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                      ));
            }
          }
        },
      ),
    );
  }
}
