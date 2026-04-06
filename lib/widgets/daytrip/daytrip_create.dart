import 'package:charms/models/user.dart';
import 'package:charms/providers/bookingsettings.dart';
import 'package:charms/screens/daytripindemnity_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DaytripCreate extends StatefulWidget {
  const DaytripCreate({
    super.key,
    required this.hostname,
    required this.user,
    required this.companyid,
  });

  final String hostname;
  final User user;
  final int companyid;

  @override
  State<DaytripCreate> createState() => _DaytripCreateState();
}

class _DaytripCreateState extends State<DaytripCreate> {
  DateTime? _selectedDate;
  TimeOfDay? selectedTime;
  int pax = 0;
  int priceperpax = 0;
  int total = 0;

  var _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Pesanan'),
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

  Future<DateTime?> pickDate() async {
    final now = DateTime.now();

    // Block date selection if current time is past 12 noon
    if (now.hour >= 12) {
      _showErrorDialog(
        'Jam telah melepasi 12:00 PM. Masa tamat. Sekarang adalah masa untuk penyu merisik pantai bagi persediaan bertelur',
      );
      return null;
    }

    return showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final now = DateTime.now();

    // Block time selection if current time is past 12 noon
    if (now.hour >= 12) {
      _showErrorDialog(
        'Jam telah melepasi 12:00 PM. Masa tamat. Sekarang adalah masa untuk penyu merisik pantai bagi persediaan bertelur',
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      if (pickedTime.hour >= 12) {
        _showErrorDialog(
          'Jam telah melepasi 12:00 PM. Masa yang dipilih tidak dibenarkan.',
        );
        return;
      }
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd-MM-yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Day Trip Booking')),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Day Trip', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(
                  _selectedDate != null
                      ? 'Tarikh: ${f.format(_selectedDate!)}'
                      : 'Tarikh',
                  style: const TextStyle(fontSize: 18),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await pickDate();
                    if (selectedDate != null) {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                    }
                  },
                  child: const Text('Pilih Tarikh'),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  selectedTime != null
                      ? 'Masa: ${selectedTime!.format(context)}'
                      : 'Masa',
                  style: const TextStyle(fontSize: 18),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  child: const Text('Pilih Masa'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Pax'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter total pax';
                }
                // else if (int.parse(value) > 20) {
                //   return 'Invalid input. Total pax cannot exceed 20 pax';
                // }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  pax = int.parse(value);
                  total = priceperpax * pax;
                });
              },
            ),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, int>>(
              future: Provider.of<BookingSettings>(
                context,
                listen: false,
              ).fetchSettingbystatus(widget.hostname, 3, 1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No data found');
                } else {
                  priceperpax = snapshot.data!['value1']!;
                  return Text('Yuran Konservasi: RM $priceperpax seorang');
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Jumlah: RM $total',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (ctx) => DaytripIndemnityScreen(
                            title: 'Day Trip',
                            total: total,
                            selecteddate: DateTime.parse(
                              _selectedDate.toString(),
                            ),
                            selectedtime:
                                selectedTime!.format(context).toString(),
                            hostname: widget.hostname,
                            user: widget.user,
                            pax: pax,
                            companyid: widget.companyid,
                          ),
                    ),
                  );

                  setState(() {
                    _isLoading = false;
                  });
                },
                child: const Text('Mohon'),
              ),
          ],
        ),
      ),
    );
  }
}
