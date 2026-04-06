import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/internshipproviders/register_provider.dart';
import 'package:charms/internshipmodels/register.dart';

class InternDetailScreen extends StatelessWidget {
  final int internId;

  const InternDetailScreen({super.key, required this.internId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intern Details'),
      ),
      body: FutureBuilder<Register>(
        future: context.read<RegisterProvider>().getInternDetails(internId),
        builder: (context, snapshot) {
          // Show loading spinner while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if something went wrong
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load intern details: ${snapshot.error}'),
            );
          }

          // Display intern details
          final intern = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${intern.firstName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Age: ${intern.age}'),
                Text('Gender: ${intern.gender}'),
                Text('Phone: ${intern.phoneNumber}'),
                Text('Email: ${intern.email}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Example button for additional functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Additional action!')),
                    );
                  },
                  child: const Text('Perform Action'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
