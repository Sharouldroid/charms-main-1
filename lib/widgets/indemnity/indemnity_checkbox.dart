// import 'package:flutter/material.dart';

// class IndemnityCheckbox extends StatefulWidget {
//   const IndemnityCheckbox({
//     super.key,
//     required this.indemitem,
//     required this.index,
//     required this.selectedData,
//     required this.ischecked,
//   });

//   final String indemitem;
//   final int index;
//   final List selectedData;
//   final List ischecked;

//   @override
//   State<IndemnityCheckbox> createState() => _IndemnityCheckboxState();
// }

// class _IndemnityCheckboxState extends State<IndemnityCheckbox> {
//   // List selectedData = [];

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(20),
//           child: Checkbox.adaptive(
//             value: !widget.selectedData.contains(widget.index) ? false : true,
//             onChanged: (value) {
//               if (!widget.selectedData.contains(widget.index)) {
//                 setState(() {
//                   widget.selectedData.add(widget.index);
//                   widget.ischecked.add(widget.index + 1);
//                   // print('${widget.index} checked');
//                 });
//               } else {
//                 setState(() {
//                   widget.selectedData
//                       .removeWhere((element) => element == widget.index);
//                   widget.ischecked
//                       .removeWhere((element) => element == widget.index + 1);
//                 });
//               }
//             },

//             // activeColor: Colors.green,
//             checkColor: Colors.teal,
//             // controlAffinity: ListTileControlAffinity.leading,
//           ),
//         ),
//         Expanded(
//             child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//           child: Text(
//             widget.indemitem,
//             textAlign: TextAlign.justify,
//             style: const TextStyle(fontSize: 18, wordSpacing: 1.5),
//           ),
//         )),
//         const SizedBox(
//           height: 20,
//         ),
//         const Divider(color: Colors.white),
//       ],
//     );
//   }
// }
