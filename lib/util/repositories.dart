import 'dart:io';

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/model/checklistAttachment.dart';
import 'package:kcs_engineer/model/comment.dart';
import 'package:kcs_engineer/model/engineer.dart';
import 'package:kcs_engineer/model/general_code.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/jobGeneralCodes.dart';
import 'package:kcs_engineer/model/job_filter_options.dart';
import 'package:kcs_engineer/model/job_order_seq.dart';
import 'package:kcs_engineer/model/payment_method.dart';
import 'package:kcs_engineer/model/problem.dart';
import 'package:kcs_engineer/model/solution.dart';
import 'package:kcs_engineer/model/payment_history_item.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/model/user_sparepart.dart';
import 'package:kcs_engineer/model/user.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import 'package:http_parser/http_parser.dart';

import 'package:kcs_engineer/util/key.dart';

class Repositories {
  static Future<dynamic> handleSignIn(String email, String password) async {
    final Map<String, dynamic> map = {
      'identifier': email,
      'password': password,
    };

    final response = await Api.bearerPost('auth/login', params: map);
    print("#Resp: ${jsonEncode(response)}");

    if (response["success"]) {
      var dateTimeFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSSSS'Z'")
          .parse(response?['data']?['token']?['expires_at']);
      await storage.write(
          key: TOKEN, value: response?['data']?['token']?['token']);
      await storage.write(
          key: TOKEN_EXPIRY,
          value: dateTimeFormat.millisecondsSinceEpoch.toString());
      await storage.write(
          key: REFRESH_TOKEN,
          value: response['data']?['refresh_token']?['token']);
      await storage.write(
          key: USERID, value: response['data']?['user']?['user_id']);
    }
    return response;
  }

  static Future<bool> handleLogout() async {
    final response = await Api.bearerPost('auth/logout');
    print("#Resp: ${jsonEncode(response)}");

    if (response["success"] != null) {
      Helpers.isAuthenticated = false;
      await storage.delete(key: TOKEN);
      await storage.delete(key: TOKEN_EXPIRY);
      await storage.delete(key: REFRESH_TOKEN);
      await storage.delete(key: USERID);
      return true;
    } else {
      return false;
    }
  }

  static Future<String> renewAccessToken() async {
    final response = await Api.bearerPost('auth/refresh-token');
    print("#Resp: ${jsonEncode(response)}");

    if (response["success"]) {
      Helpers.isAuthenticated = false;
      var dateTimeFormat = DateFormat('MMMM d, yyyy', 'en_US')
          .parse(response?['data']?['token']?['expires_at']);

      await storage.write(
          key: TOKEN, value: response?['data']?['token']?['token']);
      await storage.write(
          key: TOKEN_EXPIRY,
          value: dateTimeFormat.millisecondsSinceEpoch.toString());

      return response?['data']?['token']?['token'];
    } else {
      Helpers.isAuthenticated = false;
      await storage.delete(key: TOKEN);
      await storage.delete(key: TOKEN_EXPIRY);
      await storage.delete(key: REFRESH_TOKEN);
      await storage.delete(key: USERID);
      return "unauthenticated";
    }
  }

  static Future<Engineer?> fetchProfile() async {
    Engineer? user = null;
    final response = await Api.bearerGet('auth/profile');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      user = Engineer.fromJson(response["data"]);
    }
    return user;
  }

  static Future<String> updateProfilePicuture(String picture) async {
    String path = 'user/upload-profile-image';
    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";

    String url = '${baseUrl}/${path}';

    Uri uri = Uri.parse(url);

    File pictureFile = File(picture);

    var request = http.MultipartRequest('POST', uri);

    if (pictureFile != "") {
      var mimeType = lookupMimeType(picture); // 'image/jpeg'

      request.files.add(
        await http.MultipartFile.fromBytes(
            'attachment',
            Platform.isIOS
                ? (await rootBundle.load(picture)).buffer.asUint8List()
                : File(picture).readAsBytesSync(),
            contentType: new MediaType(mimeType?.split('/')[0] ?? 'application',
                mimeType?.split('/')[1] ?? "jpg"),
            filename: picture.split("/").last),
      );
    }

    var userToken = await storage.read(key: TOKEN);
    request.headers["Authorization"] = "Bearer ${userToken}";

    http.StreamedResponse response = await request.send();
    var res = await response.stream.bytesToString();
    var jsonObj = json.decode(res);
    if (response.statusCode == 200) {}

    if (jsonObj["success"]) {
      return "success";
    } else {
      return "error";
    }
  }

  static Future<JobData?> fetchJobs(filters) async {
    JobData? data;

    final response = await Api.bearerPost('job/service-jobs', params: filters);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      data = await JobData.selectedJobFromJson(response);
    }
    return data;
  }

  static Future<JobFilterOptions?> fetchJobStatus() async {
    JobFilterOptions? data;

    final response = await Api.bearerGet('general/job-list-filter-options');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      data = await JobFilterOptions.fromJson(response);
    }
    return data;
  }

  static Future<JobData?> fetchOrderStatuses() async {
    JobData? data;

    final response = await Api.bearerGet('job/service-jobs');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      data = await JobData.selectedJobFromJson(response);
    }
    return data;
  }

  static Future<List<Comment>> fetchOrderComments(String salesOrderId) async {
    List<Comment>? data = [];

    final response = await Api.bearerGet('job/comments/' + salesOrderId);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      data =
          (response['data'] as List).map((i) => Comment.fromJson(i)).toList();
    }
    return data;
  }

  static Future<bool> addComment(String salesOrdefId, String content) async {
    var data = {"content": content, "sales_order_id": salesOrdefId};

    final response =
        await Api.bearerPost('job/comments/create', params: jsonEncode(data));
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      return true;
    }
    return false;
  }

  static Future<bool> updateComment(int commentId, String content) async {
    var data = {"remarks": content, "cust_remarks_id": commentId};

    final response =
        await Api.bearerPost('job/comments/update', params: jsonEncode(data));
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      return true;
    }
    return false;
  }

  static Future<bool> deleteComment(int commentId) async {
    var data = {"cust_remarks_id": commentId};

    final response =
        await Api.bearerPost('job/comments/delete', params: jsonEncode(data));
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      return true;
    }
    return false;
  }

  static Future<List<ChecklistAttachment>> fetchChecklistAttachment(
      String salesOrderId) async {
    List<ChecklistAttachment>? data = [];

    final response = await Api.bearerGet(
        'job/checklist/' + salesOrderId + '/question-answers');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      data = (response['data'] as List)
          .map((i) => ChecklistAttachment.fromJson(i))
          .toList();
    }
    return data;
  }

  static Future<Job?> fetchJobDetails({required String? jobId}) async {
    final response = await Api.bearerGet('job-orders/$jobId');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      Job? job = null;
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
      String jobId, List<SparePart> spareparts) async {
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
      String jobId, List<GeneralCode> generalCodes) async {
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
      String jobId, List<JobGeneralCode> generalCodes) async {
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
  static Future<bool> updateSerialNo(String jobId, String serialNo) async {
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
  static Future<bool> updateRemarks(String jobId, String remarks) async {
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
  static Future<bool> toggleChargable(String jobId) async {
    final response =
        await Api.bearerPost('job-orders/$jobId/toggle-chargerable');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateSolutionOfJob(String jobId, int solutionId) async {
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
  static Future<bool> cancelJob(String jobId) async {
    final response = await Api.bearerPost('job-orders/$jobId/job-cancel');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> startJob(List<File> images, String jobId) async {
    var url =
        Uri.parse('https://mc.mayer.sg/api/v1/job-orders/$jobId/job-start');
    return await sendMultipartReq(images, url);
  }

  static Future<bool> completeJob(List<File> images, String jobId) async {
    var url =
        Uri.parse('https://mc.mayer.sg/api/v1/job-orders/$jobId/job-complete');
    return await sendMultipartReq(images, url);
  }

  static Future<bool> uploadKIV(List<File> images, String jobId) async {
    var url = Uri.parse('https://mc.mayer.sg/api/v1/job-orders/$jobId/job-kiv');
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
    final response = await Api.bearerGet('general/solutions');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      var solutions =
          (response['data'] as List).map((i) => Solution.fromJson(i)).toList();
      return solutions;
    } else {
      return [];
    }
  }

  static Future<List<Problem>> fetchProblems() async {
    final response = await Api.bearerGet('general/problems');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      var problems =
          (response['data'] as List).map((i) => Problem.fromJson(i)).toList();
      return problems;
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
      String jobId,
      File image,
      bool isMailInvoice,
      String mailEmail,
      double amount,
      String currency,
      List<Map<String, dynamic>>? paymentTransactions) async {
    var token = await storage.read(key: TOKEN);

    var url =
        Uri.parse('https://mc.mayer.sg/api/v1/job-orders/$jobId/job-payment');

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
  static Future<bool> postRating(String jobId, List<int> categories,
      int ratingScore, String comment) async {
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
