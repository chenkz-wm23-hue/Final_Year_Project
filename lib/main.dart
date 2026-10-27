import 'package:flutter/material.dart';

import 'app.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/database/supabase_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<Supabase> initialization;
  Future<Supabase> initialize() => SupabaseDatabase.connect();
  @override
  void initState() {
    super.initState();
    initialization = initialize();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Supabase>(
    future: initialization,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return SmartExpenseApp(client: snapshot.data!.client);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to initialize the app.'),
                      FilledButton(
                        onPressed: () =>
                            setState(() => initialization = initialize()),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
