import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. إدارة حفظ وقراءة الباسورد
class AppPasswordsService {
  static const String globalSummaryKey = 'global_summary_password';
  static const String stockKey = 'stock_password';
  static const String deleteCostKey = 'delete_cost_password'; // مفتاح باسورد مسح الكوست
  static const String defaultPassword = '1234'; // الباسورد الافتراضي أول مرة

  static Future<String> getPassword(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String? pass = prefs.getString(key);
    if (pass == null) {
      await prefs.setString(key, defaultPassword);
      return defaultPassword;
    }
    return pass;
  }

  static Future<void> updatePassword(String key, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, newPassword);
  }

  static Future<bool> verifyPassword(String key, String inputPassword) async {
    String currentPass = await getPassword(key);
    return currentPass == inputPassword;
  }
}

// 2. دالة التحقق من الباسورد كـ Dialog وترجع true إذا الباسورد صحيح
Future<bool> promptPasswordDialog({
  required BuildContext context,
  required String passwordKey,
  required String title,
}) async {
  TextEditingController controller = TextEditingController();
  bool isCorrect = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('دخول بكلمة سر لـ $title', textAlign: TextAlign.right),
      content: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          labelText: 'أدخل الباسورد',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            isCorrect = false;
            Navigator.pop(context);
          },
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            bool isValid = await AppPasswordsService.verifyPassword(
              passwordKey,
              controller.text,
            );
            if (isValid) {
              isCorrect = true;
              if (context.mounted) Navigator.pop(context);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الباسورد غير صحيح!')),
              );
            }
          },
          child: const Text('دخول'),
        ),
      ],
    ),
  );

  return isCorrect;
}

// 3. نافذة عامة للتحقق من الباسورد قبل فتح أي شاشة جديدة
void checkPasswordAndNavigate({
  required BuildContext context,
  required String passwordKey,
  required Widget destinationScreen,
}) {
  TextEditingController controller = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('دخول بكلمة سر', textAlign: TextAlign.right),
      content: TextField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          labelText: 'أدخل الباسورد',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            bool isValid = await AppPasswordsService.verifyPassword(
              passwordKey,
              controller.text,
            );
            if (isValid && context.mounted) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destinationScreen),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الباسورد غير صحيح!')),
              );
            }
          },
          child: const Text('دخول'),
        ),
      ],
    ),
  );
}

// 4. نافذة تغيير أي باسورد
void showChangePasswordDialog({
  required BuildContext context,
  required String passwordKey,
  required String title,
}) {
  TextEditingController oldPass = TextEditingController();
  TextEditingController newPass = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('تغيير باسورد $title', textAlign: TextAlign.right),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: oldPass,
            obscureText: true,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'الباسورد الحالي'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newPass,
            obscureText: true,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'الباسورد الجديد'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            bool isValid = await AppPasswordsService.verifyPassword(
              passwordKey,
              oldPass.text,
            );
            if (isValid && newPass.text.trim().isNotEmpty) {
              await AppPasswordsService.updatePassword(
                passwordKey,
                newPass.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تغيير الباسورد بنجاح!')),
                );
              }
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الباسورد الحالي غير صحيح!')),
              );
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}