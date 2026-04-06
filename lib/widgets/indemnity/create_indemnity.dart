import 'package:charms/models/indemnity.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateIndemnity extends StatefulWidget {
  const CreateIndemnity({
    super.key,
    required this.userid,
    required this.hostname,
    required this.indemitems,
    required this.id,
    this.index = 0,
  });

  final int userid;
  final String hostname;
  final List<Indemnity> indemitems;
  final int id;
  final int index;

  @override
  State<CreateIndemnity> createState() => _CreateIndemnityState();
}

class _CreateIndemnityState extends State<CreateIndemnity> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  var _newIndemnity = Indemnity(
    id: 0,
    indemitems: '',
    type: 1,
    status: 1,
  );

  var _initValues = {
    'id': '',
    'indemitems': '',
    'type': '',
    'status': '',
  };
  var _isInit = true;
  var _isLoading = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.indemitems.isNotEmpty) {
        _initValues = {
          'id': widget.indemitems[widget.index].id.toString(),
          'indemitems': widget.indemitems[widget.index].indemitems,
          'type': widget.indemitems[widget.index].type.toString(),
          'status': widget.indemitems[widget.index].status.toString(),
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
    if (widget.indemitems.isEmpty) {
      try {
        await Provider.of<Indemnitites>(context, listen: false)
            .createIndemnity(widget.hostname, _newIndemnity, widget.userid);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        await Provider.of<Indemnitites>(context, listen: false).updateIndemnity(
            widget.hostname, _newIndemnity, widget.userid, widget.id);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    }

    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Indemnity'),
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
                initialValue: _initValues['indemitems'],
                decoration: const InputDecoration(labelText: 'Item'),
                textInputAction: TextInputAction.next,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter indemnity text';
                  }
                  return null;
                },
                onSaved: (value) {
                  _newIndemnity = Indemnity(
                    id: _newIndemnity.id,
                    indemitems: value!,
                    type: _newIndemnity.type,
                  );
                },
              ),
              DropdownButtonFormField<dynamic>(
                initialValue: _initValues['type']!.isNotEmpty
                    ? int.parse(_initValues['type'].toString())
                    : null,
                hint: const Text('Indemnity Type'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Default')),
                  DropdownMenuItem(value: 2, child: Text('With Child')),
                  DropdownMenuItem(value: 4, child: Text('Day Trip')),
                ],
                onChanged: (value) {
                  setState(() {
                    // _selectedType = value!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please choose indemnity type' : null,
                onSaved: (value) {
                  _newIndemnity = Indemnity(
                    id: _newIndemnity.id,
                    indemitems: _newIndemnity.indemitems,
                    type: value!,
                  );
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: _submit,
                  child: Text(widget.indemitems.isEmpty ? 'Save' : 'Update'),
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
      lastDate: DateTime(2100));
}
