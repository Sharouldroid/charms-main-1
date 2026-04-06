import 'package:charms/image_test_screen.dart';
import 'package:charms/HRproviders/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class CustomDrawer extends StatelessWidget {
  final String selectedLanguage;
  final List<String> languages;
  final void Function(String?) onLanguageChanged;
  final VoidCallback onLogOut;

  const CustomDrawer({
    Key? key,
    required this.selectedLanguage,
    required this.languages,
    required this.onLanguageChanged,
    required this.onLogOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: onLogOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 16),
                    ),
                    child:
                        Text('Log Out', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ImageTestScreen()),
                  );
                },
                child: Text("text image"),
              )
            ],
          ),
        );
      },
    );
  }
}
