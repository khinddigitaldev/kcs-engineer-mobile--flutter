import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:kcs_engineer/model/payment/payment_method.dart';
import 'package:signature/signature.dart';

class PaymentStatus {
  bool? isPaid;
  bool? isPending;
  PaymentGatewayResponse? paymentGatewayResponse;

  PaymentStatus({
    this.isPaid,
    this.isPending,
    this.paymentGatewayResponse,
  });

  PaymentStatus.fromJson(Map<String, dynamic> json) {
    this.isPaid = json["is_paid"];
    this.isPending = json["is_pending"];
    this.paymentGatewayResponse = (json["payment_gateway_response"] != null
        ? PaymentGatewayResponse.fromJson(json["payment_gateway_response"])
        : null);
  }
}

class PaymentGatewayResponse {
  String? status;
  String? failureCode;
  String? failureMessage;

  PaymentGatewayResponse({
    this.status,
    this.failureCode,
    this.failureMessage,
  });

  PaymentGatewayResponse.fromJson(Map<String, dynamic> json) {
    this.status = json["type"];
    this.failureCode = json["spareparts_id"];
    this.failureMessage = json["attributes"]?["spareparts_code"];
  }
}
