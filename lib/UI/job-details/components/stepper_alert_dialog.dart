import 'package:flutter/material.dart';

class StepperAlertDialog extends StatefulWidget {
  Widget content;
  int? stepperCounter;
  Function isStepperCountChanged;
  Function isConfirmPressed;

  StepperAlertDialog(
      {required this.content,
      required this.stepperCounter,
      required this.isStepperCountChanged,
      required this.isConfirmPressed}) {}

  @override
  _StepperAlertDialogState createState() => _StepperAlertDialogState();
}

class _StepperAlertDialogState extends State<StepperAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text('Job Summary'),
        content: Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
            width: MediaQuery.of(context).size.height * 0.5,
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * .4,
                    minHeight: MediaQuery.of(context).size.height * .1),
                child: Column(children: [
                  SizedBox(height: 50),
                  widget.content,
                ]))),
        actions: <Widget>[
          SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.18, // <-- match_parent
              height:
                  MediaQuery.of(context).size.width * 0.05, // <-- match-parent
              child: widget.stepperCounter == 0
                  ? new Container()
                  : ElevatedButton(
                      child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            children: [
                              const Text(
                                'Previous',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ],
                          )),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Colors.black)))),
                      onPressed: () async {
                        await widget.isStepperCountChanged.call(false);
                      })),
          SizedBox(width: 20),
          SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.18, // <-- match_parent
              height:
                  MediaQuery.of(context).size.width * 0.05, // <-- match-parent
              child: widget.stepperCounter == 5
                  ? ElevatedButton(
                      child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            children: [
                              const Icon(
                                // <-- Icon
                                Icons.check,
                                color: Colors.white,
                                size: 18.0,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                'Confirm',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ],
                          )),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  side:
                                      const BorderSide(color: Colors.black)))),
                      onPressed: () async {
                        await widget.isConfirmPressed();
                      })
                  : ElevatedButton(
                      child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                'Next',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ],
                          )),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  side: const BorderSide(color: Colors.black)))),
                      onPressed: () async {
                        await widget.isStepperCountChanged.call(true);
                      })),
        ]);
  }
}
