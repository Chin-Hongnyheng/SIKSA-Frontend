import 'package:flutter/material.dart';
import '../widgets/textfield.dart';
import '../widgets/phonetextfield.dart';
import '../widgets/logo.dart';
import '../core/theme/app_colors.dart';
import '../widgets/checkbox.dart';
import '../widgets/button.dart';
import '../modals/email_modal.dart';
import '../modals/OTP_modal.dart';
import '../widgets/password_modal.dart';
import '../graphql/graphql_service.dart';
import '../graphql/api_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/loading.dart';
import '../widgets/center_toast.dart';
import '../widgets/roles.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool isSignUp = true;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final forgetEmailController = TextEditingController();

  final GraphQLService graphqlService = GraphQLService();

  String selectedRole = "Student";

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      await CenterToast.show(
        context,
        message: "Please fill all fields",
        icon: Icons.error,
        color: const Color.fromARGB(255, 68, 62, 62),
      );
      return;
    }

    try {
      LoadingOverlay.show(context);
      await graphqlService.validateLogin(email: email, password: password);
      await ApiService.sendOtp(email);
      LoadingOverlay.hide();
      if (!context.mounted) return;

      bool verified = false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxHeight: double.infinity),
        builder: (bottomSheetContext) => OtpModal(
          email: email,
          onVerify: () async {
            try {
              // 4. Login
              await graphqlService.login(email: email, password: password);
              if (!mounted) return;
              verified = true;
            } catch (e) {
              await CenterToast.show(
                context,
                message: "Login failed: $e",
                icon: Icons.error,
                color: Colors.red,
              );
            }
          },
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));

      if (verified && context.mounted) {
        await CenterToast.show(
          context,
          message: "Login successful",
          icon: Icons.check_circle,
          color: Colors.green,
        );

        context.go('/dashboard');
      }
    } catch (e) {
      LoadingOverlay.hide();
      await CenterToast.show(
        context,
        message: e.toString(),
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> handleForgotPassword() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) => EmailModal(
        emailController: forgetEmailController,
        onContinue: () async {
          final email = forgetEmailController.text.trim();

          if (email.isEmpty) {
            await CenterToast.show(
              context,
              message: "Email is required",
              icon: Icons.error,
              color: Colors.red,
            );
            return;
          }

          try {
            LoadingOverlay.show(context);

            /// send OTP
            await ApiService.sendOtp(email);

            if (!mounted) return;

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              isDismissible: true,
              enableDrag: true,
              useSafeArea: true,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              builder: (context) => OtpModal(
                email: email,
                onVerify: () {
                  /// PASSWORD MODAL (FULL WIDTH)
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    isDismissible: true,
                    enableDrag: true,
                    useSafeArea: true,
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
                    builder: (context) => PasswordModal(
                      newPasswordController: newPasswordController,
                      confirmPasswordController: confirmPasswordController,
                      onSubmit: () async {
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword = confirmPasswordController.text
                            .trim();

                        if (newPassword.isEmpty || confirmPassword.isEmpty) {
                          await CenterToast.show(
                            context,
                            message: "Password cannot be empty",
                            icon: Icons.error,
                            color: Colors.red,
                          );
                          return;
                        }

                        if (newPassword != confirmPassword) {
                          await CenterToast.show(
                            context,
                            message: "Password do not match",
                            icon: Icons.error,
                            color: Colors.red,
                          );
                          return;
                        }

                        try {
                          LoadingOverlay.show(context);

                          await graphqlService.forget(
                            email: email,
                            newPassword: newPassword,
                            confirm: confirmPassword,
                          );

                          Navigator.pop(context); // close password modal
                          Navigator.pop(context); // close OTP modal

                          await CenterToast.show(
                            context,
                            message: "Password updated successfully",
                            icon: Icons.check_circle,
                            color: Colors.green,
                          );
                        } catch (e) {
                          await CenterToast.show(
                            context,
                            message: e.toString(),
                            icon: Icons.error,
                            color: Colors.red,
                          );
                        } finally {
                          LoadingOverlay.hide();
                        }
                      },
                    ),
                  );
                },
              ),
            );
          } catch (e) {
            await CenterToast.show(
              context,
              message: e.toString(),
              icon: Icons.error,
              color: Colors.red,
            );
          } finally {
            LoadingOverlay.hide();
          }
        },
      ),
    );
  }

  Future<void> handleRegister() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    // VALIDATION
    if (username.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      await CenterToast.show(
        context,
        message: "Please fill all fields",
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    if (password != confirm) {
      await CenterToast.show(
        context,
        message: "Password do not match",
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    try {
      LoadingOverlay.show(context);

      /// Validate first
      await graphqlService.validate(
        userName: username,
        email: email,
        phone: phone,
        password: password,
        confirm: confirm,
      );

      /// SEND OTP
      await ApiService.sendOtp(email);

      LoadingOverlay.hide();
      if (!context.mounted) return;

      bool registered = false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        constraints: BoxConstraints(maxWidth: double.infinity),
        builder: (modalcontext) => OtpModal(
          email: email,
          onVerify: () async {
            try {
              await graphqlService.register(
                userName: username,
                email: email,
                phone: phone,
                password: password,
                confirm: confirm,
                role: selectedRole,
              );
              if (!mounted) return;
              registered = true;
            } catch (e) {
              await CenterToast.show(
                context,
                message: "Register failed: $e",
                icon: Icons.error,
                color: Colors.red,
              );
            }
          },
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (registered && context.mounted) {
        await CenterToast.show(
          context,
          message: "Register successful",
          icon: Icons.check_circle,
          color: Colors.green,
        );

        context.go('/profile');
      }
    } catch (e) {
      await CenterToast.show(
        context,
        message: e.toString(),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      LoadingOverlay.hide();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Center(child: LogoApp()),
              const SizedBox(height: 20),
              Text(
                "Welcome",
                style: TextStyle(color: AppColors.primary, fontSize: 28),
              ),
              const SizedBox(height: 5),
              Text(
                "Login or Sign Up to access our features",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),
              // SWITCH (Toggle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      // SIGN UP
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isSignUp = true;

                              usernameController.clear();
                              emailController.clear();
                              phoneController.clear();
                              passwordController.clear();
                              confirmController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSignUp
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: isSignUp ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // LOGIN
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isSignUp = false;

                              emailController.clear();
                              passwordController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isSignUp
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: !isSignUp ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isSignUp) ...[
                        RoleSelector(
                          selectedRole: selectedRole,
                          onChanged: (userRole) {
                            setState(() {
                              selectedRole = userRole;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: usernameController,
                          label: "Username",
                          hint: "Enter your username",
                          secure: false,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: emailController,
                          label: "Email",
                          hint: "Enter your email",
                          secure: false,
                          icon: Icons.mail,
                        ),
                        const SizedBox(height: 16),

                        PhoneTextField(controller: phoneController),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: passwordController,
                          label: "Password",
                          hint: "Enter password",
                          secure: true,
                          showToggle: true,
                          icon: Icons.lock,
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: confirmController,
                          label: "Confirm Password",
                          hint: "Confirm password",
                          secure: true,
                          showToggle: true,
                          icon: Icons.lock,
                        ),
                        const SizedBox(height: 5),

                        AppCheckbox(
                          text: "I have accepted the terms and conditions",
                        ),
                        const SizedBox(height: 16),
                        AppButton(text: "SIGN UP", onPressed: handleRegister),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "Or",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                                  height: 22,
                                ),

                                const SizedBox(width: 12),

                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),
                      ] else ...[
                        // 🔥 LOGIN UI
                        AppTextField(
                          controller: emailController,
                          label: "Email",
                          hint: "Enter your email",
                          secure: false,
                          icon: Icons.mail,
                        ),
                        const SizedBox(height: 16),

                        AppTextField(
                          controller: passwordController,
                          label: "Password",
                          hint: "Enter your password",
                          secure: true,
                          showToggle: true,
                          icon: Icons.lock,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: handleForgotPassword,
                            child: const Text("Forgot Password?"),
                          ),
                        ),

                        AppButton(text: "LOG IN", onPressed: handleLogin),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "Or",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                                  height: 22,
                                ),

                                const SizedBox(width: 12),

                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
