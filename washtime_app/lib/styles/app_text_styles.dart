// 📁 styles/app_text_styles.dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final title = TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold);
  static final subtitle =
      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600);
  static final body = TextStyle(fontSize: 16.sp, color: Colors.black87);
  static final caption = TextStyle(fontSize: 14.sp, color: AppColors.textGray);
  static final button = TextStyle(
      fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white);
}
