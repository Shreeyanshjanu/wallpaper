import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_service.dart';
import 'providers/media_provider.dart'; // Changed
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://kltaeskfqdmokgvogasf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtsdGFlc2tmcWRtb2tndm9nYXNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNzI0OTQsImV4cCI6MjA3ODk0ODQ5NH0.NYDAhuvZWxV2DM6572FoFmWT70Sseny02vSMnb0nkhc',
  );
  
  ApiService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MediaProvider(), // Changed
      child: MaterialApp(
        title: 'Wallpaper Composer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
