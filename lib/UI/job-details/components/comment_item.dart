import 'package:flutter/material.dart';
import 'package:kcs_engineer/model/job/comment.dart';
import 'package:kcs_engineer/util/repositories.dart';

class CommentItem extends StatefulWidget {
  CommentItem(
      {Key? key,
      required this.comments,
      required this.loggedInUserId,
      required this.index,
      required this.onDeletePressed,
      // required this.textEditingControllers,
      required this.ctx,
      required this.focusNodes,
      required this.onUpdate,
      required this.onEditPressed,
      required this.isCurrentSelectedindex})
      : super(key: key);

  final List<Comment> comments;
  final List<FocusNode> focusNodes;
  // final List<TextEditingController> textEditingControllers;

  final int index;
  final int? isCurrentSelectedindex;
  final String loggedInUserId;
  Function onDeletePressed;
  Function onUpdate;
  Function onEditPressed;
  BuildContext ctx;

  @override
  _CommentItemState createState() => new _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool isFocused = false;
  bool isCurrentUIEditable = false;

  TextEditingController commentTextController = new TextEditingController();
  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await widget.onDeletePressed.call(widget.index);
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
  void initState() {
    super.initState();

    setState(() {
      var oo = widget.comments;
      var abc = widget.comments[widget.index].remarks ?? "";
      var indwwwex = widget.index;

      this.commentTextController.text =
          widget.comments[widget.index].remarks ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        widget.comments != null && widget.comments.length > 0
            ? SizedBox(
                height: 20,
              )
            : new Container(),
        widget.comments != null && widget.comments.length > 0
            ? Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * .2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  border: Border.all(
                    width: 0.4,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 5,
                        color: Colors.grey[100]!,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: MediaQuery.of(context).size.width * 0.06,
                      child: Container(
                        child: Image(
                          image:
                              AssetImage('assets/images/inverted_commas.png'),
                        ),
                      ),
                    ),
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(70, 50, 70, 5),
                            child: Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: widget.comments[widget.index]
                                                .customerName,
                                            style: const TextStyle(
                                                color: Color(0xFF888888),
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.circle,
                                  size: 5,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Color(0xFF888888),
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: widget.comments[widget.index]
                                                .insertedAtInAgoAnnotation,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFDBF0F9),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Center(
                                      child: Text(
                                        widget.comments[widget.index].role ??
                                            "",
                                        style: TextStyle(
                                          color: Color(0xFF5ACEFF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.fromLTRB(70, 5, 70, 30),
                            child: widget.isCurrentSelectedindex == widget.index
                                ? TextFormField(
                                    keyboardType: TextInputType.multiline,
                                    minLines: 1,
                                    maxLines: 2,
                                    onChanged: (str) {
                                      // setState(() {
                                      //   isSerialNoEditable = true;
                                      // });
                                    },
                                    enabled: true,
                                    controller: this.commentTextController,
                                    //     readOnly: isSerialNoEditable,
                                    focusNode: widget.focusNodes[widget.index],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold))
                                : RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: widget
                                                      .comments[widget.index]
                                                      .remarks ??
                                                  "",
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold)),
                                        ]),
                                  ),
                          ),
                          widget.loggedInUserId ==
                                  widget.comments[widget.index].userId
                              ? Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        var comme =
                                            widget.comments[widget.index];
                                        var loggewd = widget.loggedInUserId;

                                        if (!(widget.isCurrentSelectedindex ==
                                            widget.index)) {
                                          await widget
                                              .onEditPressed(widget.index);
                                        } else {
                                          var res =
                                              await Repositories.updateComment(
                                                  widget.comments[widget.index]
                                                          .id ??
                                                      0,
                                                  this
                                                      .commentTextController
                                                      .text
                                                      .toString());
                                          await widget.onUpdate(widget.index);
                                        }
                                      },
                                      child: !(widget.isCurrentSelectedindex ==
                                              widget.index)
                                          ? Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  70, 5, 10, 30),
                                              child: Row(
                                                children: [
                                                  Icon(Icons
                                                      .edit_calendar_outlined),
                                                  SizedBox(width: 5),
                                                  RichText(
                                                    text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 16.0,
                                                          color: Colors.black,
                                                        ),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text: 'Edit',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ]),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  70, 5, 10, 30),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check_box_sharp),
                                                  SizedBox(width: 5),
                                                  RichText(
                                                    text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 16.0,
                                                          color: Colors.black,
                                                        ),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text: 'Save',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    GestureDetector(
                                        onTap: () async {
                                          showAlertDialog(widget.ctx);
                                        },
                                        child: Container(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 5, 70, 30),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_forever,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 3),
                                              RichText(
                                                text: TextSpan(
                                                    style: const TextStyle(
                                                      fontSize: 16.0,
                                                      color: Colors.red,
                                                    ),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                          text: 'Delete',
                                                          style: const TextStyle(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ]),
                                              ),
                                            ],
                                          ),
                                        ))
                                  ],
                                )
                              : new Container()
                        ]),
                  ],
                ))
            : new Container()
      ],
    );
  }
}
