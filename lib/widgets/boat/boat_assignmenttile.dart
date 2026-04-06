import 'package:charms/models/event.dart';
import 'package:charms/providers/boats.dart';
import 'package:charms/widgets/boat/boat_participant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BoatAssignmentTile extends StatefulWidget {
  final Event event;
  final String hostname;
  final int usertype;
  final int userid;

  const BoatAssignmentTile({
    super.key,
    required this.event,
    required this.hostname,
    required this.usertype,
    required this.userid,
  });

  @override
  State<BoatAssignmentTile> createState() => BoatAssignmentTileState();
}

class BoatAssignmentTileState extends State<BoatAssignmentTile> {
  bool _isAssigned = false;
  bool _isLoading = true;
  bool _isCompleted = false;
  int? _companyId;
  DateTime? _returnTime;
  DateTime? _departureTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _checkAssignmentStatus();
    await _fetchCompanyData();
    await _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    try {
      final tripDetails = await Provider.of<Boats>(
        context,
        listen: false,
      ).getTripDetails(widget.hostname, int.parse(widget.event.id));

      if (mounted) {
        setState(() {
          _departureTime = tripDetails['timedepart'];
          _returnTime = tripDetails['timereturn'];
          _isCompleted = _returnTime != null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompleted = false;
        });
      }
    }
  }

  Future<void> _checkAssignmentStatus() async {
    try {
      final assigned = await Provider.of<Boats>(
        context,
        listen: false,
      ).isEventAssigned(widget.hostname, int.parse(widget.event.id));
      if (mounted) {
        setState(() {
          _isAssigned = assigned;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check assignment: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _fetchCompanyData() async {
    try {
      final companyId = await Provider.of<Boats>(
        context,
        listen: false,
      ).fetchCompanyDatabyUserid(widget.hostname, widget.userid);

      if (mounted) {
        setState(() {
          _companyId = companyId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch company: ${e.toString()}')),
        );
      }
    }
  }

  void _showTripConfirm(BuildContext context, int eventId) {
    if (_companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila lengkapkan maklumat syarikat anda')),
      );
      return;
    }

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Ambil Trip Ini?'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adakah anda bersedia menjalankan trip ini?'),
                    const SizedBox(height: 20),
                    _buildDateTimePicker(
                      label: 'Waktu Bertolak',
                      initialDateTime: DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                      onDateTimeChanged: (dateTime) {
                        selectedDate = dateTime;
                        selectedTime = TimeOfDay.fromDateTime(dateTime);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime timedepart = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      Navigator.of(ctx).pop();
                      await _assignBoat(eventId, timedepart, _companyId!);
                      await _checkAssignmentStatus();
                    },
                    child: const Text('Ya'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _assignBoat(
    int eventId,
    DateTime timedepart,
    int companyId,
  ) async {
    try {
      final formattedTime = timedepart.toIso8601String();

      await Provider.of<Boats>(
        context,
        listen: false,
      ).assignTrip(widget.hostname, eventId, companyId, 0, formattedTime);

      if (mounted) {
        setState(() {
          _departureTime = timedepart;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip berjaya diterima!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menerima trip: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateReturnTime() async {
    try {
      await Provider.of<Boats>(context, listen: false).updateReturnTime(
        widget.hostname,
        int.parse(widget.event.id),
        _companyId!,
        _returnTime!.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _isCompleted = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu pulang berjaya dikemaskini!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengemaskini: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child:
          _isCompleted
              ? _buildCompletedTripCard()
              : ExpansionTile(
                title: _buildTitle(),
                subtitle: _buildSubtitle(),
                trailing: _buildTrailingIcons(),
                children: _isAssigned ? [_buildReturnTimeForm()] : [],
              ),
    );
  }

  Widget _buildCompletedTripCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.event.startdate))} - '
            '${DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.event.enddate))}',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_departureTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Bertolak: ${DateFormat('dd/MM/yyyy HH:mm').format(_departureTime!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          if (_returnTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.arrow_downward, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Pulang: ${DateFormat('dd/MM/yyyy HH:mm').format(_returnTime!)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.blue),
            onPressed: () => _navigateToParticipants(),
            tooltip: 'Senarai Sukarelawan',
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.event.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.teal,
            ),
          ),
        ),
        if (_isAssigned && !_isLoading)
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      '${DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.event.startdate))} - '
      '${DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.event.enddate))}',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildTrailingIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.people, color: Colors.blue),
          onPressed: () => _navigateToParticipants(),
          tooltip: 'Senarai Sukarelawan',
        ),
        if (!_isAssigned && !_isLoading)
          IconButton(
            icon: const Icon(Icons.directions_boat, color: Colors.green),
            onPressed:
                () => _showTripConfirm(context, int.parse(widget.event.id)),
            tooltip: 'Terima Trip',
          ),
      ],
    );
  }

  Widget _buildReturnTimeForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateTimePicker(
            label: 'Tarikh dan Waktu Pulang',
            initialDateTime:
                _returnTime ?? DateTime.now().add(const Duration(hours: 2)),
            onDateTimeChanged:
                (dateTime) => setState(() => _returnTime = dateTime),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 20),
            label: const Text('SIMPAN WAKTU PULANG'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _returnTime != null ? _updateReturnTime : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime initialDateTime,
    required Function(DateTime) onDateTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDatePickerSection(
                initialDateTime,
                onDateTimeChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePickerSection(
                initialDateTime,
                onDateTimeChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerSection(
    DateTime initialDateTime,
    Function(DateTime) onDateTimeChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDateTime,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            initialDateTime.hour,
            initialDateTime.minute,
          );
          onDateTimeChanged(newDateTime);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(initialDateTime),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerSection(
    DateTime initialDateTime,
    Function(DateTime) onDateTimeChanged,
  ) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDateTime),
        );
        if (time != null) {
          final newDateTime = DateTime(
            initialDateTime.year,
            initialDateTime.month,
            initialDateTime.day,
            time.hour,
            time.minute,
          );
          onDateTimeChanged(newDateTime);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              DateFormat('HH:mm').format(initialDateTime),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToParticipants() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (ctx) => BoatParticipant(
              hostname: widget.hostname,
              eventid: int.parse(widget.event.id),
              title: widget.event.title,
              usertype: widget.usertype,
              userid: widget.userid,
              confirmnum: widget.event.confirmnum,
            ),
      ),
    );
  }
}
