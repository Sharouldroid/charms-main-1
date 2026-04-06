import 'package:charms/models/event.dart';
import 'package:charms/providers/events.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreateEvent extends StatefulWidget {
  const CreateEvent({
    super.key,
    required this.userid,
    required this.hostname,
    required this.eventdata,
  });

  final int userid;
  final String hostname;
  final Event eventdata;

  @override
  State<CreateEvent> createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  var _newEvent = Event(
    id: '',
    title: '',
    startdate: '',
    enddate: '',
    slotvolunteer: 0,
    slotresearcher: 0,
    eventtype: 0,
    price: 0,
    priceresearcher: 0,
    status: 0,
  );

  var _initValues = {
    'id': '',
    'title': '',
    'startdate': '',
    'enddate': '',
    'slotvolunteer': '',
    'slotresearcher': '',
    'eventtype': '',
    'price': '',
    'priceresearcher': '',
    'status': '',
  };

  var _isLoading = false;
  var _isInit = true;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (int.parse(widget.eventdata.id) != 0) {
        _initValues = {
          'id': widget.eventdata.id,
          'title': widget.eventdata.title,
          'startdate': widget.eventdata.startdate,
          'enddate': widget.eventdata.enddate,
          'slotvolunteer': widget.eventdata.slotvolunteer.toString(),
          'slotresearcher': widget.eventdata.slotresearcher.toString(),
          'eventtype': widget.eventdata.eventtype.toString(),
          'price': widget.eventdata.price.toString(),
          'priceresearcher': widget.eventdata.priceresearcher.toString(),
        };
        _startDate = DateTime.tryParse(widget.eventdata.startdate);
        _endDate = DateTime.tryParse(widget.eventdata.enddate);
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
    if (int.parse(widget.eventdata.id) == 0) {
      try {
        // print(_authData);
        await Provider.of<Events>(
          context,
          listen: false,
        ).createEvent(widget.hostname, _newEvent, widget.userid);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        // print(_authData);
        await Provider.of<Events>(context, listen: false).updateEvent(
          widget.hostname,
          _newEvent,
          int.parse(widget.eventdata.id),
        );
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    }
    setState(() {
      _isLoading = false;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          int.parse(widget.eventdata.id) == 0 ? 'Create Event' : 'Update Event',
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
                initialValue: _initValues['title'],
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Event title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _newEvent = Event(
                    id: _newEvent.id,
                    title: value!,
                    startdate: _newEvent.startdate,
                    enddate: _newEvent.enddate,
                    slotvolunteer: _newEvent.slotvolunteer,
                    slotresearcher: _newEvent.slotresearcher,
                    eventtype: _newEvent.eventtype,
                    price: _newEvent.price,
                    priceresearcher: _newEvent.priceresearcher,
                    status: 0,
                  );
                },
              ),

              // DropdownButtonFormField<dynamic>(
              //   value: _initValues['eventtype']!.isNotEmpty
              //       ? int.parse(_initValues['eventtype'].toString())
              //       : null,
              //   hint: const Text('Event Type'),
              //   items: const [
              //     DropdownMenuItem(value: 1, child: Text('Volunteer Event')),
              //     DropdownMenuItem(value: 2, child: Text('Researcher Event')),
              //     DropdownMenuItem(value: 3, child: Text('Kem Prihatin Penyu')),
              //     DropdownMenuItem(value: 4, child: Text('Day Trip')),
              //   ],
              //   onChanged: (value) {
              //     setState(() {
              //       // _selectedType = value!;
              //     });
              //   },
              //   validator: (value) =>
              //       value == null ? 'Please choose Event type' : null,
              //   onSaved: (value) {
              //     _newEvent = Event(
              //         id: _newEvent.id,
              //         title: _newEvent.title,
              //         startdate: _newEvent.startdate,
              //         enddate: _newEvent.enddate,
              //         slotvolunteer: _newEvent.slotvolunteer,
              //         slotresearcher: _newEvent.slotresearcher,
              //         eventtype: value!,
              //         price: _newEvent.price,
              //         priceresearcher: _newEvent.priceresearcher,
              //         status: 0);
              //   },
              // ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _initValues['slotvolunteer'],
                      decoration: const InputDecoration(
                        labelText: 'Volunteer Slot',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter volunteer slot';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _newEvent = Event(
                          id: _newEvent.id,
                          title: _newEvent.title,
                          startdate: _newEvent.startdate,
                          enddate: _newEvent.enddate,
                          slotvolunteer: int.parse(value!),
                          slotresearcher: _newEvent.slotresearcher,
                          eventtype: _newEvent.eventtype,
                          price: _newEvent.price,
                          priceresearcher: _newEvent.priceresearcher,
                          status: 0,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: _initValues['slotresearcher'],
                      decoration: const InputDecoration(
                        labelText: 'Researcher Slot',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter researcher slot';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _newEvent = Event(
                          id: _newEvent.id,
                          title: _newEvent.title,
                          startdate: _newEvent.startdate,
                          enddate: _newEvent.enddate,
                          slotvolunteer: _newEvent.slotvolunteer,
                          slotresearcher: int.parse(value!),
                          eventtype: _newEvent.eventtype,
                          price: _newEvent.price,
                          priceresearcher: _newEvent.priceresearcher,
                          status: 0,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _initValues['price'],
                      decoration: const InputDecoration(
                        labelText: 'Volunteer Price',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter event price for volunteer';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _newEvent = Event(
                          id: _newEvent.id,
                          title: _newEvent.title,
                          startdate: _newEvent.startdate,
                          enddate: _newEvent.enddate,
                          slotvolunteer: _newEvent.slotvolunteer,
                          slotresearcher: _newEvent.slotresearcher,
                          eventtype: _newEvent.eventtype,
                          price: double.parse(value!),
                          priceresearcher: _newEvent.priceresearcher,
                          status: 0,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: _initValues['priceresearcher'],
                      decoration: const InputDecoration(
                        labelText: 'Researcher Price',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter event price for researcher';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _newEvent = Event(
                          id: _newEvent.id,
                          title: _newEvent.title,
                          startdate: _newEvent.startdate,
                          enddate: _newEvent.enddate,
                          slotvolunteer: _newEvent.slotvolunteer,
                          slotresearcher: _newEvent.slotresearcher,
                          eventtype: _newEvent.eventtype,
                          price: _newEvent.price,
                          priceresearcher: double.parse(value!),
                          status: 0,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  // Text(_startDate != null
                  //     ? '${_startDate!.day}-${_startDate!.month}-${_startDate!.year}'
                  Text(
                    _startDate != null
                        ? f.format(_startDate!)
                        : (_initValues['startdate'] ?? 'Start Date'),
                  ),

                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      _startDate = await pickDate();

                      if (_startDate == null) return;

                      // setState(() => _startDate = _startDate!);
                      setState(() {
                        _startDate = _startDate!;
                        _initValues['startdate'] = f.format(_startDate!);
                      });

                      _newEvent = Event(
                        id: _newEvent.id,
                        title: _newEvent.title,
                        startdate: _startDate!.toIso8601String(),
                        enddate: _newEvent.enddate,
                        slotvolunteer: _newEvent.slotvolunteer,
                        slotresearcher: _newEvent.slotresearcher,
                        eventtype: _newEvent.eventtype,
                        price: _newEvent.price,
                        priceresearcher: _newEvent.priceresearcher,
                        status: 0,
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                  ),
                  const Spacer(),
                  Text(
                    _endDate != null
                        ? f.format(_endDate!)
                        : (_initValues['enddate'] ?? 'End Date'),
                  ),

                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      _endDate = await pickDate();

                      if (_endDate == null) return;

                      // setState(() => _endDate = _endDate!);
                      setState(() {
                        _endDate = _endDate!;
                        _initValues['enddate'] = f.format(_endDate!);
                      });

                      _newEvent = Event(
                        id: _newEvent.id,
                        title: _newEvent.title,
                        startdate: _newEvent.startdate,
                        enddate: _endDate!.toIso8601String(),
                        slotvolunteer: _newEvent.slotvolunteer,
                        slotresearcher: _newEvent.slotresearcher,
                        eventtype: _newEvent.eventtype,
                        price: _newEvent.price,
                        priceresearcher: _newEvent.priceresearcher,
                        status: 0,
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                  ),
                ],
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
                  child: Text(
                    int.parse(widget.eventdata.id) == 0 ? 'Save' : 'Update',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
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
