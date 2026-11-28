import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';

class SpokenStrings {
  const SpokenStrings._();

  static String stepOfTotal(int step, int total, GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'படி $step / $total';
      case GuideLanguage.hindi:
        return 'चरण $step / $total';
      case GuideLanguage.tanglish:
        return 'Step $step / $total';
      case GuideLanguage.english:
        return 'Step $step of $total';
    }
  }

  static String firstStep(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'இது முதல் படி.';
      case GuideLanguage.hindi:        return 'यह पहला चरण है।';
      case GuideLanguage.tanglish:
        return 'Idhu mudhal step.';
      case GuideLanguage.english:
        return 'This is the first step.';
    }
  }

  static String lastStep(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'இது கடைசி படி. சமையல் முடியப்போகிறது.';
      case GuideLanguage.hindi:
        return 'यह अंतिम चरण है। आपकी डिश लगभग तैयार है।';
      case GuideLanguage.tanglish:
        return 'Idhu last step. Dish ready aaga pogudhu.';
      case GuideLanguage.english:
        return 'This is the last step. Almost done!';
    }
  }

  static String paused(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'சமையல் வழிகாட்டி இடைநிறுத்தப்பட்டது.';
      case GuideLanguage.hindi:
        return 'कुकिंग गाइड रोक दिया गया है।';
      case GuideLanguage.tanglish:
        return 'Guide pause panniyaachu.';
      case GuideLanguage.english:
        return 'Cooking guide paused.';
    }
  }

  static String resumed(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'தொடர்கிறது.';
      case GuideLanguage.hindi:
        return 'आगे बढ़ रहे हैं।';
      case GuideLanguage.tanglish:
        return 'Thodarurom.';
      case GuideLanguage.english:
        return 'Resuming.';
    }
  }

  static String startedOver(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'முதலில் இருந்து ஆரம்பிக்கலாம்.';
      case GuideLanguage.hindi:
        return 'शुरुआत से दोबारा शुरू कर रहे हैं।';
      case GuideLanguage.tanglish:
        return 'First-la irundhu start pannalam.';
      case GuideLanguage.english:
        return 'Starting over from step one.';
    }
  }

  static String timerStarted(int minutes, GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return '$minutes நிமிட டைமர் துவங்கியது.';
      case GuideLanguage.hindi:
        return '$minutes मिनट का टाइमर शुरू हो गया है।';
      case GuideLanguage.tanglish:
        return '$minutes minutes timer start aayiduchu.';
      case GuideLanguage.english:
        return 'Timer started for $minutes minute${minutes == 1 ? '' : 's'}.';
    }
  }

  static String timerStopped(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'டைமர் நிறுத்தப்பட்டது.';
      case GuideLanguage.hindi:
        return 'टाइमर रोक दिया गया है।';
      case GuideLanguage.tanglish:
        return 'Timer stop panniyaachu.';
      case GuideLanguage.english:
        return 'Timer stopped.';
    }
  }

  static String timerDone(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'டைமர் முடிந்தது! அடுத்த படிக்கு செல்லலாம்.';
      case GuideLanguage.hindi:
        return 'समय समाप्त! आप अगले चरण पर जा सकते हैं।';
      case GuideLanguage.tanglish:
        return 'Timer mudinjiruchu! Adutha step-ku polaam.';
      case GuideLanguage.english:
        return 'Time is up! You can proceed to the next step.';
    }
  }

  static String cookingCompleted(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'வாழ்த்துகள்! சமையல் வெற்றிகரமாக முடிந்தது!';
      case GuideLanguage.hindi:
        return 'बधाई हो! आपकी रेसिपी पूरी हो गई है।';
      case GuideLanguage.tanglish:
        return 'Super! Samayal mudinjiruchu!';
      case GuideLanguage.english:
        return 'Congratulations! Cooking completed!';
    }
  }

  static String noTipAvailable(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'இந்த படிக்கு கூடுதல் குறிப்புகள் இல்லை.';
      case GuideLanguage.hindi:
        return 'इस चरण के लिए कोई विशेष टिप उपलब्ध नहीं है।';
      case GuideLanguage.tanglish:
        return 'Indha step-ku tips edhuvum illa.';
      case GuideLanguage.english:
        return 'No specific tip available for this step.';
    }
  }

  static String ingredientQuantity(String name, String quantity, GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return '$name தேவைப்படும் அளவு: $quantity.';
      case GuideLanguage.hindi:
        return '$name की मात्रा: $quantity.';
      case GuideLanguage.tanglish:
        return '$name thevaipadum alavu: $quantity.';
      case GuideLanguage.english:
        return 'You need $quantity of $name.';
    }
  }

  static String ingredientNotFound(String name, GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return '$name இந்த செய்முறையில் காணப்படவில்லை.';
      case GuideLanguage.hindi:
        return '$name इस रेसिपी में नहीं मिला।';
      case GuideLanguage.tanglish:
        return '$name indha recipe-la illa.';
      case GuideLanguage.english:
        return '$name is not found in this recipe.';
    }
  }

  static String foodSafetyDisclaimer(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'குறிப்பு: சமைப்பதற்கு முன் உணவு பாதுகாப்பாக உள்ளதா என்று உங்கள் உணர்வுகளைக் கொண்டு சரிபார்க்கவும்.';
      case GuideLanguage.hindi:
        return 'सूचना: पकाने से पहले हमेशा सामग्री की गुणवत्ता और सुरक्षा खुद जांचें।';
      case GuideLanguage.tanglish:
        return 'Note: Samakkuradhukku munnadi ingredients nallaa irukaa-nu check pannikonga.';
      case GuideLanguage.english:
        return 'Reminder: Always inspect ingredients for quality and safety before cooking.';
    }
  }
}
