import 'package:charms/models/event.dart';
import 'package:charms/models/specialbooking_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/bookingsettings.dart';
import 'package:charms/widgets/researcher/specialresearch_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CustomEvent extends StatefulWidget {
  const CustomEvent({
    super.key,
    required this.hostname,
    required this.eventdata,
    required this.user,
  });

  final String hostname;
  final SpecialEvent eventdata;
  final User user;

  @override
  State<CustomEvent> createState() => _CustomEventState();
}

class _CustomEventState extends State<CustomEvent> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  var _newEvent = const SpecialEvent(
    id: 0,
    pax: 0,
    startdate: '',
    enddate: '',
    needboat: 0,
  );

  var _initValues = {
    'id': '',
    'pax': '',
    'startdate': '',
    'enddate': '',
    'needboat': '',
  };

  var _isLoading = false;
  var _isInit = true;

  DateTime? _startDate;
  DateTime? _endDate;
  int pax = 0;
  int totaldays = 0;

  int priceperpax = 0;
  int boatpriceperpax = 0;
  int total = 0;
  int totalboat = 0;
  bool showboatprice = false;

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
          'needboat': widget.eventdata.needboat.toString(),
        };
        _startDate = DateTime.tryParse(widget.eventdata.startdate);
        _endDate = DateTime.tryParse(widget.eventdata.enddate);
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventdata.id == 0
              ? 'Request Special Slot'
              : 'Update Special Slot',
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Researcher Special Slot',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              const Card(
                child: Column(
                  children: [
                    Text('Please input date.'),
                    SizedBox(height: 10),
                    Text(
                      'Please be informed that you can apply for any dates except Wednesdays and Saturdays.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  // Text(_startDate != null
                  //     ? '${_startDate!.day}-${_startDate!.month}-${_startDate!.year}'
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

                      _newEvent = SpecialEvent(
                        id: _newEvent.id,
                        pax: _newEvent.pax,
                        startdate: _startDate!.toString(),
                        enddate: _newEvent.enddate,
                        needboat: _newEvent.needboat,
                      );
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

                      _newEvent = SpecialEvent(
                        id: _newEvent.id,
                        pax: _newEvent.pax,
                        startdate: _newEvent.startdate,
                        enddate: _endDate!.toString(),
                        needboat: _newEvent.needboat,
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                  ),
                ],
              ),
              Text('$totaldays days'),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _initValues['pax'],
                decoration: const InputDecoration(labelText: 'Pax'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total pax';
                  } else if (int.parse(value) > 10) {
                    return 'Invalid input. Total pax cannot exceed 10 pax';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    pax = int.parse(value);
                    total = (priceperpax * pax * totaldays).toInt();
                    showboatprice == true
                        ? totalboat = pax * boatpriceperpax
                        : totalboat = 0;
                  });
                },
                onSaved: (value) {
                  _newEvent = SpecialEvent(
                    id: _newEvent.id,
                    startdate: _newEvent.startdate,
                    enddate: _newEvent.enddate,
                    pax: _newEvent.pax,
                    needboat: _newEvent.needboat,
                  );
                },
              ),
              // Text('Total: RM $total'),
              FutureBuilder<Map<String, int>>(
                future: Provider.of<BookingSettings>(
                  context,
                  listen: false,
                ).fetchSettingbystatus(widget.hostname, 1, 1),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No data found');
                  } else {
                    priceperpax = snapshot.data!['value1']!;
                    boatpriceperpax = snapshot.data!['value2']!;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Price Per Pax: RM $priceperpax'),
                        Text('Total: RM $total'),
                        // Text('Boat Price Per Pax: RM $boatpriceperpax'),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text('Do you need boat arrangement?'),
              DropdownButtonFormField<dynamic>(
                initialValue: 0,
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('No, I will arrange the boat myself'),
                  ),
                  DropdownMenuItem(value: 1, child: Text('Yes, please')),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value == 1) {
                      showboatprice = true;
                      totalboat = pax * boatpriceperpax;
                    } else {
                      showboatprice = false;
                      totalboat = 0;

                      // _selectedType = value!;
                    }
                  });
                },
                validator: (value) => value == null ? 'Please choose' : null,
                onSaved: (value) {
                  _newEvent = SpecialEvent(
                    id: _newEvent.id,
                    startdate: _newEvent.startdate,
                    enddate: _newEvent.enddate,
                    pax: _newEvent.pax,
                    needboat: int.parse(value.toString()),
                  );
                },
              ),
              Visibility(
                visible: showboatprice,
                child: Column(
                  children: [
                    Text(' Boat Charge per pax: RM $boatpriceperpax'),
                    Text('Total boat charge: RM $totalboat'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Total: RM ${total + totalboat}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (ctx) => ResearcherSpecialInfo(
                              hostname: widget.hostname,
                              user: widget.user,
                              pax: pax,
                              startdate: _startDate.toString(),
                              enddate: _endDate.toString(),
                              eventprice: total,
                              boatprice: totalboat,
                            ),
                      ),
                    );

                    Provider.of<SpecialBookingCartOut>(
                      context,
                      listen: false,
                    ).addItem(
                      '0-${widget.user.id}',
                      'Researcher Special Slot',
                      int.parse(widget.user.id),
                      pax,
                      '',
                      // boatpriceperpax,
                      totalboat,
                      total,
                      _startDate.toString(),
                      _endDate.toString(),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: Text(
                    widget.eventdata.id == 0 ? 'Proceed' : 'Update',
                    style: const TextStyle(color: Colors.white),
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
