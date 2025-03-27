import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.pastelWhite,
  fontFamily: 'Pretendard',
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.pastelBlue,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: AppTextStyles.title.copyWith(fontSize: 24.sp),
    iconTheme: const IconThemeData(color: Colors.black87),
  ),
);
