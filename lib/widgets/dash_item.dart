import 'package:flutter/material.dart';

class DashItem extends StatelessWidget {
  const DashItem({
    super.key,
    required this.image,
    required this.widgetname,
    required this.title,
  });

  final String image;
  final Widget widgetname;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          title: Text(title),
        ),
        child: widgetname,
      ),
    );
  }
}
