import 'package:kcs_engineer/model/payment/payment_method.dart';
import 'package:signature/signature.dart';

class PaymentDTO {
  SignatureController? signatureController;
  String? dropDownOneSelectedText;
  String? dropDownTwoSelectedText;
  // String? PMOneCT;
  // String? PMTwoCT;
  String? emailCT;
  List<PaymentMethod>? paymentMethods;
  // bool mixedPayment;
  // bool solution;
  bool isWantInvoice;
  bool payByCash;
  bool payNow;
  // bool pendingPayment;
  // bool billing;
  // bool payByCheque;

  PaymentDTO({
    this.signatureController,
    this.dropDownOneSelectedText,
    this.dropDownTwoSelectedText,
    // this.PMOneCT,
    // this.PMTwoCT,
    this.paymentMethods,
    // this.mixedPayment = false,
    // this.solution = false,
    this.emailCT,
    this.isWantInvoice = false,
    this.payByCash = false,
    this.payNow = false,
    // this.pendingPayment = false,
    // this.billing = false,
    // this.payByCheque = false
  });
}
