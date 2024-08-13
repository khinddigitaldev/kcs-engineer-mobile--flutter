import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/util/repositories.dart';

class PickListItem extends StatelessWidget {
  PickListItem(
      {Key? key,
      required this.width,
      required this.part,
      required this.job,
      required this.jobId,
      required this.index,
      required this.rcpCost,
      required this.onDeletePressed,
      required this.editable,
      required this.isDiscountApplied,
      required this.aggregatedSpareParts,
      required this.onQuantityChanged,
      required this.partList})
      : super(key: key);

  final double width;
  final SparePart part;
  final Job job;
  final String jobId;
  final int index;
  Function onDeletePressed;
  Function onQuantityChanged;
  RCPCost? rcpCost;
  bool? isDiscountApplied;
  List<SparePart> aggregatedSpareParts;

  final bool editable;
  final List<SparePart> partList;
  var isRecordEditable = false;

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        // List<JobSparePart> finalArr = [];
        // for (int i = 0; i < partList.length; i++) {
        //   if (partList[i].id == part.id) {
        //     partList[i].quantity = 0;
        //   }
        // }
        // await _AddSparePartsToJob(partList);
        await onDeletePressed.call(part.id);
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

  Future<bool> _AddSparePartsToJob(List<SparePart> jobSpareparts) async {
    SparePart sparePart;
    List<SparePart> spareParts = [];
    jobSpareparts.forEach((element) {
      sparePart = new SparePart();
      sparePart.id = element!.id;
      sparePart.quantity = element!.quantity;
      spareParts.add(sparePart);
    });

    return await Repositories.addSparePartsToJob(jobId, spareParts);
  }

  @override
  Widget build(BuildContext context) {
    // var transactionId = this.part.transactionId;
    var sparePartId = this.part.id;
    int quantity = this.part.unapprovedQuantityTaken ?? 0;
    // aggregatedSpareParts.indexWhere((element) => element.id == part.id) ==
    //         -1
    //     ? (part.quantity ?? 0)
    //     : (part.quantity ?? 0) -
    //         (aggregatedSpareParts
    //                 .firstWhere((element) => element.id == part.id)
    //                 .quantity ??
    //             0);
    // var discount = this.part.discount;
    var price = this.part.priceFormatted;
    var sparePartCode = this.part.code;
    var description = this.part.description;

    num unitPrice = num.parse((rcpCost?.pickListItems ?? [])
                .indexWhere((element) => element.sparepartsId == part.id) !=
            -1
        ? '${(num.parse((isDiscountApplied ?? false) ? (rcpCost?.pickListItems ?? []).firstWhere((element) => element.sparepartsId == part.id).rcpUnitPriceVal ?? "0" : (rcpCost?.pickListItems ?? []).firstWhere((element) => element.sparepartsId == part.id).unitPrice ?? "0") / (100)).toStringAsFixed(2)}'
        : "0.00");

    // var total = (((double.parse(price ?? '0') *
    //         double.parse((quantity != "" ? quantity : "0") ?? "0")) *
    //     (100 - double.parse(discount ?? '0')) /
    //     100));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        job.serviceJobStatus != "COMPLETED" && editable
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
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 200,
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '$sparePartCode',
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
                        text: '$description',
                      ),
                    ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        Expanded(
            // width: MediaQuery.of(context).size.width * 0.4,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Container(
                padding: const EdgeInsets.only(bottom: 30),
                child: RichText(
                  text: TextSpan(
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.black54,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "MYR ${unitPrice.toStringAsFixed(2)}",
                        )
                      ]),
                ),
              ),
              !editable
                  ? Container(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: RichText(
                        text: TextSpan(
                            style: TextStyle(
                              fontSize: 16.0,
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
                    )
                  : Container(
                      width: 80,
                      padding: EdgeInsets.only(bottom: 50),
                      child: TextFormField(
                          //focusNode: focusEmail,
                          keyboardType: TextInputType.number,
                          onChanged: (newQuantity) async {
                            await onQuantityChanged(newQuantity, index);
                          },
                          onEditingComplete: () {},
                          onFieldSubmitted: (val) {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());
                          },
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp("[0-9a-zA-Z]")),
                          ],
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.black54,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            //suffixText: quantity == 1 ? ' Unit' : ' Units',
                            hintText: '$quantity'.split(".")[0],
                            hintStyle:
                                TextStyle(color: Colors.grey.withOpacity(0.7)),
                            contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                          )),
                    ),
              Container(
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
                              'MYR ${(unitPrice * quantity).toStringAsFixed(2)}',
                        ),
                      ]),
                ),
              ),
            ])),
      ],
    );
  }
}
