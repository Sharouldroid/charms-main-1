// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';

/// Example event class.
class Event2 {
  final String title;
  final DateTime startdate;
  final DateTime enddate;
  final int id;

  const Event2({
    required this.title,
    required this.startdate,
    required this.enddate,
    required this.id,
  });

  // @override
  // String toString() => title;
}

class Event {
  final String id;
  final String title;
  final String startdate;
  final String enddate;
  final String? startdate2;
  final String? enddate2;
  final int? eventtype;
  final int? createdby;
  final int? approve1;
  final int? approve2;
  final int? status;

  Event({
    required this.id,
    required this.title,
    required this.startdate,
    required this.enddate,
    this.startdate2,
    this.enddate2,
    this.eventtype,
    this.createdby,
    this.approve1,
    this.approve2,
    this.status,
  });
}

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
// final kEvents = LinkedHashMap<DateTime, List<Event2>>(
//   equals: isSameDay,
//   hashCode: getHashCode,
// )..addAll(_kEventSource);

// final _kEventSource = {
//   for (var item in List.generate(50, (index) => index))
//     DateTime.utc(kFirstDay.year, kFirstDay.month, item * 5): List.generate(
//         item % 4 + 1,
//         (index) => Event2(
//             title: 'Event $item | ${index + 1}',
//             startdate: DateTime.now(),
//             enddate: DateTime.now(),
//             id: 1))
// }..addAll({
//     kToday: [
//       // const Event2('Today\'s Event 1'),
//       // const Event2('Today\'s Event 2'),
//     ],
//   });

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

// final kToday = DateTime.now();
// final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
// final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
