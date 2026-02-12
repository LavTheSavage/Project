import 'package:project/main.dart';

Future<bool> isCurrentUserAdmin() async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return false;

  final res = await supabase
      .from('profiles')
      .select('role, is_admin')
      .eq('id', uid)
      .single();

  return res['is_admin'] == true || res['role'] == 'admin';
}
