import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signin.dart';
import 'admin/admin_dashboard.dart';
import 'dept/dept_dashboard.dart';
import 'host/host_dashboard.dart';
import 'receptionist/dashboard.dart';
import 'receptionist/host_passes_page.dart';
import 'receptionist/manual_entry_page.dart';
import 'receptionist/kiosk_qr_page.dart';
import 'receptionist/visitor_tracking_page.dart';
import 'splash_screen.dart';
import 'receptionist/receptionist_reports_page.dart';

void main() async{          
  WidgetsFlutterBinding.ensureInitialized();        
  await Firebase.initializeApp(                     
    options: const FirebaseOptions(                 
      apiKey: 'AIzaSyByxS4j4y-tOx1AbTqxm7kv8zTOj-P1wNc',
      appId: '1:262645349308:android:473868969c622d4ac089b9',
      messagingSenderId: '262645349308',
      projectId: 'visitor-management-d97ea',
    ),
  );
  // Print the Firebase project ID for debugging
  print('FIREBASE PROJECT ID: ' + Firebase.app().options.projectId);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: SplashScreen(),
      routes: {
        '/dashboard': (context) => const ReceptionistDashboard(),
        '/receptionist_dashboard': (context) => const ReceptionistDashboard(),
        '/host_passes': (context) => const HostPassesPage(),
        '/manual_entry': (context) => const ManualEntryPage(),
        '/receptionist_reports': (context) => ReceptionistReportsPage(),
        '/kiosk_qr': (context) => const KioskQRPage(),
        '/visitor_tracking': (context) => const VisitorTrackingPage(),
        '/signin': (context) => const SignInPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                );
              },
              child: const Text('Go to Sign In'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                );
              },
              child: const Text('Go to Admin Dashboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeptDashboard()),
                );
              },
              child: const Text('Go to Department Dashboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HostMainScreen()),
                );
              },
              child: const Text('Go to Host Dashboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/receptionist_dashboard');
              },
              child: const Text('Go to Receptionist Dashboard'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
