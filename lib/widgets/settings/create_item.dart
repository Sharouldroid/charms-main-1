import 'package:charms/models/bookingsetting.dart';
import 'package:charms/providers/bookingsettings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateItem extends StatefulWidget {
  const CreateItem({
    super.key,
    required this.hostname,
    required this.settingdata,
    required this.settingdataid,
  });

  final String hostname;
  final Bookingsetting settingdata;
  final int settingdataid;

  @override
  State<CreateItem> createState() => _CreateItemState();
}

class _CreateItemState extends State<CreateItem> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  var _newsettingdata = const Bookingsetting(
    id: 0,
    item: '',
    price: 0,
    itemtype: 1,
  );

  var _initValues = {'id': '', 'item': '', 'price': '', 'itemtype': ''};

  var _isLoading = false;
  var _isInit = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.settingdataid != 0) {
        _initValues = {
          'id': widget.settingdataid.toString(),
          'item': widget.settingdata.item,
          'price': widget.settingdata.price.toString(),
          'itemtype': widget.settingdata.itemtype.toString(),
        };
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _showErrorDialog(String message, int type) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              type == 1 ? 'Warning' : 'Message',
            ), // 1 = error, 2 = success
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
    if (widget.settingdataid == 0) {
      try {
        // print(_authData);
        // await Provider.of<BookingSettings>(context, listen: false)
        //     .addItem(widget.hostname, _newsettingdata);
        Navigator.of(context).pop();
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        // print(_authData);
        await Provider.of<BookingSettings>(
          context,
          listen: false,
        ).updateItem(widget.hostname, _newsettingdata, widget.settingdataid);
        Navigator.of(context).pop();
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
    int settingdatatype = 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.settingdataid == 0
              ? 'Add Booking Item'
              : 'Configure Booking Item',
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                initialValue: _initValues['item'],
                decoration: const InputDecoration(labelText: 'Item'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item';
                  }
                  return null;
                },
                onSaved: (value) {
                  _newsettingdata = Bookingsetting(
                    id: _newsettingdata.id,
                    item: value!,
                    price: _newsettingdata.price,
                    itemtype: _newsettingdata.itemtype,
                  );
                },
              ),
              TextFormField(
                initialValue: _initValues['price'],
                decoration: const InputDecoration(labelText: 'Item Price'),
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item price';
                  }
                  return null;
                },
                onSaved: (value) {
                  _newsettingdata = Bookingsetting(
                    id: _newsettingdata.id,
                    item: _newsettingdata.item,
                    price: int.parse(value!),
                    itemtype: _newsettingdata.itemtype,
                  );
                },
              ),
              DropdownButtonFormField<dynamic>(
                initialValue:
                    _initValues['itemtype']!.isNotEmpty
                        ? int.parse(_initValues['itemtype'].toString())
                        : null,
                hint: const Text('Item Type'),
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Researcher Special Slot'),
                  ),
                  DropdownMenuItem(value: 2, child: Text('Kem Prihatin Penyu')),
                  DropdownMenuItem(value: 3, child: Text('Daytrip')),
                ],
                onChanged: (value) {
                  setState(() {
                    settingdatatype = value!;
                  });
                },
                validator:
                    (value) => value == null ? 'Please choose item type' : null,
                onSaved: (value) {
                  _newsettingdata = Bookingsetting(
                    id: _newsettingdata.id,
                    item: _newsettingdata.item,
                    price: _newsettingdata.price,
                    itemtype: value!,
                  );
                },
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: _submit,
                  child: Text(widget.settingdataid == 0 ? 'Save' : 'Update'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> pickDate() => showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );
}
