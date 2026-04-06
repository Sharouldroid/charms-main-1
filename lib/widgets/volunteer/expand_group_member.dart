import 'package:charms/providers/indemnities.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpandGroupMember extends StatelessWidget {
  const ExpandGroupMember({
    super.key,
    required this.name,
    required this.idnum,
    required this.email,
    required this.booktype,
    required this.hostname,
    required this.confirmnum,
    required this.shirtsize,
  });

  final String name;
  final String idnum;
  final String email;
  final int booktype;
  final String hostname;
  final int confirmnum;
  final String shirtsize;

  // --- NEW: Helper function to split the logic ---
  Future<Map<String, dynamic>> _checkMemberStatus(BuildContext context) async {
    final provider = Provider.of<Indemnitites>(context, listen: false);

    // Step 1: Check if User exists in UserLogin table
    bool isRegistered = await provider.checkUserRegistration(hostname, email);
    
    if (!isRegistered) {
      return {'status': 'not_registered'};
    }

    // Step 2: If registered, check if Indemnity is accepted
    bool hasIndemnity = await provider.checkIndemnityStatus(hostname, email, confirmnum);
    
    if (hasIndemnity) {
      return {'status': 'accepted'};
    } else {
      return {'status': 'incomplete'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        isThreeLine: true,
        title: Text(name),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Number: $idnum'),
            Text('Email: $email'),
            Text('T-Shirt Size: $shirtsize'),
            const SizedBox(height: 5), // Add small spacing
            
            FutureBuilder<Map<String, dynamic>>(
              future: _checkMemberStatus(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  );
                } 
                
                if (snapshot.hasError) {
                   return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }

                final status = snapshot.data?['status'];

                if (status == 'not_registered') {
                  return const Text(
                    'Error: User is not registered to CHARMS',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.bold
                    ),
                  );
                } else if (status == 'accepted') {
                  return const Text(
                    'Indemnity Accepted',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.bold
                    ),
                  );
                } else {
                  // status == 'incomplete'
                  return const Text(
                    'Indemnity Incomplete',
                    style: TextStyle(
                      color: Colors.orange, // Changed to Orange to differentiate from error
                      fontSize: 15,
                      fontWeight: FontWeight.bold
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}