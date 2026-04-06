import 'package:charms/models/boat.dart';
import 'package:charms/providers/boats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({
    super.key,
    required this.userid,
    required this.hostname,
    required this.companydata,
  });

  final int userid;
  final String hostname;
  final List<BoatCompany> companydata;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  var _editedInfo = BoatCompany(
    id: 0,
    companyname: '',
    phone: '',
    email: '',
    address: '',
    ownerid: 0,
    boatcount: 0,
    registrationno: '',
  );

  var _initValues = {
    'id': '',
    'companyname': '',
    'phone': '',
    'email': '',
    'address': '',
    'ownerid': '',
    'boatcount': '',
    'registrationno': '',
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
      if (widget.companydata.isNotEmpty) {
        _initValues = {
          'id': widget.companydata[0].id.toString(),
          'companyname': widget.companydata[0].companyname,
          'phone': widget.companydata[0].phone,
          'email': widget.companydata[0].email,
          'address': widget.companydata[0].address,
          'ownerid': widget.userid.toString(),
          'boatcount': widget.companydata[0].boatcount.toString(),
          'registrationno': widget.companydata[0].registrationno,
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

    if (widget.companydata.isEmpty) {
      try {
        await Provider.of<Boats>(context, listen: false)
            .createBoatCompany(widget.hostname, _editedInfo, widget.userid)
            .then((value) => Navigator.of(context).pop());
        // _showErrorDialog('ni create', 1);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        await Provider.of<Boats>(context, listen: false)
            .updateBoatCompany(
                widget.hostname, _editedInfo, widget.companydata[0].id)
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
        title: Text(widget.companydata.isEmpty
            ? 'Maklumat Syarikat'
            : 'Kemaskini Maklumat Syarikat'),
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
                    initialValue: _initValues['companyname'],
                    decoration:
                        const InputDecoration(labelText: 'Nama Syarikat'),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Masukkan nama syarikat';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = BoatCompany(
                        id: _editedInfo.id,
                        companyname: value!,
                        phone: _editedInfo.phone,
                        email: _editedInfo.email,
                        address: _editedInfo.address,
                        ownerid: widget.userid,
                        registrationno: _editedInfo.registrationno,
                        boatcount: _editedInfo.boatcount,
                      );
                    },
                  ),
                  TextFormField(
                    initialValue: _initValues['registrationno'].toString(),
                    decoration:
                        const InputDecoration(labelText: 'No Pendaftaran'),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Masukkan nombor pendaftaran syarikat';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = BoatCompany(
                        id: _editedInfo.id,
                        companyname: _editedInfo.companyname,
                        phone: _editedInfo.phone,
                        email: _editedInfo.email,
                        address: _editedInfo.address,
                        ownerid: widget.userid,
                        registrationno: value!,
                        boatcount: _editedInfo.boatcount,
                      );
                    },
                  ),
                  TextFormField(
                    initialValue: _initValues['address'].toString(),
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    textInputAction: TextInputAction.next,
                    maxLines: 3,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Masukkan alamat syarikat';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = BoatCompany(
                        id: _editedInfo.id,
                        companyname: _editedInfo.companyname,
                        phone: _editedInfo.phone,
                        email: _editedInfo.email,
                        address: value!,
                        ownerid: widget.userid,
                        registrationno: _editedInfo.registrationno,
                        boatcount: _editedInfo.boatcount,
                      );
                    },
                  ),
                  TextFormField(
                    initialValue: _initValues['phone'].toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'No Telefon'),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Masukkan nombor telefon syarikat';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = BoatCompany(
                        id: _editedInfo.id,
                        companyname: _editedInfo.companyname,
                        phone: value!,
                        email: _editedInfo.email,
                        address: _editedInfo.address,
                        ownerid: widget.userid,
                        registrationno: _editedInfo.registrationno,
                        boatcount: _editedInfo.boatcount,
                      );
                    },
                  ),
                  TextFormField(
                    initialValue: _initValues['email'].toString(),
                    decoration: const InputDecoration(labelText: 'Emel'),
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Masukkan emel syarikat';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = BoatCompany(
                        id: _editedInfo.id,
                        companyname: _editedInfo.companyname,
                        phone: _editedInfo.phone,
                        email: value!,
                        address: _editedInfo.address,
                        ownerid: widget.userid,
                        registrationno: _editedInfo.registrationno,
                        boatcount: _editedInfo.boatcount,
                      );
                    },
                  ),
                  TextFormField(
                    initialValue: _initValues['boatcount'].toString(),
                    decoration: const InputDecoration(labelText: 'Jumlah Bot'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null) {
                        return 'Masukkan jumlah bot';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _editedInfo = BoatCompany(
                        id: _editedInfo.id,
                        companyname: _editedInfo.companyname,
                        phone: _editedInfo.phone,
                        email: _editedInfo.email,
                        address: _editedInfo.address,
                        ownerid: widget.userid,
                        registrationno: _editedInfo.registrationno,
                        boatcount: int.parse(value!),
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
                          widget.companydata.isEmpty ? 'Simpan' : 'Kemaskini'),
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
