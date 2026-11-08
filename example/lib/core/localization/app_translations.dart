import 'package:get/get.dart';

import 'translations/ar_sa.dart';
import 'translations/en_us.dart';

/// Central internationalization class for GetX.
///
/// Provides Arabic (`ar_SA`) and English (`en_US`) dictionary mappings.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ar_SA': arSA,
        'en_US': enUS,
      };
}

