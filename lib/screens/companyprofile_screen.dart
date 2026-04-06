import 'package:charms/models/boat.dart';
import 'package:charms/widgets/boat/edit_profile.dart';
import 'package:flutter/material.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({
    super.key,
    required this.userid,
    required this.hostname,
    required this.companydata,
  });

  final int userid;
  final String hostname;
  final List<BoatCompany> companydata;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Maklumat Syarikat'),
        ),
        body: companydata.isNotEmpty
            ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Container(
                      //   decoration: BoxDecoration(
                      //     border: Border.all(
                      //       width: 1,
                      //       color: Theme.of(context).colorScheme.primary,
                      //     ),
                      //   ),
                      //   height: 250,
                      //   width: double.infinity,
                      //   child: Image.network(
                      //     'https://i.pinimg.com/474x/ae/90/4e/ae904ea29ca111d5fbd9e9e08a953322.jpg',
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      // const SizedBox(height: 14),
                      Text(
                        'Nama Syarikat',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        companydata[0].companyname,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Telefon',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        companydata[0].phone,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Emel',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          companydata[0].email,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Pendaftaran',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      // for (final step in meal.steps)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          companydata[0].registrationno,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Status Syarikat',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      userid != companydata[0].ownerid
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: companydata[0].status == 2
                                  ? ElevatedButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Verify User',
                                      ),
                                    )
                                  : Text(
                                      'User Verified',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: companydata[0].status == 2
                                  ? Text(
                                      'Not Verified',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    )
                                  : Text(
                                      'Verified',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                            ),
                      const SizedBox(height: 50),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (ctx) => EditProfile(
                                      userid: userid,
                                      hostname: hostname,
                                      companydata: companydata,
                                    )));
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Kemaskini'),
                        ),
                      )
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                    child: Text('Maklumat Syarikat Tidak Lengkap'),
                  ),
                  TextButton.icon(
                    label: const Text('Lengkapkan'),
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => EditProfile(
                        userid: userid,
                        hostname: hostname,
                        companydata: const [],
                      ),
                    )),
                    icon: const Icon(Icons.check_box),
                  ),
                ],
              ));
  }
}
