import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kcs_engineer/UI/feedback.dart';
import 'package:kcs_engineer/UI/feedback_confirmation.dart';
import 'package:kcs_engineer/UI/payment.dart';
import 'package:kcs_engineer/UI/job-details/job_details.dart';
import 'package:kcs_engineer/UI/payment_history.dart';
import 'package:kcs_engineer/UI/side_menu.dart';
import 'package:kcs_engineer/UI/signature.dart';
import 'package:kcs_engineer/UI/signin.dart';
import 'package:kcs_engineer/UI/splashScreen.dart';
import 'package:kcs_engineer/UI/warehouse.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/payment_method.dart';
import 'package:kcs_engineer/model/payment/payment_request.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';

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
      case 'payment':
        return MaterialPageRoute(
            builder: (_) => Payment(
                data: (arguments as List<dynamic>)[0] as Job,
                paymentDTO: (arguments as List<dynamic>)[1] as PaymentDTO,
                rcpCost: (arguments as List<dynamic>)[2] as RCPCost,
                signature: (arguments as List<dynamic>)[3] as File,
                isWantInvoice: (arguments as List<dynamic>)[4] as bool,
                payByCash: (arguments as List<dynamic>)[5] as bool,
                email: (arguments as List<dynamic>)[6] as String,
                paymentMethods:
                    (arguments as List<dynamic>)[7] as List<PaymentMethod>));
      case 'signature':
        return MaterialPageRoute(
            builder: (_) => SignatureUI(
                data: (arguments as List<dynamic>)[0] as Job,
                rcpCost: (arguments as List<dynamic>)[1] as RCPCost));
      case 'payment_history':
        return MaterialPageRoute(builder: (_) => PaymentHistory());
      case 'feedback':
        return MaterialPageRoute(
            builder: (_) => FeedbackUI(
                data: (arguments as List<dynamic>)[0] as Job,
                paymentDTO: (arguments as List<dynamic>)[1] as PaymentDTO));
      case 'feedback_confirmation':
        return MaterialPageRoute(
            builder: (_) => FeedBackConfirmation(
                data: arguments != null ? arguments as Job : null));
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
