import 'package:flutter/material.dart';

import '../../business_logic/supabase_authentication.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.auth, required super.child});
  final SupabaseAuthentication auth;
  static SupabaseAuthentication? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.auth;
  @override
  bool updateShouldNotify(AuthScope oldWidget) => oldWidget.auth != auth;
}
