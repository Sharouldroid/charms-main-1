import 'package:charms/models/boat.dart';
import 'package:charms/providers/boats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddBoat extends StatefulWidget {
  const AddBoat({
    super.key,
    required this.boatid,
    required this.hostname,
    required this.boatdata,
    required this.companyid,
    this.index = 0,
  });

  final int boatid;
  final String hostname;
  final List<Boat> boatdata;
  final int companyid;
  final int index;

  @override
  State<AddBoat> createState() => _AddBoatState();
}

class _AddBoatState extends State<AddBoat> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  var _editedInfo = Boat(
    id: 0,
    name: '',
    capacity: 0,
    companyId: 0,
  );

  var _initValues = {
    'id': '',
    'name': '',
    'capacity': '',
    'companyId': '',
  };
  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.boatdata.isNotEmpty) {
        _initValues = {
          'id': widget.boatdata[widget.index].id.toString(),
          'name': widget.boatdata[widget.index].name,
          'capacity': widget.boatdata[widget.index].capacity.toString(),
          'companyId': widget.boatdata[widget.index].companyId.toString(),
        };
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _showErrorDialog(String message, int type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(type == 1 ? 'Warning' : 'Message'), // 1 = error, 2 = success
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    if (widget.boatdata.isEmpty) {
      try {
        await Provider.of<Boats>(context, listen: false)
            .createBoat(widget.hostname, _editedInfo, widget.companyid)
            .then((value) => Navigator.of(context).pop());
        // _showErrorDialog('ni create', 1);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        await Provider.of<Boats>(context, listen: false)
            .updateBoat(
                widget.hostname, _editedInfo, widget.companyid, widget.boatid)
            .then((value) => Navigator.of(context).pop());
        // _showErrorDialog('ni update', 1);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.boatdata.isEmpty ? 'Tambah Bot' : 'Kemaskini Maklumat Bot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _initValues['name'],
                    decoration: const InputDecoration(
                        labelText: 'Nombor Pendaftaran Bot'),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Masukkan nombor pendaftaran bot';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = Boat(
                        id: _editedInfo.id,
                        name: value!,
                        capacity: _editedInfo.capacity,
                        companyId: _editedInfo.companyId,
                      );
                    },
                  ),
                  // TextFormField(
                  //   initialValue: _initValues['driver'],
                  //   decoration: const InputDecoration(labelText: 'Pemandu'),
                  //   textInputAction: TextInputAction.next,
                  //   validator: (value) {
                  //     if (value!.isEmpty) {
                  //       return 'Masukkan nama pemandu';
                  //     }
                  //     return null;
                  //   },
                  //   onSaved: (value) {
                  //     _editedInfo = Boat(
                  //       id: _editedInfo.id,
                  //       name: _editedInfo.name,
                  //       driver: value!,
                  //       codriver: _editedInfo.codriver,
                  //       driverphone: _editedInfo.driverphone,
                  //       codriverphone: _editedInfo.codriverphone,
                  //       capacity: _editedInfo.capacity,
                  //       companyId: _editedInfo.companyId,
                  //     );
                  //   },
                  // ),
                  // TextFormField(
                  //   initialValue: _initValues['codriver'].toString(),
                  //   decoration:
                  //       const InputDecoration(labelText: 'Pembantu Pemandu'),
                  //   textInputAction: TextInputAction.next,
                  //   validator: (value) {
                  //     if (value!.isEmpty) {
                  //       return 'Masukkan pembantu pemandu';
                  //     }
                  //     return null;
                  //   },
                  //   onSaved: (value) {
                  //     _editedInfo = Boat(
                  //       id: _editedInfo.id,
                  //       name: _editedInfo.name,
                  //       driver: _editedInfo.driver,
                  //       codriver: value!,
                  //       driverphone: _editedInfo.driverphone,
                  //       codriverphone: _editedInfo.codriverphone,
                  //       capacity: _editedInfo.capacity,
                  //       companyId: _editedInfo.companyId,
                  //     );
                  //   },
                  // ),
                  // TextFormField(
                  //   initialValue: _initValues['codriverphone'].toString(),
                  //   keyboardType: TextInputType.number,
                  //   decoration:
                  //       const InputDecoration(labelText: 'No Telefon Pemandu'),
                  //   textInputAction: TextInputAction.next,
                  //   validator: (value) {
                  //     if (value!.isEmpty) {
                  //       return 'Masukkan nombor telefon pemandu';
                  //     }
                  //     return null;
                  //   },
                  //   onSaved: (value) {
                  //     _editedInfo = Boat(
                  //       id: _editedInfo.id,
                  //       name: _editedInfo.name,
                  //       driver: _editedInfo.driver,
                  //       codriver: _editedInfo.codriver,
                  //       driverphone: value!,
                  //       codriverphone: _editedInfo.codriverphone,
                  //       capacity: _editedInfo.capacity,
                  //       companyId: _editedInfo.companyId,
                  //     );
                  //   },
                  // ),
                  // TextFormField(
                  //   initialValue: _initValues['codriverphone'],
                  //   decoration: const InputDecoration(
                  //       labelText: 'No Telefon Pembantu Pemandu'),
                  //   textInputAction: TextInputAction.done,
                  //   autocorrect: false,
                  //   validator: (value) {
                  //     if (value == null || value.trim().isEmpty) {
                  //       return 'Masukkan nombor telefon pembantu pemandu';
                  //     }
                  //     return null;
                  //   },
                  //   onSaved: (value) {
                  //     _editedInfo = Boat(
                  //       id: _editedInfo.id,
                  //       name: _editedInfo.name,
                  //       driver: _editedInfo.driver,
                  //       codriver: _editedInfo.codriver,
                  //       driverphone: _editedInfo.driverphone,
                  //       capacity: _editedInfo.capacity,
                  //       codriverphone: value!,
                  //       companyId: _editedInfo.companyId,
                  //     );
                  //   },
                  // ),
                  TextFormField(
                    initialValue: _initValues['capacity'],
                    decoration:
                        const InputDecoration(labelText: 'Kapasiti Bot'),
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Masukkan kapasiti bot';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = Boat(
                        id: _editedInfo.id,
                        name: _editedInfo.name,
                        capacity: int.parse(value!),
                        companyId: _editedInfo.companyId,
                      );
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      ),
                      onPressed: _submit,
                      child: Text(
                          widget.boatdata.isEmpty ? 'Simpan' : 'Kemaskini'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
