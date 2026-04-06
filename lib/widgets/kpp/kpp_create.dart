import 'package:charms/models/event.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/bookingsettings.dart';
import 'package:charms/providers/events_kpp.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KppCreate extends StatefulWidget {
  const KppCreate({
    super.key,
    required this.hostname,
    required this.eventdata,
    required this.user,
    required this.picemail,
  });

  final String hostname;
  final SpecialEvent eventdata;
  final User user;
  final String picemail;

  @override
  State<KppCreate> createState() => _KppCreateState();
}

class _KppCreateState extends State<KppCreate> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final _newEvent = const SpecialEvent(id: 0, pax: 0, startdate: '', enddate: '');

  var _initValues = {
    'id': '',
    'pax': '',
    'startdate': '',
    'enddate': '',
    'picemail': '',
  };

  var _isLoading = false;
  var _isInit = true;

  DateTime? _startDate;
  DateTime? _endDate;
  int pax = 0;
  int totaldays = 0;
  String _picemail = '';

  int priceperpax = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.eventdata.id != 0) {
        _initValues = {
          'id': widget.eventdata.id.toString(),
          'userid': widget.user.id,
          'pax': widget.eventdata.pax.toString(),
          'startdate': widget.eventdata.startdate,
          'enddate': widget.eventdata.enddate,
          'picemail': widget.picemail,
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

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventdata.id == 0 ? 'Request KPP' : 'Update KPP'),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Kem Prihatin Penyu', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              const Card(child: Text('Please input date.')),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Start Date'),
                        const SizedBox(height: 10),
                        Text(
                          _startDate != null
                              ? f.format(_startDate!)
                              : (_initValues['startdate'] ?? 'Start Date'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      _startDate = await pickDate();

                      if (_startDate == null) return;

                      setState(() {
                        _startDate = _startDate!;

                        if (_endDate != null) {
                          if (_startDate!.isAfter(_endDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: Start date must be set before the end date',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          totaldays = _endDate!.difference(_startDate!).inDays;
                        }
                      });
                    },
                    icon: const Icon(Icons.calendar_month),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('End Date'),
                        const SizedBox(height: 10),
                        Text(
                          _endDate != null
                              ? f.format(_endDate!)
                              : (_initValues['enddate'] ?? 'End Date'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      _endDate = await pickDate();

                      if (_endDate == null) return;

                      setState(() {
                        _endDate = _endDate!;

                        if (_startDate != null) {
                          if (_endDate!.isBefore(_startDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: End date must be set after the start date',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          totaldays = _endDate!.difference(_startDate!).inDays;
                        }
                      });
                    },
                    icon: const Icon(Icons.calendar_month),
                  ),
                ],
              ),
              Text('$totaldays days'),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _initValues['picemail'],
                decoration: const InputDecoration(labelText: 'PIC Email'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter person in charge email';
                  }
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  _picemail = value;
                },
              ),
              TextFormField(
                initialValue: _initValues['pax'],
                decoration: const InputDecoration(labelText: 'Pax'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total pax';
                  } else if (int.parse(value) > 20) {
                    return 'Invalid input. Total pax cannot exceed 20 pax';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    pax = int.parse(value);
                    total = priceperpax;
                  });
                },
              ),
              FutureBuilder<Map<String, int>>(
                future: Provider.of<BookingSettings>(
                  context,
                  listen: false,
                ).fetchSettingbystatus(widget.hostname, 2, 1),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No data found');
                  } else {
                    priceperpax = snapshot.data!['value1']!;
                    return const SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Total: RM $total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      // Invalid!
                      return;
                    }
                    _formKey.currentState!.save();
                    setState(() {
                      _isLoading = true;
                    });
                    Provider.of<EventsKPP>(context, listen: false).applyKPP(
                      widget.hostname,
                      int.parse(widget.user.id),
                      _picemail,
                      pax,
                      _startDate.toString(),
                      _endDate.toString(),
                      total,
                    );
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    widget.eventdata.id == 0 ? 'Proceed' : 'Update',
                    style: TextStyle(color: Colors.black),
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
