import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constant.dart';

const DEVANSH_IP = '192.168.1.3'; // Replace with your actual IP address

class LoginScreen extends StatelessWidget {
  Future<void> handleLogin(String userType, String email, String password,
      BuildContext context) async {
    final response = await http.post(
      Uri.parse(
          '${Constants.DEVANSH_IP}/api/auth/${userType == "player" ? "loginuser" : "loginadmin"}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', responseData['authtoken']);

      // Navigate based on user type
      if (userType == "player") {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      }
    } else {
      throw Exception('Failed to login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Swiper(
        itemCount: 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return PlayerLogin(
              handleLogin: (email, password) {
                handleLogin("player", email, password, context);
              },
              handleRegister: () {
                Navigator.pushNamed(context, '/registration');
              },
              handleForgotPassword: () {
                Navigator.pushNamed(context, '/forgotPassword');
              },
            );
          } else {
            return OwnerLogin(
              handleLogin: (email, password) {
                handleLogin("owner", email, password, context);
              },
              handleRegister: () {
                Navigator.pushNamed(context, '/registration');
              },
              handleForgotPassword: () {
                Navigator.pushNamed(context, '/forgotPassword');
              },
            );
          }
        },
        pagination: SwiperPagination(),
        control: SwiperControl(),
      ),
    );
  }
}

class MovingLogo extends StatefulWidget {
  final double logoSize;

  MovingLogo({this.logoSize = 50.0});

  @override
  _MovingLogoState createState() => _MovingLogoState();
}

class _MovingLogoState extends State<MovingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              _animation.value * MediaQuery.of(context).size.width * 0.1, 0),
          child: child,
        );
      },
      child: Container(
        width: widget.logoSize,
        height: widget.logoSize,
        child: Image.asset('assets/login.png'),
      ),
    );
  }
}

class PlayerLogin extends StatefulWidget {
  final Function(String, String) handleLogin;
  final VoidCallback handleRegister;
  final VoidCallback handleForgotPassword;

  PlayerLogin(
      {required this.handleLogin,
      required this.handleRegister,
      required this.handleForgotPassword});

  @override
  _PlayerLoginState createState() => _PlayerLoginState();
}

class _PlayerLoginState extends State<PlayerLogin> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool showPassword = false;

  void handleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MovingLogo(),
          SizedBox(height: 30),
          Text(
            "TURFIT",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            "Player Login",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: handleShowPassword,
              ),
            ),
            obscureText: !showPassword,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.handleLogin(
                emailController.text, passwordController.text),
            child: Text("Login"),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: widget.handleForgotPassword,
            child: Text("Forgot Password?"),
          ),
          TextButton(
            onPressed: widget.handleRegister,
            child: Text("Don't have an account? Register"),
          ),
        ],
      ),
    );
  }
}

class OwnerLogin extends StatefulWidget {
  final Function(String, String) handleLogin;
  final VoidCallback handleRegister;
  final VoidCallback handleForgotPassword;

  OwnerLogin(
      {required this.handleLogin,
      required this.handleRegister,
      required this.handleForgotPassword});

  @override
  _OwnerLoginState createState() => _OwnerLoginState();
}

class _OwnerLoginState extends State<OwnerLogin> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool showPassword = false;

  void handleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MovingLogo(),
          SizedBox(height: 30),
          Text(
            "TURFIT",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            "Owner Login",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                  icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: handleShowPassword),
            ),
            obscureText: !showPassword,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.handleLogin(
                emailController.text, passwordController.text),
            child: Text("Login"),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: widget.handleForgotPassword,
            child: Text("Forgot Password?"),
          ),
          TextButton(
            onPressed: widget.handleRegister,
            child: Text("Don't have an account? Register"),
          ),
        ],
      ),
    );
  }
}
