import 'package:flutter/material.dart';
import '../widgets/textfield.dart';
import '../widgets/phonetextfield.dart';
import '../widgets/logo.dart';
import '../core/theme/app_colors.dart';
import '../widgets/checkbox.dart';
import '../widgets/button.dart';
import '../widgets/email_modal.dart';
import '../widgets/OTP_modal.dart';
import '../widgets/password_modal.dart';
import '../graphql/graphql_service.dart';
import '../graphql/api_service.dart';
import 'package:go_router/go_router.dart';
import '../widgets/loading.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool isSignUp = true; // true = Sign Up, false = Login

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final newPasswordController = TextEditingController();
  final reenterPasswordController = TextEditingController();

  final GraphQLService graphqlService = GraphQLService();

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      LoadingOverlay.show(context);

      await ApiService.sendOtp(email);

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (context) => OtpModal(
          email: email,
          onVerify: () async {
            try {
              await graphqlService.login(email: email, password: password);
              if (!mounted) return;
              context.go("/home");
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
            }
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      LoadingOverlay.hide();
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    try {
      LoadingOverlay.show(context);

      /// 1. SEND OTP
      await ApiService.sendOtp(email);

      if (!context.mounted) return;

      /// 2. SHOW OTP MODAL
      showModalBottomSheet(
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
              );
              if (!mounted) return;

              context.go("/home");
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Register failed: $e")));
            }
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
    reenterPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
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
                            color: isSignUp ? Colors.green : Colors.transparent,
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

            // 🔥 FORM SECTION
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isSignUp) ...[
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
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => EmailModal(
                                emailController: emailController,
                                onContinue: () {
                                  Navigator.pop(context);

                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => OtpModal(
                                      email: emailController.text,
                                      onVerify: () {
                                        Navigator.pop(context);
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => PasswordModal(
                                            newPasswordController:
                                                newPasswordController,
                                            reenterPasswordController:
                                                reenterPasswordController,
                                            onSubmit: () {
                                              final pass =
                                                  newPasswordController.text;
                                              final confirm =
                                                  reenterPasswordController
                                                      .text;

                                              if (pass.isEmpty ||
                                                  confirm.isEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Password cannot be empty",
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              if (pass != confirm) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Passwords do not match",
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              Navigator.pop(context);

                                              print("Password updated: $pass");
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
    );
  }
}
