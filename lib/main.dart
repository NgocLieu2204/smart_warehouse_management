// lib/main.dart (ĐÃ SỬA LỖI)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import 'firebase_options.dart';
import 'blocs/product/product_bloc.dart';
import 'repositories/product_repository.dart';
import 'repositories/auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/product/product_event.dart';
import 'views/auth/login_screen.dart';
// Thay đổi import từ dashboard cũ sang màn hình chính mới
import 'views/main/main_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Giữ nguyên phần khởi tạo backend của bạn
    final authRepository = AuthRepository();
    final productRepo = ProductRepository(
      Dio(BaseOptions(
        baseUrl: "http://10.0.2.2:5000",
      )),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(productRepo)..add(LoadProducts()),
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const colorPrimary = Color(0xFF00BFFF);
    const colorAccent = Color(0xFFFFD700);
    const colorDarkBg = Color(0xFF121212);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: colorPrimary,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: const ColorScheme.light(
        primary: colorPrimary,
        secondary: colorAccent,
        background: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: Colors.black,
        onSurface: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 1,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // SỬA LỖI: Sử dụng CardThemeData thay vì CardTheme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: colorPrimary,
      scaffoldBackgroundColor: colorDarkBg,
      colorScheme: const ColorScheme.dark(
        primary: colorPrimary,
        secondary: colorAccent,
        background: colorDarkBg,
        surface: Color(0xFF1E1E1E),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorDarkBg.withOpacity(0.8),
        elevation: 1,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // SỬA LỖI: Sử dụng CardThemeData thay vì CardTheme
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Warehouse',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          // Khi đăng nhập thành công, chuyển đến MainScreen mới
          return const MainScreen();
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}