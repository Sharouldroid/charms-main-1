// import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
// import 'package:flutter/material.dart';

// class PdfViewer extends StatefulWidget {
//   const PdfViewer({Key? key, required this.fileUrl}) : super(key: key);

//   final String fileUrl;

//   @override
//   State<PdfViewer> createState() => _PdfViewerState();
// }

// class _PdfViewerState extends State<PdfViewer> {
//   PDFDocument? _document;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadDocument();
//   }

//   Future<void> _loadDocument() async {
//     try {
//       PDFDocument document = await PDFDocument.fromURL(widget.fileUrl);
//       setState(() {
//         _document = document;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to load document: $e")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("PDF Viewer"),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _document != null
//               ? PDFViewer(
//                   document: _document!,
//                   lazyLoad: false,
//                   zoomSteps: 1,
//                   numberPickerConfirmWidget: const Text("Confirm"),
//                 )
//               : const Center(
//                   child: Text("Unable to load document"),
//                 ),
//     );
//   }
// }
