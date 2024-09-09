import 'dart:io';

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/model/acknowledgement/payment_history.dart';
import 'package:kcs_engineer/model/user/bag.dart';
import 'package:kcs_engineer/model/job/checklistAttachment.dart';
import 'package:kcs_engineer/model/job/comment.dart';
import 'package:kcs_engineer/model/user/engineer.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/job/filters/job_filter_options.dart';
import 'package:kcs_engineer/model/job/job_order_seq.dart';
import 'package:kcs_engineer/model/spareparts/miscellaneousItem.dart';
import 'package:kcs_engineer/model/payment/paymentCollection.dart';
import 'package:kcs_engineer/model/payment/payment_method.dart';
import 'package:kcs_engineer/model/spareparts/pick_list_Items.dart';
import 'package:kcs_engineer/model/payment/pickup_charges.dart';
import 'package:kcs_engineer/model/job/general/problem.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';
import 'package:kcs_engineer/model/job/general/reason.dart';
import 'package:kcs_engineer/model/job/general/solution.dart';
import 'package:kcs_engineer/model/payment/payment_history_item.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/model/job/general/transportCharge.dart';
import 'package:kcs_engineer/model/util/app_version.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import 'package:http_parser/http_parser.dart';

import 'package:kcs_engineer/util/key.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    Map<String, dynamic> map = {"logout_all_devices": false};
    final response = await Api.bearerPost('auth/logout', params: map);
    print("#Resp: ${jsonEncode(response)}");

    if (response["success"] != null && response["success"]) {
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

  // static Future<String> renewAccessToken() async {
  //   final response = await Api.bearerPost('auth/refresh-token');
  //   print("#Resp: ${jsonEncode(response)}");

  //   if (response["success"]) {
  //     Helpers.isAuthenticated = false;
  //     var dateTimeFormat = DateFormat('MMMM d, yyyy', 'en_US')
  //         .parse(response?['data']?['token']?['expires_at']);

  //     await storage.write(
  //         key: TOKEN, value: response?['data']?['token']?['token']);
  //     await storage.write(
  //         key: TOKEN_EXPIRY,
  //         value: dateTimeFormat.millisecondsSinceEpoch.toString());

  //     return response?['data']?['token']?['token'];
  //   } else {
  //     Helpers.isAuthenticated = false;
  //     await storage.delete(key: TOKEN);
  //     await storage.delete(key: TOKEN_EXPIRY);
  //     await storage.delete(key: REFRESH_TOKEN);
  //     await storage.delete(key: USERID);
  //     return "unauthenticated";
  //   }
  // }

  static Future<Engineer?> fetchProfile() async {
    Engineer? user = null;
    final response = await Api.bearerGet('auth/profile');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
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

  static Future<JobData?> fetchJobs(filters, int currentPage) async {
    JobData? data;

    final response = await Api.bearerPost('job/service-jobs?page=$currentPage',
        params: filters);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] && response['data'] != null) {
      data = await JobData.selectedJobFromJson(response);
    }
    return data;
  }

  static Future<JobData?> fetchKIVJobs(filters, int currentPage) async {
    JobData? data;

    final response = await Api.bearerPost(
        'job/service-jobs-extra?page=$currentPage',
        params: filters);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] && response['data'] != null) {
      data = await JobData.selectedJobFromJson(response);
    }
    return data;
  }

  static Future<JobData?> fetchCompletedJobs(filters, int currentPage) async {
    JobData? data;

    final response = await Api.bearerPost(
        'job/service-jobs-completed?page=$currentPage',
        params: filters);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] && response['data'] != null) {
      data = await JobData.selectedJobFromJson(response);
    }
    return data;
  }

  static Future<List<Job>?> fetchJobHistory(
      String jobId, String insertedAt) async {
    List<Job>? data = [];

    final response = await Api.bearerGet(
        'job/service-jobs-history-by-warranty?service_request_id=${jobId}&inserted_at=$insertedAt');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      data = (response['data'] as List).map((i) => Job.fromJson(i)).toList();
    }
    return data;
  }

  static Future<BagMetaData?> fetchUserBag(String serviceRequestId) async {
    BagMetaData? bag;

    final response = await Api.bearerGet(
        'general/spareparts-from-bag?service_request_id=${serviceRequestId}&search_only_by_code=0&include_spareparts_from_bag=1');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] &&
        response['data'] != null &&
        !(response['data'] is List)) {
      bag = (BagMetaData.selectedJobFromJson(response['data']));
    }
    return bag;
  }

  static Future<List<SparePart>?> fetchUserBagWithoutFilters() async {
    List<SparePart>? list;

    final response = await Api.bearerGet('general/spareparts-from-bag');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] && response['data'] != null) {
      list =
          (response['data'] as List).map((i) => SparePart.fromJson(i)).toList();
    }
    return list;
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

  static Future<JobData?> fetchOrderStatusesInitial() async {
    JobData? data;
    final response = await Api.bearerGet('job/service-jobs');
    print("#Resp: ${jsonEncode(response)}");
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
    final Map<String, dynamic> map = {
      'content': content,
      'service_request_id': salesOrdefId,
    };
    final response = await Api.bearerPost('job/comments/create', params: map);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      return true;
    }
    return false;
  }

  static Future<bool> changeSequence(
      String serviceRequestId, String position) async {
    final Map<String, dynamic> map = {
      "service_requests": [
        {
          'service_request_id': serviceRequestId,
          'job_sequence': position,
        }
      ]
    };

    final response = await Api.bearerPost('job/update-sequence', params: map);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      return true;
    }
    return false;
  }

  static Future<bool> updateComment(int commentId, String content) async {
    final Map<String, dynamic> map = {
      'remarks': content,
      'cust_remarks_id': commentId,
    };

    final response = await Api.bearerPost('job/comments/update', params: map);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"]) {
      return true;
    }
    return false;
  }

  static Future<bool> deleteComment(int commentId) async {
    final Map<String, dynamic> map = {
      'cust_remarks_id': commentId,
    };

    final response = await Api.bearerPost('job/comments/delete', params: map);
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
    if (response["success"] && response['data'] != null) {
      data = (response['data'] as List)
          .map((i) => ChecklistAttachment.fromJson(i))
          .toList();
    }
    return data;
  }

  static Future<Job?> fetchJobDetails({required String? jobId}) async {
    final response = await Api.bearerGet('job/service-job-details/${jobId}');
    if (response["success"] != null && response["success"]) {
      Job? job = null;
      job = Job.fromJson(response["data"]);

      return job;
    } else {
      return null;
    }
  }

  static Future<bool> createPickList(
      String jobId, List<SparePart> spareparts) async {
    List<Map<String, dynamic>> mapList = [];

    spareparts.forEach((element) {
      Map<String, dynamic> e = {
        'spareparts_id': element.id,
        'quantity_taken': element.selectedQuantity,
      };

      mapList.add(e);
    });

    final Map<String, dynamic> map = {'job_id': jobId, 'spareparts': mapList};

    final response =
        await Api.bearerPost('job/create-pick-list', params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addSparePartsToJob(
      String jobId, List<SparePart> spareparts) async {
    List<Map<String, dynamic>> fromPickList = [];
    List<Map<String, dynamic>> fromBag = [];
    List<Map<String, dynamic>> fromWarehouse = [];

    spareparts.forEach((element) {
      Map<String, dynamic> e = {
        'spareparts_id': element.id,
        'quantity_taken': element.quantity,
      };

      if (element.from == "bag") {
        fromBag.add(e);
      } else if (element.from == "warehouse") {
        fromWarehouse.add(e);
      } else if (element.from == "picklist") {
        fromPickList.add(e);
      }
    });

    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'picklist': fromPickList,
      'bag': fromBag,
      'warehouse': fromWarehouse,
    };

    final response = await Api.bearerPost('job/add-spareparts', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<TransportCharge>> fetchTransportCharges(
      productModelId) async {
    List<TransportCharge> data = [];

    try {
      final response = await Api.bearerGet(
          'general/transport-charges?product_model_id=' +
              productModelId.toString());
      print("#Resp: ${jsonEncode(response)}");
      if (response["success"] && response['data'] != null) {
        data = (response['data'] as List)
            .map((i) => TransportCharge.fromJson(i))
            .toList();
        var xx = data;

        return data;
      } else {
        return data;
      }
    } catch (e) {
      print(e);
      return data;
    }
  }

  static Future<bool> addItemsToPickList(
      String jobId, List<SparePart> spareparts) async {
    List<Map<String, dynamic>> spareParts = [];

    spareparts.forEach((element) {
      Map<String, dynamic> e = {
        'spareparts_id': element.id,
        'quantity_taken': element.quantity,
      };
      spareParts.add(e);
    });

    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'spareparts': spareParts
    };

    final response = await Api.bearerPost('job/create-pick-list', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> deleteMiscItem(String jobId, int miscChargesId) async {
    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'misc_charges_id': miscChargesId
    };

    final response =
        await Api.bearerPost('job/delete-misc-charges', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addMiscItem(String jobId, String remarks,
      double miscCharges, int quantity, int? miscChargesId) async {
    final List<Map<String, dynamic>> miscChargesArr = [
      {
        'remarks': remarks,
        'misc_charges': miscCharges,
        ...(miscChargesId == null ? {} : {'misc_charges_id': miscChargesId}),
        'quantity': quantity,
      }
    ];

    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'misc_charges_arr': miscChargesArr,
    };

    final response =
        await Api.bearerPost('job/update-misc-charges', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateMiscItems(
      String jobId, List<MiscellaneousItem> miscItems) async {
    var listOfMaps =
        await MiscellaneousItem().ListOfbjectsToListofMaps(miscItems);

    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'misc_charges_arr': listOfMaps,
    };

    final response =
        await Api.bearerPost('job/update-misc-charges', params: map);
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addProblemToJob(
      String jobId, int? problemId, bool isEstimate) async {
    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      ...(isEstimate
          ? {
              'estimated_problem_id':
                  problemId != null ? problemId.toString() : null
            }
          : {
              'actual_problem_id':
                  problemId != null ? problemId.toString() : null
            }),
    };

    final response = await Api.bearerPost('job/upsert-problem', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addSolutionToJob(
      String jobId, int? solutionId, bool isEstimate) async {
    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      ...(isEstimate
          ? {
              'estimated_solution_id':
                  solutionId != null ? solutionId.toString() : null
            }
          : {
              'actual_solution_id':
                  solutionId != null ? solutionId.toString() : null
            }),
    };

    final response = await Api.bearerPost('job/upsert-solution', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addTransportChargesToJob(
      String jobId, int productModelId, int? transportchargesGroupId) async {
    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'transport_charges_group_id': transportchargesGroupId != null
          ? transportchargesGroupId.toString()
          : null,
      'product_model_id': productModelId.toString()
    };

    final response =
        await Api.bearerPost('job/update-transport-charges', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> addPickupCharges(String jobId, int? pickupId) async {
    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'pickup_charges_id': pickupId != null ? pickupId.toString() : null,
    };

    final response =
        await Api.bearerPost('job/update-pickup-charges', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<PickListItems?> fetchDailyPickList() async {
    PickListItems? pickListItems = null;

    var map = {"get_only_today": true};
    final response =
        await Api.bearerPost('job/get-pick-list-for-day', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null &&
        response["success"] &&
        response["data"] != null &&
        !(response["data"] is List))
    //  &&(response["data"] as List<dynamic>).length > 0)
    {
      pickListItems = PickListItems.fromJson(response["data"]);
    }

    return pickListItems;
  }

  static Future<bool> startJob(
      List<File> images, String jobId, Job selectedJob) async {
    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
    var url = Uri.parse('${baseUrl}/job/start-job');
    return await sendMultipartReq(
        images, url, false, 0, jobId, selectedJob, false);
  }

  static Future<bool> completeJob(
      List<File> images, String jobId, Job selectedJob) async {
    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
    var url = Uri.parse('${baseUrl}/job/complete-job');
    return await sendMultipartReq(
        images, url, false, 0, jobId, selectedJob, true);
  }

  static Future<bool> cancelJob(
    List<File> images,
    String jobId,
    int reasonId,
  ) async {
    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
    var url = Uri.parse('${baseUrl}/job/cancel-job');
    return await sendMultipartReq(
        images, url, true, reasonId, jobId, null, false);
  }

  static Future<bool> uploadKIV(
      List<File> images, String jobId, int reasonId) async {
    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
    var url = Uri.parse('${baseUrl}/job/kiv-job');
    return await sendMultipartReq(
        images, url, true, reasonId, jobId, null, false);
  }

  static Future<bool> closeJob(List<File> images, String jobId) async {
    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
    var url = Uri.parse('${baseUrl}/job/job-close');
    return await sendMultipartReq(images, url, false, 0, jobId, null, false);
  }

  static Future<bool> rejectJob(String jobId, int? reasonId) async {
    final Map<String, dynamic> map = {
      'service_request_id': jobId,
      'cancellation_reason_id': reasonId,
    };

    final response = await Api.bearerPost('job/reject-job', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> rejectJobBulk(List<String> jobIds, int? reasonId) async {
    final Map<String, dynamic> map = {
      'service_request_ids': jobIds,
      'cancellation_reason_id': reasonId,
    };

    final response = await Api.bearerPost('job/reject-job-bulk', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> sendMultipartReq(
    List<File> images,
    Uri url,
    bool isKivOrIsCancelOrIsReject,
    int? reasonId,
    String serviceRequestId,
    Job? selectedJob,
    bool isComplete,
  ) async {
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
        'images[]',
        fileBytes,
        filename: file.path.split('/').last,
      );
      multipartFiles.add(multipartFile);
    }

    request.files.addAll(multipartFiles);

    request.fields["service_request_id"] = serviceRequestId;

    if (isKivOrIsCancelOrIsReject) {
      request.fields["cancellation_reason_id"] = reasonId.toString();
    } else if (isComplete) {
      request.fields["is_chargeable[spareparts]"] =
          (selectedJob?.chargeableSparepartIds?.length ?? 0) > 0 ? "1" : "0";
      request.fields["is_chargeable[solution]"] =
          (selectedJob?.isChargeableSolution ?? false) ? "1" : "0";
      request.fields["is_chargeable[transport]"] =
          (selectedJob?.isChargeableTransport ?? false) ? "1" : "0";
      request.fields["is_chargeable[pickup]"] =
          (selectedJob?.isChargeablePickup ?? false) ? "1" : "0";
      request.fields["is_chargeable[misc]"] =
          (selectedJob?.isChargeableMisc ?? false) ? "1" : "0";

      if ((selectedJob?.chargeableSparepartIds?.length ?? 0) > 0)
        selectedJob?.chargeableSparepartIds?.forEach((element) {
          request.fields["list_of_spareparts_not_chargeable[]"] = element;
        });
    }

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    var ll = response.statusCode;

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<void> fetchKIVReasonsInitial() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final response = await Api.bearerGet(
        'general/service-request-cancellation-reason?service_request_status_id=21');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      // var reason =
      //     (response['data'] as List).map((i) => Reason.fromJson(i)).toList();
      // var abc = json.encode(reason);
      pref.setString("kiv-reasons", json.encode(response['data']));
    } else {
      return fetchKIVReasonsInitial();
    }
  }

  static Future<void> fetchCancellationReasonsInitial() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    final response = await Api.bearerGet(
        'general/service-request-cancellation-reason?service_request_status_id=16');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      // var reason =
      //     (response['data'] as List).map((i) => Reason.fromJson(i)).toList();
      pref.setString("cancel-reasons", json.encode(response['data']));
    } else {
      fetchCancellationReasonsInitial();
    }
  }

  static Future<void> fetchRejectReasonsInitial() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final response = await Api.bearerGet(
        'general/service-request-cancellation-reason?service_request_status_id=23');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      // var reason =
      //     (response['data'] as List).map((i) => Reason.fromJson(i)).toList();
      pref.setString("reject-reasons", json.encode(response['data']));
    } else {
      fetchRejectReasonsInitial();
    }
  }

  static Future<void> fetchPickupChargesInitial() async {
    List<PickupCharge>? data = [];
    SharedPreferences pref = await SharedPreferences.getInstance();
    final response = await Api.bearerGet('general/pickup-charges');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      pref.setString("pickup-charges", json.encode(response['data']));
    } else {
      return fetchPickupChargesInitial();
    }
  }

  ///////SharedPREF BEGIN

  static Future<List<Reason>> fetchKIVReasons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String kivReasonsStr = prefs.getString("kiv-reasons") ?? "";
    List<Reason> kivReasons = (json.decode(kivReasonsStr) as List)
        .map((e) => Reason.fromJson(e))
        .toList();
    return kivReasons;
  }

  static Future<List<PickupCharge>> fetchPickupCharges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String pickupchargesStr = prefs.getString("pickup-charges") ?? "";
    List<PickupCharge> pickupCharges = (json.decode(pickupchargesStr) as List)
        .map((e) => PickupCharge.fromJson(e))
        .toList();
    return pickupCharges;
  }

  static Future<List<Reason>> fetchCancellationReasons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cancellationReasonsStr = prefs.getString("cancel-reasons") ?? "";
    var abc = json.decode(cancellationReasonsStr);
    List<Reason> cancellationReasons =
        (json.decode(cancellationReasonsStr) as List)
            .map((e) => Reason.fromJson(e))
            .toList();
    return cancellationReasons;
  }

  static Future<List<Reason>> fetchRejectReasons() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String rejectionReasonsStr = prefs.getString("reject-reasons") ?? "";
    var abc = json.decode(rejectionReasonsStr);
    List<Reason> rejectionReasons = (json.decode(rejectionReasonsStr) as List)
        .map((e) => Reason.fromJson(e))
        .toList();
    return rejectionReasons;
  }

  // static Future<List<Reason>> fetchJobStatuses() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String jobStatusesStr = prefs.getString("job-statuses") ?? "";
  //   List<String> jobStatuses = (json.decode(rejectionReasonsStr) as List)
  //       .map((e) => Reason.fromJson(e))
  //       .toList();
  //   return rejectionReasons;
  // }

  ///////SHARED PREF END

  static Future<bool> updateChargeable(
      String jobId,
      bool isChargeablePickup,
      bool isChargeableTransport,
      bool isChargeableSolution,
      bool isChargeableMisc,
      bool isDiscountApplied,
      List<String> ids) async {
    var query = "";

    if (ids.length > 0) {
      ids.forEach((element) {
        query = '${query}&list_of_spareparts_not_chargeable[]=${element}';
      });
    }

    var url =
        'job/fetch-payment-rcp?service_request_id=${jobId}&is_chargeable[spareparts]=${ids.length > 0 ? "1" : "0"}&is_chargeable[solution]=${isChargeableSolution ? "1" : "0"}&is_discount_applied=${isDiscountApplied ? "1" : "0"}&is_chargeable[transport]=${isChargeableTransport ? "1" : "0"}&is_chargeable[pickup]=${isChargeablePickup ? "1" : "0"}&is_chargeable[misc]=${isChargeableMisc ? "1" : "0"}${query}';
    final response = await Api.bearerGet(
        'job/fetch-payment-rcp?service_request_id=${jobId}&is_chargeable[spareparts]=${ids.length > 0 ? "1" : "0"}&is_chargeable[solution]=${isChargeableSolution ? "1" : "0"}&is_discount_applied=${isDiscountApplied ? "1" : "0"}&is_chargeable[transport]=${isChargeableTransport ? "1" : "0"}&is_chargeable[pickup]=${isChargeablePickup ? "1" : "0"}&is_chargeable[misc]=${isChargeableMisc ? "1" : "0"}${query}');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<PaymentMethod>> fetchPaymentMethodLabels() async {
    final response = await Api.bearerGet('payment-methods');
    if (response["success"] != null && response["success"]) {
      var paymentMethods = (response['data'] as List)
          .map((i) => (PaymentMethod.fromJson(i)))
          .toList();
      return paymentMethods;
    } else {
      return [];
    }
  }

  static Future<bool> confirmAcknowledgement(
      String jobId,
      File image,
      File? qrPaymentImgs,
      bool isMailInvoice,
      String mailEmail,
      String paymentMethodId
      // double amount,
      // String currency,
      ) async {
    var token = await storage.read(key: TOKEN);

    String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
    var url = Uri.parse('${baseUrl}/job/service-request-acknowledgement');

    var headers = {
      'Accept': 'application/vnd.api+json',
      'Content-Type': 'application/vnd.api+json',
      'Authorization': 'Bearer $token'
    };
    var request = http.MultipartRequest('POST', url);
    request.files
        .add(await http.MultipartFile.fromPath('signature', image.path));

    if (qrPaymentImgs != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'qr_payment', qrPaymentImgs?.path ?? ""));
    }
    // List<http.MultipartFile> multipartFiles = [];

    // for (var file in qrPaymentImgs) {
    //   List<int> fileBytes = await file.readAsBytes();
    //   http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
    //     'images[]',
    //     fileBytes,
    //     filename: file.path.split('/').last,
    //   );
    //   multipartFiles.add(multipartFile);
    // }
    request.headers.addAll(headers);
    request.fields['service_request_id'] = jobId;
    request.fields['payment_method_id'] = paymentMethodId;
    request.fields['mail_invoice'] = isMailInvoice ? "1" : "0";
    (mailEmail != "" && isMailInvoice)
        ? request.fields['mailing_email'] = mailEmail
        : {};

    http.StreamedResponse response = await request.send();

    // var res = response.stream.bytesToString() ?? "";

    if (response.statusCode == 200) {
      // print(await response.stream.bytesToString());
      return true;
    } else {
      print(response.reasonPhrase);
      return false;
    }
  }

  static Future<List<Solution>> fetchSolutions(
      String productModelId, String serviceTypeId) async {
    final response = await Api.bearerGet(
        'general/solutions?product_model_id=${productModelId}&service_type_id=${serviceTypeId}');
    print("#Resp:  ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      var solutions =
          (response['data'] as List).map((i) => Solution.fromJson(i)).toList();
      return solutions;
    } else {
      return [];
    }
  }

  static Future<List<Problem>> fetchProblems(
    String productGroupId,
  ) async {
    final response = await Api.bearerGet(
        'general/problems?product_group_id=${productGroupId}');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      var problems =
          (response['data'] as List).map((i) => Problem.fromJson(i)).toList();
      return problems;
    } else {
      return [];
    }
  }

  static Future<RCPCost?> fetchPaymentRCP(
      String jobId,
      bool isChargeablePickup,
      bool isChargeableTransport,
      bool isChargeableSolution,
      bool isChargeableMisc,
      bool isDiscountApplied,
      List<String> ids) async {
    var query = "";

    if (ids.length > 0) {
      ids.forEach((element) {
        query = '${query}&list_of_spareparts_not_chargeable[]=${element}';
      });
    }

    var url =
        'job/fetch-payment-rcp?service_request_id=${jobId}&is_chargeable[spareparts]=1&is_chargeable[solution]=${isChargeableSolution ? "1" : "0"}&is_discount_applied=${isDiscountApplied ? "1" : "0"}&is_chargeable[transport]=${isChargeableTransport ? "1" : "0"}&is_chargeable[pickup]=${isChargeablePickup ? "1" : "0"}&is_chargeable[misc]=${isChargeableMisc ? "1" : "0"}${query}';
    final response = await Api.bearerGet(
        'job/fetch-payment-rcp?service_request_id=${jobId}&is_chargeable[spareparts]=1&is_chargeable[solution]=${isChargeableSolution ? "1" : "0"}&is_discount_applied=${isDiscountApplied ? "1" : "0"}&is_chargeable[transport]=${isChargeableTransport ? "1" : "0"}&is_chargeable[pickup]=${isChargeablePickup ? "1" : "0"}&is_chargeable[misc]=${isChargeableMisc ? "1" : "0"}${query}');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return RCPCost.fromJson(response["data"]);
    } else {
      return null;
    }
  }

  static Future<PaymentCollection?> fetchPaymentCollection() async {
    final response = await Api.bearerGet('user/get-payment-collection');
    if (response["success"] != null && response["success"]) {
      return PaymentCollection.fromJson(response['data']);
    } else {
      return null;
    }
  }

  static Future<List<PaymentHistoryMeta>?> fetchPaymentHistory(
      String startDate, String endDate, String cursor) async {
    var url =
        'payment/engineer/collection/list?start_date=$startDate&end_date=$endDate&cursor_date=$cursor';
    final response = await Api.bearerGet(
        'payment/engineer/collection/list?start_date=$startDate&end_date=$endDate&cursor_date=$cursor');
    if (response["success"] != null && response["success"]) {
      return await (response['data'] as List)
          .map((e) => PaymentHistoryMeta.fromJson(e))
          .toList();
    } else {
      return null;
    }
  }

  static Future<JobData?> fetchPaymentHistoryJobList(
      String collectionDate,
      String? serviceTypeId,
      String? paymentStatusId,
      String? serviceRequestStatus,
      String? q) async {
    var url =
        'payment/engineer/collection/job/list?collection_date=$collectionDate' +
            (serviceTypeId != null
                ? "&filters[service_type][0]=$serviceTypeId"
                : "") +
            (paymentStatusId != null
                ? "&filters[payment_status_id][0]=$paymentStatusId"
                : "") +
            (serviceRequestStatus != null
                ? "&filters[service_request_status][0]=$serviceRequestStatus"
                : "") +
            (q != null ? "&q=$q" : "");
    final response = await Api.bearerGet(url);
    if (response["success"] != null && response["success"]) {
      return await JobData.selectedJobFromJson(response);
    } else {
      return null;
    }
  }

//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> updateJobOrderSequence(
      List<JobOrderSequence> orderSeq) async {
    final Map<String, dynamic> map = {'job_orders': orderSeq};

    final response = await Api.bearerPost('job-orders/update-sequence',
        params: jsonEncode(map));
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
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

  static Future<bool> updateSerialNo(String jobId, String serialNo) async {
    final Map<String, dynamic> map = {
      'serial_no': serialNo,
      'service_request_id': jobId
    };

    final response =
        await Api.bearerPost('job/update-job-description', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateRemarks(String jobId, String remarks) async {
    final Map<String, dynamic> map = {
      'remarks': remarks,
      'service_request_id': jobId
    };

    final response =
        await Api.bearerPost('job/update-job-description', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateAdminRemarks(String jobId, String remarks) async {
    final Map<String, dynamic> map = {
      'admin_remarks': remarks,
      'service_request_id': jobId
    };

    final response =
        await Api.bearerPost('job/update-job-description', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateEngineerRemarks(
      String jobId, String remarks) async {
    final Map<String, dynamic> map = {
      'remarks': remarks,
      'service_request_id': jobId
    };

    final response =
        await Api.bearerPost('job/update-engineer-remarks', params: map);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> toggleChargable(String jobId) async {
    final response =
        await Api.bearerPost('job-orders/$jobId/toggle-chargerable');
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final response = await Api.bearerGet('general/payment-methods');
    if (response["success"] != null && response["success"]) {
      var paymentMethods = (response['data'] as List)
          .map((i) => (PaymentMethod.fromJson(i)))
          .toList();
      return paymentMethods;
    } else {
      return [];
    }
  }

  static Future<AppVersion?> fetchAppVersion() async {
    final response = await Api.bearerGet('general/app-version');
    if (response["success"] != null && response["success"]) {
      AppVersion appVersion = AppVersion.fromJson(response['data']);
      return appVersion;
    } else {
      return null;
    }
  }

  static Future<String> renewAccessToken() async {
    var baseUrl = await dotenv.env["API_BASE_URL"];
    var refreshToken = await storage.read(key: REFRESH_TOKEN);

    var data = {"refresh_token": refreshToken};

    final res =
        await http.post(Uri.parse("$baseUrl/auth/refresh-token"), body: data);

    var response = json.decode(res.body) as Map<String, dynamic>;

    print("#Resp: ${jsonEncode(response)}");

    if (response["success"]) {
      Helpers.isAuthenticated = false;
      var dateTimeFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSSSS'Z'")
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

  //POST RATING

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
    if (response["success"] != null && response["success"]) {
      return true;
    } else {
      return false;
    }
  }
}
