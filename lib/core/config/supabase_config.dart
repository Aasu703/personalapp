import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client singleton. Replace the placeholder URL and anon key with your real project values.
final supabase = SupabaseClient(
  'https://YOUR_SUPABASE_PROJECT.supabase.co',
  'YOUR_PUBLIC_ANON_KEY',
);
