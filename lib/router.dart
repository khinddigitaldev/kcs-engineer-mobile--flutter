import 'package:flutter/material.dart';
import 'package:kcs_engineer/UI/feedback.dart';
import 'package:kcs_engineer/UI/feedback_confirmation.dart';
import 'package:kcs_engineer/UI/payment.dart';
import 'package:kcs_engineer/UI/job_details.dart';
import 'package:kcs_engineer/UI/payment_history.dart';
import 'package:kcs_engineer/UI/side_menu.dart';
import 'package:kcs_engineer/UI/signature.dart';
import 'package:kcs_engineer/UI/signin.dart';
import 'package:kcs_engineer/UI/splashScreen.dart';
import 'package:kcs_engineer/UI/warehouse.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/payment_request.dart';

class AppRouter {
  static const String initialRoute = "/";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case 'home':
        return MaterialPageRoute(builder: (_) => MyHomePage());
      case 'jobDetails':
        return MaterialPageRoute(
            builder: (_) => JobDetails(id: arguments as String));
      case 'warehouse':
        return MaterialPageRoute(
            builder: (_) => Warehouse(jobId: arguments as String));
      case 'signIn':
        return MaterialPageRoute(builder: (_) => SignIn());
      // case 'payment':
      //   return MaterialPageRoute(
      //       builder: (_) => Payment(
      //           data: (arguments as List<dynamic>)[0] as Job,
      //           paymentDTO: (arguments as List<dynamic>)[1] as PaymentDTO));
      // case 'signature':
      //   return MaterialPageRoute(
      //       builder: (_) => SignatureUI(data: arguments as Job));
      case 'payment_history':
        return MaterialPageRoute(builder: (_) => PaymentHistory());
      // case 'feedback':
      //   return MaterialPageRoute(
      //       builder: (_) => FeedbackUI(
      //           data: (arguments as List<dynamic>)[0] as Job,
      //           paymentDTO: (arguments as List<dynamic>)[1] as PaymentDTO));
      case 'feedback_confirmation':
        return MaterialPageRoute(
            builder: (_) => FeedBackConfirmation(data: arguments as Job));
      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}'))));
    }
  }

  static MaterialPageRoute<dynamic> invalidArgument() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('invalid arguments'),
        ),
      ),
    );
  }
}
