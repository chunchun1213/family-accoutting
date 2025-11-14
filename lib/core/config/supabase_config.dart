import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static late final SupabaseClient _instance;

  /// Initialize Supabase client with environment variables
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load(fileName: 'lib/core/config/.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'Missing Supabase credentials. Please check .env file for SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _instance = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    return _instance;
  }

  /// Get the current user
  static User? get currentUser {
    return _instance.auth.currentUser;
  }

  /// Get the current session
  static Session? get currentSession {
    return _instance.auth.currentSession;
  }
}
