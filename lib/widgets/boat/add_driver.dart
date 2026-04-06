import 'package:charms/models/boat.dart';
import 'package:charms/providers/boats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddDriver extends StatefulWidget {
  const AddDriver({
    super.key,
    // required this.boatid,
    required this.hostname,
    required this.driverdata,
    required this.companyid,
    required this.driverid,
  });

  // final int boatid;
  final String hostname;
  final List<BoatDriver> driverdata;
  final int companyid;
  final int driverid;

  @override
  State<AddDriver> createState() => _AddDriverState();
}

class _AddDriverState extends State<AddDriver> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  var _editedInfo = BoatDriver(
    id: 0,
    fullname: '',
    ic: '',
    address: '',
    phone: '',
    licenseexpiry: '',
    companyid: 0,
  );

  var _initValues = {
    'id': '',
    'fullname': '',
    'ic': '',
    'address': '',
    'phone': '',
    'licenseexpiry': '',
    'companyid': '',
  };
  var _isInit = true;
  var _isLoading = false;
  DateTime? _expirydate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.driverdata.isNotEmpty) {
        _initValues = {
          'id': widget.driverdata[0].id.toString(),
          'fullname': widget.driverdata[0].fullname,
          'ic': widget.driverdata[0].ic,
          'address': widget.driverdata[0].address,
          'phone': widget.driverdata[0].phone,
          'licenseexpiry': widget.driverdata[0].licenseexpiry,
          'companyid': widget.companyid.toString(),
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

    if (widget.driverdata.isEmpty) {
      try {
        await Provider.of<Boats>(context, listen: false)
            .createBoatDriver(widget.hostname, _editedInfo, widget.companyid)
            .then((value) => Navigator.of(context).pop());
        // _showErrorDialog('ni create', 1);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        await Provider.of<Boats>(context, listen: false)
            .updateBoatDriver(
                widget.hostname, _editedInfo, widget.companyid, widget.driverid)
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
        title: Text(widget.driverdata.isEmpty
            ? 'Tambah Pemandu'
            : 'Kemaskini Maklumat Pemandu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _initValues['fullname'],
                  decoration: const InputDecoration(labelText: 'Nama Pemandu'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Masukkan nama pemandu';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _editedInfo = BoatDriver(
                      id: _editedInfo.id,
                      fullname: value!,
                      ic: _editedInfo.ic,
                      address: _editedInfo.address,
                      phone: _editedInfo.phone,
                      licenseexpiry: _editedInfo.licenseexpiry,
                      companyid: _editedInfo.companyid,
                    );
                  },
                ),
                TextFormField(
                  initialValue: _initValues['ic'],
                  decoration: const InputDecoration(labelText: 'No IC Pemandu'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Masukkan IC pemandu';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _editedInfo = BoatDriver(
                      id: _editedInfo.id,
                      fullname: _editedInfo.fullname,
                      ic: value!,
                      address: _editedInfo.address,
                      phone: _editedInfo.phone,
                      licenseexpiry: _editedInfo.licenseexpiry,
                      companyid: _editedInfo.companyid,
                    );
                  },
                ),
                TextFormField(
                  initialValue: _initValues['address'],
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Masukkan alamat pemandu';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _editedInfo = BoatDriver(
                      id: _editedInfo.id,
                      fullname: _editedInfo.fullname,
                      ic: _editedInfo.ic,
                      address: value!,
                      phone: _editedInfo.phone,
                      licenseexpiry: _editedInfo.licenseexpiry,
                      companyid: _editedInfo.companyid,
                    );
                  },
                ),
                TextFormField(
                  initialValue: _initValues['phone'],
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'No Telefon Pemandu'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Masukkan nombor telefon pemandu';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _editedInfo = BoatDriver(
                      id: _editedInfo.id,
                      fullname: _editedInfo.fullname,
                      ic: _editedInfo.ic,
                      address: _editedInfo.address,
                      phone: value!,
                      licenseexpiry: _editedInfo.licenseexpiry,
                      companyid: _editedInfo.companyid,
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text('Tarikh Luput Lesen'),
                const SizedBox(height: 10),
                Text(
                  _initValues['licenseexpiry'] != ''
                      ? '${_initValues['licenseexpiry']}'
                      : _expirydate != null
                          ? '${_expirydate!.day}-${_expirydate!.month}-${_expirydate!.year}'
                          : '',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () async {
                    _expirydate = await pickDate();

                    if (_expirydate == null) return;

                    setState(() => _expirydate = _expirydate!);

                    _editedInfo = BoatDriver(
                      id: _editedInfo.id,
                      fullname: _editedInfo.fullname,
                      ic: _editedInfo.ic,
                      address: _editedInfo.address,
                      phone: _editedInfo.phone,
                      // licenseexpiry: _editedInfo.licenseexpiry,
                      // licenseexpiry: _expirydate!.toString(),
                      licenseexpiry:
                          '${_expirydate!.day}-${_expirydate!.month}-${_expirydate!.year}',
                      companyid: _editedInfo.companyid,
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
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
                        widget.driverdata.isEmpty ? 'Simpan' : 'Kemaskini'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100));
}
