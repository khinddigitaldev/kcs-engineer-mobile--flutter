import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddMiscItemsPopup extends StatefulWidget {
  Function? newItemAdded;

  AddMiscItemsPopup({required this.newItemAdded}) {}

  @override
  _AddMiscItemsPopupState createState() => _AddMiscItemsPopupState();
}

class _AddMiscItemsPopupState extends State<AddMiscItemsPopup> {
  TextEditingController itemNameController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  Function? newItemAdded;
  int quantity = 1;

  void increment() {
    setState(() {
      quantity++;
    });
  }

  void decrement() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    newItemAdded = widget.newItemAdded;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Miscellaneous item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 25),
          RichText(
            text: const TextSpan(
                style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Item Name: ',
                  ),
                ]),
          ),
          SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: EdgeInsets.only(bottom: 50),
            child: TextFormField(
                //focusNode: focusEmail,
                controller: itemNameController,
                keyboardType: TextInputType.text,
                onChanged: (str) {},
                onEditingComplete: () {},
                onFieldSubmitted: (val) {
                  FocusScope.of(context).requestFocus(new FocusNode());
                },
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]')),
                ],
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                  contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                )),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: decrement,
                        icon: Icon(
                          Icons.remove,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * .07,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          controller: TextEditingController(text: '$quantity'),
                          readOnly: true,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 1.0),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: increment,
                        icon: Icon(Icons.add, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Row(children: [
                  Container(
                      padding: EdgeInsets.only(bottom: 50),
                      decoration: BoxDecoration(
                        boxShadow: [],
                      ),
                      child: Text("RM")),
                  Container(
                      width: MediaQuery.of(context).size.width * 0.2,
                      padding: EdgeInsets.only(bottom: 50, left: 20),
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (str) {},
                        onEditingComplete: () {},
                        onFieldSubmitted: (val) {
                          FocusScope.of(context).requestFocus(new FocusNode());
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9a-zA-Z.]'),
                          ),
                        ],
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          border: OutlineInputBorder(),
                          hintStyle:
                              TextStyle(color: Colors.grey.withOpacity(0.7)),
                          contentPadding: EdgeInsets.fromLTRB(15, 5, 5, 5),
                        ),
                      )),
                ])
              ])
        ],
      ),
      actions: [
        ElevatedButton(
            child: Padding(
                padding: EdgeInsets.all(0.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )
                ])),
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: const BorderSide(color: Color(0xFF242A38))))),
            onPressed: () {
              Navigator.pop(context);
            }),
        ElevatedButton(
            child: Padding(
                padding: EdgeInsets.all(0.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Add Items',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )
                ])),
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: const BorderSide(color: Color(0xFF242A38))))),
            onPressed: () async {
              await newItemAdded?.call(
                  itemNameController.text.toString(),
                  quantity,
                  num.parse(priceController.text.toString())
                      .toStringAsFixed(2));
            }),
      ],
    );
  }
}
