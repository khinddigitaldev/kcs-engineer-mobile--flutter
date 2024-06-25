import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/util/helpers.dart';

class AddPartItem extends StatefulWidget {
  double? width;
  SparePart? part;
  bool? isStepper;
  Job? job;
  String? jobId;
  int? index;
  bool? isChargeable;
  Function? onDeletePressed;
  Function? onChargeablePressed;
  bool? editable;
  List<SparePart>? partList;
  bool? isDiscountApplied;
  RCPCost? rcpCost;

  AddPartItem(
      {Key? key,
      required this.width,
      required this.part,
      required this.isChargeable,
      required this.job,
      required this.isStepper,
      required this.jobId,
      required this.isDiscountApplied,
      required this.index,
      required this.rcpCost,
      required this.onDeletePressed,
      required this.onChargeablePressed,
      required this.editable,
      required this.partList});

  @override
  AddPartItemState createState() => new AddPartItemState();
}

class AddPartItemState extends State<AddPartItem> {
  double? width;
  // SparePart? part;
  // Job? job;
  // String? jobId;
  // int? index;
  // Function? onDeletePressed;
  // Function? onChargeablePressed;
  // List<SparePart>? partList;

  int? selectedQuantity;

  @override
  void initState() {
    super.initState();

    setState(() {
      width = widget.width;

      selectedQuantity = widget.part?.quantity;
    });
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await widget.onDeletePressed?.call(widget.part?.id);
        Navigator.pop(context);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected spare part ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // var transactionId = this.part.transactionId;
    setState(() {});
    var sparePartId = widget.part?.id;
    int quantity = widget.part?.quantity ?? 0;
    // var discount = this.part.discount;
    var price = widget.part?.priceFormatted;
    var sparePartCode = widget.part?.code;
    var description = widget.part?.description;

    // var total = (((double.parse(price ?? '0') *
    //         double.parse((quantity != "" ? quantity : "0") ?? "0")) *
    //     (100 - double.parse(discount ?? '0')) /
    //     100));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        widget.job?.serviceJobStatus != "COMPLETED" &&
                (widget.editable ?? false)
            ? Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: GestureDetector(
                    onTap: () async {
                      await showAlertDialog(context);
                    },
                    child: Icon(
                      // <-- Icon
                      Icons.delete,
                      color: Colors.black54,
                      size: 25.0,
                    )),
              )
            : new Container(),
        SizedBox(
          width: 5,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${sparePartCode ?? "-"}',
                        ),
                      ]),
                ),
              ),
              RichText(
                text: TextSpan(
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '${description ?? "-"}',
                      ),
                    ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: FlutterSwitch(
            activeColor: (Helpers.checkIfEditableByJobStatus(
                        widget.job, (widget.job?.isMainEngineer ?? true)) &&
                    !(widget.isStepper ?? false))
                ? Colors.green
                : Colors.grey,
            inactiveColor: (Helpers.checkIfEditableByJobStatus(
                        widget.job, (widget.job?.isMainEngineer ?? true)) &&
                    !(widget.isStepper ?? false))
                ? Colors.red
                : Colors.grey,
            activeTextColor: Colors.white,
            inactiveTextColor: Colors.white,
            activeText: "Chargeable",
            inactiveText: "Not Chargeable",
            value: widget.isChargeable ?? false,
            valueFontSize: 12.0,
            width: MediaQuery.of(context).size.width * 0.2,
            borderRadius: 30.0,
            showOnOff: true,
            onToggle: (val) async {
              if (Helpers.checkIfEditableByJobStatus(
                      widget.job, (widget.job?.isMainEngineer ?? true)) &&
                  !(widget.isStepper ?? false)) {
                await widget.onChargeablePressed
                    ?.call(sparePartId, !(widget.isChargeable ?? true));
              }
            },
          ),
        ),
        !(widget.editable ?? false)
            ? SizedBox(
                width: 90,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: quantity == 1
                                ? '$quantity Unit'
                                : '$quantity Units',
                          ),
                        ]),
                  ),
                ),
              )
            : Row(children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: IconButton(
                    onPressed: () {
                      if (Helpers.editableJobSpareParts[widget.index ?? 0]
                              .quantity !=
                          0) {
                        setState(() {
                          Helpers.editableJobSpareParts[widget.index ?? 0]
                              .quantity = (Helpers
                                      .editableJobSpareParts[widget.index ?? 0]
                                      .quantity ??
                                  0) -
                              1;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.remove,
                      size: 15,
                      color: Helpers.editableJobSpareParts[widget.index ?? 0]
                                  .quantity !=
                              0
                          ? Colors.black
                          : Colors.black45,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  padding: EdgeInsets.only(bottom: 32),
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                '${(Helpers.editableJobSpareParts[widget.index ?? 0].quantity ?? 0)}',
                          ),
                        ]),
                  ),
                ),
              ]),
        SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 90,
          child: Container(
            padding: const EdgeInsets.only(bottom: 30),
            child: RichText(
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          'MYR ${((num.parse(((widget.rcpCost?.spareParts ?? []).indexWhere((element) => element.sparepartsId == widget.part?.id) != -1 ? ((widget.isDiscountApplied ?? false) ? (widget.rcpCost?.spareParts ?? []).firstWhere((element) => element.sparepartsId == widget.part?.id).rcpAmountVal : (widget.rcpCost?.spareParts ?? []).firstWhere((element) => element.sparepartsId == widget.part?.id).amountVal) : "0") ?? "0")) / 100).toStringAsFixed(2)}',
                    ),
                  ]),
            ),
          ),
        ),
      ],
    );
  }
}
