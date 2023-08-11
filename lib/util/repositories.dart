import 'dart:io';

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/UI/payment_history.dart';
import 'package:kcs_engineer/model/general_code.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/jobGeneralCodes.dart';
import 'package:kcs_engineer/model/job_order_seq.dart';
import 'package:kcs_engineer/model/payment_method.dart';
import 'package:kcs_engineer/model/payment_status.dart';
import 'package:kcs_engineer/model/solution.dart';
import 'package:kcs_engineer/model/payment_history_item.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/model/sparepart_history_item.dart';
import 'package:kcs_engineer/model/user_sparepart.dart';
import 'package:kcs_engineer/model/user.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:kcs_engineer/util/key.dart';

class Repositories {
  Future<bool> _handleSignIn(String email, String password) async {
    final Map<String, dynamic> map = {
      'email': email,
      'password': password,
    };

    final response = await Api.bearerPost('login', params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");

    if (response["success"] != null) {
      await storage.write(key: TOKEN, value: response['data']?['token']);
      return true;
    } else {
      return false;
    }
  }

  // _registerOnFirebase() async {
  //   FirebaseMessaging _fcm = FirebaseMessaging.instance;

  //   var userStorage = await storage.read(key: USER);
  //   User userJson = User.fromJson(jsonDecode(userStorage!));
  //   var email = userJson.email?.toLowerCase();

  //   if (email != null) {
  //     _fcm.subscribeToTopic('all');
  //     _fcm.getToken().then((value) async => {
  //           value.toString(),
  //           await handleNewRegistrationToken(
  //               value.toString(), email.toString()),
  //         });
  //   }
  // }

  handleNewRegistrationToken(String token, String email) async {
    final Map<String, dynamic> map = {
      'email': email,
      'token': token,
      'device_id': 'deviceID',
      'platform': Platform.isAndroid ? 'Android' : 'iOS'
    };
    var baseUrl = FlutterConfig.get("API_URL");

    var response = await http.post(
        Uri.parse((baseUrl ?? "https://cm.khind.com.my") +
            "/provider/fcm/register.php"),
        body: map,
        headers: null);

    var g = response.toString();
  }

  static Future<bool> handleLogout() async {
    final response = await Api.bearerPost('logout');
    print("#Resp: ${jsonEncode(response)}");

    if (response["success"] != null) {
      Helpers.isAuthenticated = false;
      await storage.write(key: TOKEN, value: "");
      return true;
    } else {
      return false;
    }
  }

  _fetchJobs() async {
    User? user;
    if (Helpers.loggedInUser != null) {
      user = Helpers.loggedInUser;
    }

    final response = await Api.bearerGet('job-orders/with-relationship');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] != null) {
      if (user == null) {
        user = new User();
      }

      user!.allJobsCount = response["meta"]?["allJobsCount"];
      user!.completedJobsCount = response["meta"]?["completedJobsCount"];
      user!.uncompletedJobsCount = response["meta"]?["uncompletedJobsCount"];

      // var fetchedJobs =
      //     (response['data'] as List).map((i) => Job.fromJson(i)).toList();

      // setState(() {
      //   jobs = fetchedJobs;
      //   Helpers.loggedInUser = user;
      // });
    } else {
      //show ERROR
    }
  }

  static Future<Job?> fetchJobDetails({required int? jobId}) async {
    final response = await Api.bearerGet('job-orders/$jobId');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      Job job = Job.selectedJobFromJson(response);
      var spareParts =
          (response['data']!['relationships']!['engineer_order_transaction']
                  as List)
              .map((i) => JobSparePart.fromJson(i))
              .toList();

      var generalCodes = (response['data']?["relationships"]
              ?['general_code_transaction'] as List)
          .map((i) => JobGeneralCode.fromJson(i))
          .toList();

      Helpers.editableGeneralCodes = generalCodes;

      num sumSubTotal = response['meta']!['realSubTotal'] ?? 0.0;
      num sumDiscount = response['meta']!['taxTotal'] ?? 0.0;
      num sumTotal = response['meta']!['grandTotal'] ?? 0.0;

      job.jobSpareParts = spareParts;
      job.generalCodes = generalCodes;
      job.sumSubTotal = sumSubTotal;
      job.sumDiscount = sumDiscount;
      job.sumTotal = sumTotal;

      Helpers.editableJobSpareParts = spareParts;

      return job;
    } else {
      return null;
    }
  }

  //DONE
  static Future<bool> updateJobOrderSequence(
      List<JobOrderSequence> orderSeq) async {
    final Map<String, dynamic> map = {'job_orders': orderSeq};

    final response = await Api.bearerPost('job-orders/update-sequence',
        params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  //DONE
  static Future<bool> addSparePartsToJob(
      int jobId, List<SparePart> spareparts) async {
    List<Map<String, dynamic>> mapList = [];

    spareparts.forEach((element) {
      Map<String, dynamic> e = {
        'spareparts_id': element.sparepartsId,
        'quantity_taken': element.quantity,
        'discount': element.discount
      };

      mapList.add(e);
    });

    final Map<String, dynamic> map = {'job_id': jobId, 'spareparts': mapList};

    final response = await Api.bearerPost('bag-job', params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addGeneralCodeToJob(
      int jobId, List<GeneralCode> generalCodes) async {
    //var userId = await storage.read(key: USERID);

    List<Map<String, dynamic>> mapList = [];

    generalCodes.forEach((element) {
      Map<String, dynamic> e = {
        'general_code_id': element.generalCodeId,
        'data': {'price': double.parse(element.price ?? "0")}
      };

      mapList.add(e);
    });

    final Map<String, dynamic> map = {'general_code_data': mapList};

    final response =
        await Api.bearerPost('job-general/$jobId', params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> deleteGeneralCodeFromJob(int transactionId) async {
    final response = await Api.bearerPost('job-general/delete/$transactionId');
    print("#Resp: ${jsonEncode(response)}");
    if (response != "") {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateGeneralCodes(
      int jobId, List<JobGeneralCode> generalCodes) async {
    //var userId = await storage.read(key: USERID);

    List<Map<String, dynamic>> mapList = [];

    generalCodes.forEach((element) {
      Map<String, dynamic> e = {
        'general_code_transaction_id': element.generalCodeTransactonId,
        'general_code_id': element.generalCodeId,
        'data': {'price': double.parse(element.price ?? "0")}
      };

      mapList.add(e);
    });

    final Map<String, dynamic> map = {'general_code_data': mapList};

    final response =
        await Api.bearerPost('job-general/$jobId', params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  //DONE
  static Future<bool> updateSerialNo(int jobId, String serialNo) async {
    final Map<String, dynamic> map = {'serial_no': serialNo};

    final response = await Api.bearerPost('job-orders/$jobId/update-serial',
        params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  //DONE
  static Future<bool> updateRemarks(int jobId, String remarks) async {
    final Map<String, dynamic> map = {'remarks': remarks};

    final response = await Api.bearerPost('job-orders/$jobId/update-remarks',
        params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  //DONE
  static Future<bool> toggleChargable(int jobId) async {
    final response =
        await Api.bearerPost('job-orders/$jobId/toggle-chargerable');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateSolutionOfJob(int jobId, int solutionId) async {
    final Map<String, dynamic> map = {
      'solution_id': solutionId == 0 ? null : solutionId
    };
    final response = await Api.bearerPost('job-orders/$jobId/update-solution',
        params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  //DONE
  static Future<bool> cancelJob(int jobId) async {
    final response = await Api.bearerPost('job-orders/$jobId/job-cancel');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> startJob(List<File> images, int jobId) async {
    var url = Uri.parse(
        'https://mc.mayer.sg:8080/api/v1/job-orders/$jobId/job-start');
    return await sendMultipartReq(images, url);
  }

  static Future<bool> completeJob(List<File> images, int jobId) async {
    var url = Uri.parse(
        'https://mc.mayer.sg:8080/api/v1/job-orders/$jobId/job-complete');
    return await sendMultipartReq(images, url);
  }

  static Future<bool> uploadKIV(List<File> images, int jobId) async {
    var url =
        Uri.parse('https://mc.mayer.sg:8080/api/v1/job-orders/$jobId/job-kiv');
    return await sendMultipartReq(images, url);
  }

  static Future<bool> sendMultipartReq(List<File> images, Uri url) async {
    var token = await storage.read(key: TOKEN);

    var headers = {
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
      'Authorization': 'Bearer $token'
    };

    var request = http.MultipartRequest('POST', url);
    List<http.MultipartFile> multipartFiles = [];

    for (var file in images) {
      List<int> fileBytes = await file.readAsBytes();
      http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'image[]',
        fileBytes,
        filename: file.path.split('/').last,
      );
      multipartFiles.add(multipartFile);
    }

    request.files.addAll(multipartFiles);

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<Solution>> fetchSolutions() async {
    final response = await Api.bearerGet('solutions');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      var solutions =
          (response['data'] as List).map((i) => Solution.fromJson(i)).toList();
      return solutions;
    } else {
      return [];
    }
  }

  static Future<PaymentHistoryItem?> fetchPaymentHistory(
      String startDate, String endDate) async {
    var url = 'payment/history' +
        (startDate != "" ? '?$startDate' : "") +
        (endDate != "" ? '?$endDate' : "");
    final response = await Api.bearerGet(url);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      var paymentHistories = PaymentHistoryItem.fromJson(response);
      return paymentHistories;
    } else {
      return null;
    }
  }

  static Future<List<String>> fetchPaymentMethodLabels() async {
    final response = await Api.bearerGet('payment-methods');
    List<String> pmLabels = [];
    if (response["success"] != null) {
      var paymentMethods = (response['data'] as List)
          .map((i) => (PaymentMethod.fromJson(i).description ?? "ERROR"))
          .toList();
      return paymentMethods;
    } else {
      return [];
    }
  }

 
  static Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final response = await Api.bearerGet('payment-methods');
    List<String> pmLabels = [];
    if (response["success"] != null) {
      var paymentMethods = (response['data'] as List)
          .map((i) => (PaymentMethod.fromJson(i)))
          .toList();
      return paymentMethods;
    } else {
      return [];
    }
  }

  //POST RATING
  static Future<bool> processPayment(
      int jobId,
      File image,
      bool isMailInvoice,
      String mailEmail,
      double amount,
      String currency,
      List<Map<String, dynamic>>? paymentTransactions) async {
    var token = await storage.read(key: TOKEN);

    var url = Uri.parse(
        'https://mc.mayer.sg:8080/api/v1/job-orders/$jobId/job-payment');

    var headers = {
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
      'Authorization': 'Bearer $token'
    };
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    request.headers.addAll(headers);
    request.fields['mail_invoice'] = isMailInvoice ? "true" : "false";
    request.fields['amount'] = amount.toStringAsFixed(2);
    request.fields['currency'] = "SGD";
    paymentTransactions != null
        ? request.fields['payment_transaction'] =
            json.encode(paymentTransactions)
        : {};
    (mailEmail != "" && isMailInvoice)
        ? request.fields['mailing_email'] = mailEmail
        : {};

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      return true;
    } else {
      print(response.reasonPhrase);
      return false;
    }
  }

  //JOBcOPLETE upload SIGNATURE
  static Future<bool> postRating(
      int jobId, List<int> categories, int ratingScore, String comment) async {
    final Map<String, dynamic> map = {
      'rating_category_id': categories,
      'rating_score': ratingScore,
      'comments': comment
    };

    final response = await Api.bearerPost('job-orders/$jobId/submit-rating',
        params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }
}
