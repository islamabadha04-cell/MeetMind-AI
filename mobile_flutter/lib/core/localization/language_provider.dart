import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  urdu,
  romanUrdu,
}

class AppStrings {
  static const Map<String, Map<AppLanguage, String>> _strings = {
    // Navigation
    'app_name': {
      AppLanguage.english: 'MeetMind AI',
      AppLanguage.urdu: 'میٹ مائنڈ اے آئی',
      AppLanguage.romanUrdu: 'MeetMind AI',
    },
    'nav_home': {
      AppLanguage.english: 'Home',
      AppLanguage.urdu: 'ہوم',
      AppLanguage.romanUrdu: 'Home',
    },
    'nav_meetings': {
      AppLanguage.english: 'Meetings',
      AppLanguage.urdu: 'میٹنگز',
      AppLanguage.romanUrdu: 'Meetings',
    },
    'nav_record': {
      AppLanguage.english: 'Record',
      AppLanguage.urdu: 'ریکارڈنگ',
      AppLanguage.romanUrdu: 'Recording',
    },
    'nav_ask_ai': {
      AppLanguage.english: 'Ask AI',
      AppLanguage.urdu: 'اے آئی چیٹ',
      AppLanguage.romanUrdu: 'Ask AI',
    },
    'nav_tasks': {
      AppLanguage.english: 'Tasks',
      AppLanguage.urdu: 'ٹاسکس',
      AppLanguage.romanUrdu: 'Tasks',
    },
    'nav_memory': {
      AppLanguage.english: 'Meeting Memory',
      AppLanguage.urdu: 'میٹنگ میموری',
      AppLanguage.romanUrdu: 'Meeting Memory',
    },
    'nav_search': {
      AppLanguage.english: 'AI Search',
      AppLanguage.urdu: 'اے آئی سرچ',
      AppLanguage.romanUrdu: 'AI Search',
    },
    'nav_calendar': {
      AppLanguage.english: 'Calendar',
      AppLanguage.urdu: 'کیلنڈر',
      AppLanguage.romanUrdu: 'Calendar',
    },
    'nav_kb': {
      AppLanguage.english: 'Knowledge Base',
      AppLanguage.urdu: 'نالج بیس',
      AppLanguage.romanUrdu: 'Knowledge Base',
    },
    'nav_workspaces': {
      AppLanguage.english: 'Workspaces',
      AppLanguage.urdu: 'ورک سپیس',
      AppLanguage.romanUrdu: 'Workspaces',
    },
    'nav_integrations': {
      AppLanguage.english: 'Integrations',
      AppLanguage.urdu: 'انٹیگریشنز',
      AppLanguage.romanUrdu: 'Integrations',
    },
    'nav_settings': {
      AppLanguage.english: 'Settings',
      AppLanguage.urdu: 'سیٹنگز',
      AppLanguage.romanUrdu: 'Settings',
    },

    // Dashboard & Greetings
    'greeting_subtitle': {
      AppLanguage.english: 'Your meetings, organized intelligently.',
      AppLanguage.urdu: 'آپ کی میٹنگز، خودکار اور منظم انداز میں۔',
      AppLanguage.romanUrdu: 'Aapki meetings, organized aur smart tareeqay se.',
    },
    'hero_record_title': {
      AppLanguage.english: 'Capture Meeting Audio',
      AppLanguage.urdu: 'میٹنگ کی آڈیو ریکارڈ کریں',
      AppLanguage.romanUrdu: 'Meeting ki audio record karein',
    },
    'hero_record_desc': {
      AppLanguage.english:
          'Offline-ready audio vault with live speech transcription and AI summaries.',
      AppLanguage.urdu: 'آف لائن والٹ، فوری ٹرانسکرپشن اور خودکار اے آئی سمری۔',
      AppLanguage.romanUrdu:
          'Offline audio vault, live transcription aur AI summary.',
    },
    'btn_start_recording': {
      AppLanguage.english: 'Start Live Recording',
      AppLanguage.urdu: 'ریکارڈنگ شروع کریں',
      AppLanguage.romanUrdu: 'Recording shuru karein',
    },
    'stat_meetings': {
      AppLanguage.english: 'Meetings',
      AppLanguage.urdu: 'کل میٹنگز',
      AppLanguage.romanUrdu: 'Kul Meetings',
    },
    'stat_tasks': {
      AppLanguage.english: 'Action Items',
      AppLanguage.urdu: 'ایکشن آئٹمز',
      AppLanguage.romanUrdu: 'Action Items',
    },
    'stat_minutes': {
      AppLanguage.english: 'Minutes',
      AppLanguage.urdu: 'منٹ ریکارڈڈ',
      AppLanguage.romanUrdu: 'Minutes',
    },
    'stat_vault': {
      AppLanguage.english: 'Vault Synced',
      AppLanguage.urdu: 'والٹ سنک',
      AppLanguage.romanUrdu: 'Vault Synced',
    },

    // Meeting Details
    'tab_summary': {
      AppLanguage.english: 'Summary',
      AppLanguage.urdu: 'خلاصہ (سمری)',
      AppLanguage.romanUrdu: 'Summary',
    },
    'tab_transcript': {
      AppLanguage.english: 'Transcript',
      AppLanguage.urdu: 'مکالمہ (ٹرانسکرپٹ)',
      AppLanguage.romanUrdu: 'Transcript',
    },
    'tab_decisions': {
      AppLanguage.english: 'Key Decisions',
      AppLanguage.urdu: 'اہم فیصلے',
      AppLanguage.romanUrdu: 'Key Decisions',
    },
    'tab_actions': {
      AppLanguage.english: 'Action Items',
      AppLanguage.urdu: 'تفویض کردہ کام',
      AppLanguage.romanUrdu: 'Action Items',
    },
    'btn_export_pdf': {
      AppLanguage.english: 'Export MoM PDF',
      AppLanguage.urdu: 'پی ڈی ایف منٹس ڈاؤن لوڈ کریں',
      AppLanguage.romanUrdu: 'MoM PDF Export Karein',
    },
    'btn_share': {
      AppLanguage.english: 'Share Minutes',
      AppLanguage.urdu: 'منٹس شیئر کریں',
      AppLanguage.romanUrdu: 'Share Karein',
    },

    // Recording Studio & Offline Vault
    'recording_active': {
      AppLanguage.english: 'Recording in Progress...',
      AppLanguage.urdu: 'آڈیو ریکارڈنگ جاری ہے...',
      AppLanguage.romanUrdu: 'Recording jari hai...',
    },
    'recording_paused': {
      AppLanguage.english: 'Recording Paused',
      AppLanguage.urdu: 'ریکارڈنگ روک دی گئی ہے',
      AppLanguage.romanUrdu: 'Recording roki hui hai',
    },
    'btn_pause': {
      AppLanguage.english: 'Pause',
      AppLanguage.urdu: 'وقفہ',
      AppLanguage.romanUrdu: 'Pause',
    },
    'btn_resume': {
      AppLanguage.english: 'Resume',
      AppLanguage.urdu: 'دوبارہ شروع',
      AppLanguage.romanUrdu: 'Resume',
    },
    'btn_stop_save': {
      AppLanguage.english: 'Stop & Save to Vault',
      AppLanguage.urdu: 'مکمل کریں اور والٹ میں محفوظ کریں',
      AppLanguage.romanUrdu: 'Stop karein aur Vault mein save karein',
    },
    'btn_bookmark': {
      AppLanguage.english: 'Bookmark Moment',
      AppLanguage.urdu: 'اہم لمحہ نشان زد کریں',
      AppLanguage.romanUrdu: 'Bookmark Moment',
    },
    'vault_title': {
      AppLanguage.english: 'Offline Audio Vault',
      AppLanguage.urdu: 'آف لائن آڈیو والٹ',
      AppLanguage.romanUrdu: 'Offline Audio Vault',
    },
    'status_local_only': {
      AppLanguage.english: 'Local Only',
      AppLanguage.urdu: 'صرف ڈیوائس پر محفوظ',
      AppLanguage.romanUrdu: 'Local Only',
    },
    'status_waiting_conn': {
      AppLanguage.english: 'Waiting for Connection',
      AppLanguage.urdu: 'انٹرنیٹ کا انتظار ہے',
      AppLanguage.romanUrdu: 'Waiting for Connection',
    },
    'status_uploading': {
      AppLanguage.english: 'Uploading to Cloud...',
      AppLanguage.urdu: 'کلاؤڈ پر اپ لوڈ جاری ہے...',
      AppLanguage.romanUrdu: 'Uploading to Cloud...',
    },
    'status_synced': {
      AppLanguage.english: 'Synced with Cloud',
      AppLanguage.urdu: 'کلاؤڈ سے سنک شدہ',
      AppLanguage.romanUrdu: 'Synced with Cloud',
    },
    'status_failed': {
      AppLanguage.english: 'Upload Failed — Retry Required',
      AppLanguage.urdu: 'اپ لوڈ ناکام — دوبارہ کوشش درکار ہے',
      AppLanguage.romanUrdu: 'Upload Failed — Retry Required',
    },

    // Auth & Profile
    'login_title': {
      AppLanguage.english: 'Sign In to MeetMind AI',
      AppLanguage.urdu: 'میٹ مائنڈ میں لاگ ان کریں',
      AppLanguage.romanUrdu: 'MeetMind mein Log In karein',
    },
    'btn_login': {
      AppLanguage.english: 'Sign In',
      AppLanguage.urdu: 'لاگ ان',
      AppLanguage.romanUrdu: 'Sign In',
    },
    'btn_google_signin': {
      AppLanguage.english: 'Continue with Google',
      AppLanguage.urdu: 'گوگل کے ساتھ جاری رکھیں',
      AppLanguage.romanUrdu: 'Google ke sath continue karein',
    },
    'auth_or_divider': {
      AppLanguage.english: 'OR CONTINUE WITH',
      AppLanguage.urdu: 'یا اس کے ساتھ جاری رکھیں',
      AppLanguage.romanUrdu: 'Ya phir continue karein',
    },
    'btn_demo_guest': {
      AppLanguage.english: 'Continue as Guest Reviewer',
      AppLanguage.urdu: 'بطور مہمان جائزہ کار جاری رکھیں',
      AppLanguage.romanUrdu: 'Guest Reviewer ke taur par continue karein',
    },
    'btn_logout': {
      AppLanguage.english: 'Sign Out',
      AppLanguage.urdu: 'لاگ آؤٹ',
      AppLanguage.romanUrdu: 'Sign Out',
    },
  };

  static String get(String key, AppLanguage lang) {
    if (_strings.containsKey(key)) {
      return _strings[key]?[lang] ?? _strings[key]?[AppLanguage.english] ?? key;
    }
    return key;
  }
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('meetmind_mobile_lang');
      if (saved == 'urdu') {
        state = AppLanguage.urdu;
      } else if (saved == 'romanUrdu') {
        state = AppLanguage.romanUrdu;
      } else {
        state = AppLanguage.english;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      String code = 'english';
      if (language == AppLanguage.urdu) code = 'urdu';
      if (language == AppLanguage.romanUrdu) code = 'romanUrdu';
      await prefs.setString('meetmind_mobile_lang', code);
    } catch (_) {}
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});
