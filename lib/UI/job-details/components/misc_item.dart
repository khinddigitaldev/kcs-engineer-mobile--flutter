import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/spareparts/miscellaneousItem.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';

class MiscItem extends StatelessWidget {
  MiscItem(
      {Key? key,
      required this.width,
      required this.miscItem,
      required this.job,
      required this.jobId,
      required this.index,
      required this.onDeletePressed,
      required this.editable,
      required this.partList})
      : super(key: key);

  final double width;
  final MiscellaneousItem miscItem;
  final Job job;
  final String jobId;
  final int index;
  Function onDeletePressed;
  final bool editable;
  final List<SparePart> partList;
  var isRecordEditable = false;
  final RegExp priceRegex = RegExp(r'^\d+(\.\d{0,2})?$');

  TextEditingController quantityCT = new TextEditingController();
  TextEditingController priceCT = new TextEditingController();

  showAlertDialog(BuildContext context, int id) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await onDeletePressed.call(id);
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
      content: Text("Are you sure to delete the selected miscellaneous item ?"),
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
    var miscItemId = this.miscItem.miscChargesId;
    var quantity = this.miscItem.quantity;
    var description = this.miscItem.remarks;
    var price = this.miscItem.formattedPrice;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        editable
            ? Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: GestureDetector(
                    onTap: () async {
                      await showAlertDialog(context, miscItemId ?? 0);
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
          width: MediaQuery.of(context).size.width * 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18.0,
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
        SizedBox(
          width: 10,
        ),
        !editable
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.1,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 20),
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
            : Container(
                width: 80,
                padding: EdgeInsets.only(bottom: 20),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableMiscItems[index].quantity =
                          int.parse(str);
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp((r'^[0-9]*$'))),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      hintText: quantity.toString(),
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
        SizedBox(
          width: 10,
        ),
        !editable
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(text: price),
                        ]),
                  ),
                ),
              )
            : Container(
                width: 80,
                padding: EdgeInsets.only(bottom: 20),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableMiscItems[index].formattedPrice =
                          'MYR ${str}';
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp((r"^[0-9a-zA-Z]*\.?[0-9a-zA-Z]*$"))),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      hintText: price?.split("MYR")[1],
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
      ],
    );
  }
}
