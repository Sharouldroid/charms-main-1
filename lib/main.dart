// ------------------------
// ORIGINAL CHARMS IMPORTS
// ------------------------
import 'package:charms/models/booking_cart.dart';
import 'package:charms/models/groupmembers.dart';
import 'package:charms/models/optionalitem_cart.dart';
import 'package:charms/models/specialbooking_cart.dart';
import 'package:charms/providers/auth.dart' as app_auth;
import 'package:charms/providers/boats.dart';
import 'package:charms/providers/bookevents.dart';
import 'package:charms/providers/bookingsettings.dart';
import 'package:charms/providers/event_groups.dart';
import 'package:charms/providers/events.dart';
import 'package:charms/providers/events_daytrip.dart';
import 'package:charms/providers/events_kpp.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:charms/providers/events_special.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:charms/providers/optionalitems.dart';
import 'package:charms/providers/receipts.dart';
import 'package:charms/providers/reports.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/providers/surveys.dart';
import 'package:charms/providers/users.dart'as charms_users;
import 'package:charms/screens/auth_screen.dart';
import 'package:charms/screens/dashboard_screen.dart'; // CHARMS Dashboard
import 'package:charms/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

// ------------------------
// 🌟 INTERNSHIP MODULE IMPORTS
// ------------------------
import 'package:charms/internshipproviders/register_provider.dart';
import 'package:charms/internshipproviders/schedule_provider.dart';
import 'package:charms/internshipproviders/assessment_provider.dart';
import 'package:charms/internshipscreens/dashboard_screen.dart' as internship_screens;

// ------------------------
// 🌟 HR MODULE IMPORTS (ADDED)
// ------------------------
import 'package:charms/camera_service.dart';
import 'package:charms/HRproviders/auth.dart' as hr_auth;
import 'package:charms/HRproviders/attendances.dart';
import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRproviders/schedules.dart' as hr_schedules; // Alias to avoid conflict
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRproviders/theme_provider.dart';
import 'package:charms/HRproviders/users.dart' as hr_users;
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';

// 🌟 ADDED CHARMS MAINTENANCE PAGES
import 'campsite_maintenance.dart';
import 'maintenance_page.dart';
import 'kitchen_maintenance.dart';
import 'outdoorclassroom_maintenance.dart';
import 'quarters_maintenance.dart';
import 'watersportarea_maintenance.dart';
import 'safety_page.dart';
import 'backpacking_page.dart';
import 'firstaid_page.dart';
import 'incidentreporting_page.dart';
import 'otherfacility_page.dart';
import 'office_maintenance.dart';
import 'surau_maintenance.dart';
import 'transactionhistory_page.dart';
import 'ReplacementItemsPage.dart';
import 'landscape_page.dart';
import 'others_maintenance.dart';
import 'water_quality_page.dart';
import 'package:charms/list_bahan_page.dart'; // Add this

// 🌟 NEW IMPORT
import 'app_startup.dart'; 

// app_config.dart
class AppConfig {
  static String hostname = 'https://devcms.com.my/charmsAPI';
}

// 🌟 HR MODULE: Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ------------------------------------
// MAIN FUNCTION (UPDATED)
// ------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🌟 HR MODULE: Initialize Camera
  await CameraService.initialize();

  runApp(const MyApp());
}

// --------------------------------------------------------
// MyApp Class
// --------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --------------------------------
        // CHARMS PROVIDERS
        // --------------------------------
        ChangeNotifierProvider<app_auth.Auth>(create: (_) => app_auth.Auth()),
        ChangeNotifierProvider<hr_auth.Auth>(create: (_) => hr_auth.Auth()),
        ChangeNotifierProvider<charms_users.Users>(create: (_) => charms_users.Users()),
        ChangeNotifierProvider<hr_users.Users>(create: (_) => hr_users.Users()),
        ChangeNotifierProvider(create: (_) => Events()),
        ChangeNotifierProvider(create: (_) => ResearcherEvents()),
        ChangeNotifierProvider(create: (_) => EventsSpecial()),
        ChangeNotifierProvider(create: (_) => EventsKPP()),
        ChangeNotifierProvider(create: (_) => EventsDaytrip()),
        ChangeNotifierProvider(create: (_) => EventGroups()),
        ChangeNotifierProvider(create: (_) => Indemnitites()),
        ChangeNotifierProvider(create: (_) => BookEvents()),
        ChangeNotifierProvider(create: (_) => BookingSettings()),
        ChangeNotifierProvider(create: (_) => StripeService()),
        ChangeNotifierProvider(create: (_) => Boats()),
        ChangeNotifierProvider(create: (_) => Optionalitems()),
        ChangeNotifierProvider(create: (_) => BookingCartOut()),
        ChangeNotifierProvider(create: (_) => SpecialBookingCartOut()),
        ChangeNotifierProvider(create: (_) => OptionalItemCartOut()),
        ChangeNotifierProvider(create: (_) => GroupMembersOut()),
        ChangeNotifierProvider(create: (_) => Receipts()),
        ChangeNotifierProvider(create: (_) => Surveys()),
        ChangeNotifierProvider(create: (_) => Reports()),
//test
        // --------------------------------
        // 🌟 INTERNSHIP MODULE PROVIDERS
        // --------------------------------
        ChangeNotifierProvider(create: (context) => RegisterProvider()),
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
        ChangeNotifierProvider(create: (context) => AssessmentProvider()),

        // --------------------------------
        // 🌟 HR MODULE PROVIDERS (ADDED)
        // --------------------------------
        ChangeNotifierProvider(create: (ctx) => Staffs()),
        ChangeNotifierProvider(create: (ctx) => hr_schedules.Schedules()), // Uses alias
        ChangeNotifierProvider(create: (ctx) => Payments()),
        ChangeNotifierProvider(create: (ctx) => Attendances()),
        ChangeNotifierProvider(create: (ctx) => Leaves()),
        ChangeNotifierProvider(create: (ctx) => Claims()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
      ],

      child: OverlaySupport.global(
        child: Consumer<app_auth.Auth>(
          builder: (ctx, auth, _) => MaterialApp(
            navigatorKey: navigatorKey, // 🌟 HR MODULE: Add Navigator Key
            title: 'charms',
            debugShowCheckedModeBanner: false,
            
            // Note: Retaining Charms Theme. 
            // If you want HR Dark Mode, you need to wrap MaterialApp in Consumer<ThemeProvider>
            theme: ThemeData.light().copyWith(
              colorScheme: const ColorScheme(
                brightness: Brightness.light,
                primary: Color.fromARGB(255, 86, 127, 215),
                onPrimary: Colors.white,
                secondary: Color(0xFFDA291C),
                onSecondary: Colors.white,
                surface: Color(0xFFF2F2F2),
                onSurface: Colors.black,
                error: Colors.red,
                onError: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color.fromARGB(255, 255, 0, 55),
                foregroundColor: Colors.white,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFDA291C),
                foregroundColor: Colors.white,
              ),
            ),

            // 🌟 MERGED HOME LOGIC
            home: auth.isAuth
                ? _getDashboardForUser(auth.usertype, auth.username, auth.userId, auth.hostname)
                : FutureBuilder(
                    future: AppStartup.initialize(auth),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SplashScreen();
                      }
                      if (auth.isAuth) {
                         return _getDashboardForUser(auth.usertype, auth.username, auth.userId, auth.hostname);
                      }
                      return const AuthScreen();
                    },
                  ),

            routes: {
              DashboardScreen.routeName: (_) => DashboardScreen(
                    userid: auth.userId ?? 0,
                    usertype: auth.usertype,
                    hostname: auth.hostname,
                  ),
              // ... Existing Charms Routes ...
              '/maintenance': (context) => const MaintenancePage(),
              '/transactionhistory': (context) => const TransactionHistoryPage(),

             '/campsite': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    // Handle gracefully – maybe redirect to login or show an error
    return const AuthScreen(); // Or a placeholder
  }
  return CampsitePage(userId: auth.userId!);
},
'/kitchen': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen();
  }
  return const KitchenPage();

},'/quarters': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    // If somehow userId is null, redirect to auth
    return const AuthScreen();
  }
  return const QuartersPage(); // QuartersPage uses Provider internally
},             

'/outdoorclassroom': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen();
  }
  return const OutdoorClassroomPage();

},'/watersportarea': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen();
  }
  return const WaterSportAreaPage();
},           
   '/safety': (context) => const SafetyPage(),

'/firstaid': (context) {
 final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen(); // or handle appropriately
  }
  return FirstAidPage(userId: auth.userId!);
},            

'/backpacking': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen(); // or handle appropriately
  }
  return BackpackingPage(userId: auth.userId!);
},          

'/incident': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen();
  }
  return IncidentReportingPage(userId: auth.userId!);   // <-- added userId
},

              '/facilities': (context) => const OtherFacilityPage(),

'/office': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    // If userId is null, redirect to auth screen (or show an error)
    return const AuthScreen();
  }
  return OfficePage(userId: auth.userId!);
},

'/balaisafsurau': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen();
  }
  return SurauPage(userId: auth.userId!);
},        

'/landscape': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen(); // or handle appropriately
  }
  return LandscapePage(userId: auth.userId!);
},
'/replacementitems': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen(); // or handle appropriately
  }
  return ReplacementItemsPage(userId: auth.userId!);
},       

'/others_maintenance': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen();
  }
  return OthersMaintenancePage(userId: auth.userId!);
},
            
'/water_quality': (context) {
  final auth = Provider.of<app_auth.Auth>(context, listen: false);
  if (auth.userId == null) {
    return const AuthScreen(); // or handle appropriately
  }
  return WaterQualityPage(userId: auth.userId!);
},

              '/list-bahan': (context) => const ListBahanPage(),
                     
              // 🌟 INTERNSHIP ROUTES
              '/internship': (context) => const UserSelectionScreen(), 
            },
          ),
        ),
      ),
    );
  }

  // 🌟 HELPER FUNCTION TO SELECT DASHBOARD
 Widget _getDashboardForUser(int userType, String? username, int? userId, String hostname) {
  // HR Admin
  if (userType == 6) {
    return AdminDashboard(username: username ?? 'Admin');
  }
  // HR Staff only (usertype 7) – assuming 7 is HR staff
  else if (userType == 7) {
    return StaffDashboardScreen(username: username ?? 'Staff');
  }
  // All other types (including 8,9,10, and CHARMS roles 1-5) go to CHARMS dashboard
  return DashboardScreen(
    userid: userId ?? 0,
    usertype: userType,
    hostname: hostname,
  );
}
}

// --------------------------------------------------------
// 🌟 INTERNSHIP MODULE: UserSelectionScreen
// --------------------------------------------------------
class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const internship_screens.DashboardScreen(
                      username: 'Lutfil Haziq',
                      role: 'Admin',
                      profilePicture: 'assets/profilepicture.png',
                      userId: 1, 
                    ),
                  ),
                );
              },
              child: const Text('Login as Admin'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const internship_screens.DashboardScreen(
                      username: 'Lutfil Haziq',
                      role: 'Intern',
                      profilePicture: 'assets/profilepicture.png',
                      userId: 1, 
                    ),
                  ),
                );
              },
              child: const Text('Login as Intern'),
            ),
          ],
        ),
      ),
    );
  }
}