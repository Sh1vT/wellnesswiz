
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current selected page index in the global scaffold.
final pageNavigationProvider = StateProvider<int>((ref) => 0); 