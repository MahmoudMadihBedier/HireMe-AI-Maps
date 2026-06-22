import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/utils/app_color.dart';
import '../../../../../core/utils/app_string.dart';
import '../../../../../core/utils/app_text_style.dart';
import '../controllers/auth_login_controller.dart';

class AuthLoginView extends GetView<AuthLoginController> {
  const AuthLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              _buildTitle(),
              const SizedBox(height: 48),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 12),
              _buildRememberForgotRow(),
              const SizedBox(height: 32),
              _buildSignInButton(),
              const SizedBox(height: 32),
              _buildCreateAccountRow(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(AppString.login, style: CustomTextstyle.poppinsBold2),
        const SizedBox(height: 14),
        Text(
          "Welcome back you've\nbeen missed!",
          textAlign: TextAlign.center,
          style: CustomTextstyle.poppinsSemiBold,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _AuthTextField(
      controller: controller.emailController,
      hint: 'Email',
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return Obx(
      () => _AuthTextField(
        controller: controller.passwordController,
        hint: 'Password',
        obscure: controller.obscurePassword.value,
        suffixIcon: GestureDetector(
          onTap: controller.toggleObscure,
          child: Icon(
            controller.obscurePassword.value
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColor.greydark,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(
          () => Row(
            children: [
              GestureDetector(
                onTap: controller.toggleRememberMe,
                child: Icon(
                  controller.rememberMe.value
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: controller.rememberMe.value
                      ? const Color(0xFF8A8A9A)
                      : const Color(0xFF8A8A9A),
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text('Remember me', style: CustomTextstyle.poppins500Grey),
            ],
          ),
        ),
        GestureDetector(
          onTap: controller.onForgotPasswordPressed,
          child: Text('Forgot Password ?', style: CustomTextstyle.poppins500),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.onSignInPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.kblue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  AppString.signin,
                  style: CustomTextstyle.poppinsSemiBoldWhite,
                ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an Account? ",
          style: CustomTextstyle.interRegularBlack,
        ),
        GestureDetector(
          onTap: controller.onCreateAccountPressed,
          child: Text(
            'Create Account',
            style: CustomTextstyle.interRegularBlue,
          ),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF0F3FF),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A3794), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}


