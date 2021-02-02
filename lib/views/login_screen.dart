import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
//import 'dashboard_screen.dart';

const users = const {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class LoginScreen extends StatelessWidget {
  Duration get loginTime => Duration(milliseconds: 2250);

  Future<String> _authUser(LoginData data) {
    print('Name: ${data.name}, Password: ${data.password}');
    return Future.delayed(loginTime).then((_) {
      // if (!users.containsKey(data.name)) {
      //   return 'Username not exists';
      // }
      // if (users[data.name] != data.password) {
      //   return 'Password does not match';
      // }
      return null;
    });
  }
  Future<String> _onSignUp(LoginData data){
    return Future.delayed(Duration(milliseconds: 100)).then((value){
      return 'done';
    });
  }

  Future<String> _recoverPassword(String name) {
    print('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'Username not exists';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Learn With AR',
      logo: 'assets/logo.png',
      onLogin: _authUser,
      onSignup: _onSignUp,
      onSubmitAnimationCompleted: () {
         Navigator.pushReplacementNamed(context, 'dash');
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
