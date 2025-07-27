import 'package:profanity_filter/profanity_filter.dart';

class ProfanityFilterUtil {
  static final ProfanityFilter _filter = ProfanityFilter();
  
  /// Check if text contains profanity
  static bool hasProfanity(String text) {
    return _filter.hasProfanity(text);
  }
  
  /// Filter profanity from text (replaces with asterisks)
  static String filterProfanity(String text) {
    return _filter.censor(text);
  }
  
  /// Check and filter profanity, returns null if profanity detected
  static String? validateAndFilter(String text) {
    if (hasProfanity(text)) {
      return null; // Return null to indicate profanity was found
    }
    return text; // Return original text if no profanity
  }
  
  /// Get profanity detection message
  static String getProfanityMessage() {
    return 'Your message contains inappropriate language. Please revise and try again.';
  }
} 