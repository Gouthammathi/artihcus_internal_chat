import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      print('SupabaseConfig: Loading .env file...');
      // Load environment variables
      await dotenv.load(fileName: ".env");
      
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      print('SupabaseConfig: SUPABASE_URL = ${supabaseUrl ?? "NOT SET"}');
      print('SupabaseConfig: SUPABASE_ANON_KEY = ${supabaseAnonKey != null ? "SET (${supabaseAnonKey.length} chars)" : "NOT SET"}');

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Supabase credentials not found in .env file. Please check your .env file.');
      }

      if (supabaseUrl == 'your_supabase_project_url_here' || 
          supabaseAnonKey == 'your_supabase_anon_key_here') {
        throw Exception('Please update .env file with your actual Supabase credentials');
      }

      print('SupabaseConfig: Initializing Supabase...');
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      print('SupabaseConfig: Supabase initialized successfully!');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Supabase: $e');
      }
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}

