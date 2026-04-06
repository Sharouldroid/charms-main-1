import 'package:flutter/material.dart';

class ReportDatepick extends StatefulWidget {
  const ReportDatepick({super.key});

  @override
  State<ReportDatepick> createState() => _ReportDatepickState();
}

class _ReportDatepickState extends State<ReportDatepick> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Search'),
      children: [
        Row(
          children: [
            Text(_startDate != null
                ? '${_startDate!.day}-${_startDate!.month}-${_startDate!.year}'
                : 'Select first date'),
            // Text(
            //   '${_startDate!.day}-${_startDate!.month}-${_startDate!.year}',
            // ),

            const Spacer(),
            IconButton(
              onPressed: () async {
                _startDate = await pickDate();

                if (_startDate == null) return;

                // setState(() => _startDate = _startDate!);
                setState(() {
                  _startDate = _startDate!;
                });
              },
              icon: const Icon(Icons.calendar_month),
            ),
            // const Spacer(),
            // Text(
            //   '${_endDate!.day}-${_endDate!.month}-${_endDate!.year}',
            // ),

            Text(_endDate != null
                ? '${_endDate!.day}-${_endDate!.month}-${_endDate!.year}'
                : 'Select last date'),
            const Spacer(),
            IconButton(
              onPressed: () async {
                _endDate = await pickDate();

                if (_endDate == null) return;

                // setState(() => _endDate = _endDate!);
                setState(() {
                  _endDate = _endDate!;
                });
              },
              icon: const Icon(Icons.calendar_month),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {},
          label: const Text('Search'),
          icon: const Icon(Icons.search),
        )
      ],
    );
  }

  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now());
}
