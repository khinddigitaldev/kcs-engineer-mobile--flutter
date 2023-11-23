import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:kcs_engineer/model/bag.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/util/repositories.dart';

class AddItemsFromBagDialog extends StatefulWidget {
  BagMetaData? bag;
  List<SparePart>? existingJobSpareParts;
  String? jobId;
  String? ticketNo;

  AddItemsFromBagDialog(
      {this.bag, this.existingJobSpareParts, this.jobId, this.ticketNo});

  @override
  _AddItemsFromBagDialogState createState() => _AddItemsFromBagDialogState();
}

class _AddItemsFromBagDialogState extends State<AddItemsFromBagDialog>
    with AfterLayoutMixin {
  List<SparePart>? itemList;
  List<SparePart>? existingJobSpareParts;

  List<SparePart>? selectedBag;
  List<SparePart>? selectedJobSpareParts;
  String? jobId;
  String? ticketNo;

  BagMetaData? bag;

  @override
  void initState() {
    super.initState();
    bag = widget.bag;
    jobId = widget.jobId;
    ticketNo = widget.ticketNo;
    existingJobSpareParts = widget.existingJobSpareParts;
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await populateList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFFAFAFA),
      title: Row(children: [
        Text(
          'Add From Bag',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        SizedBox(
          height: 40.0,
          child: ElevatedButton(
              child: Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Row(children: [
                    Text(
                      'Add from Warehouse',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(
                      size: 15,
                      Icons.arrow_forward_ios,
                      color: Colors.white,
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
                Navigator.pushNamed(context, 'warehouse', arguments: jobId)
                    .then((value) async {
                  Navigator.pop(context);
                });
              }),
        ),
        SizedBox(width: 20),
      ]),
      content: Container(
        color: Color(0xFFFAFAFA),
        height: ((bag?.notPartOfBom?.length ?? 0) > 0 ||
                (bag?.notPartOfBom?.length ?? 0) > 0)
            ? MediaQuery.of(context).size.height * 0.6
            : MediaQuery.of(context).size.height * 0.3,
        width: double.maxFinite,
        child: ((bag?.notPartOfBom?.length ?? 0) > 0 ||
                (bag?.notPartOfBom?.length ?? 0) > 0)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  (itemList?.length ?? 0) > 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: "Bag",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(0.0, 1.5),
                                            blurRadius: 1.5)
                                      ]),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                .48,
                                        minWidth:
                                            MediaQuery.of(context).size.width *
                                                .35,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                .35,
                                        minHeight:
                                            MediaQuery.of(context).size.height *
                                                .1),
                                    child: ListView.builder(
                                      itemCount: itemList?.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return GestureDetector(
                                          child: Container(
                                            color: ((selectedBag ?? [])
                                                    .contains(itemList?[index]))
                                                ? Color(0xFF242A38)
                                                : Colors.transparent,
                                            child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 14.0,
                                                  horizontal: 10.0,
                                                ),
                                                child: SparePartItem(
                                                    tappedOnItem:
                                                        (tappedIndex, isleft) {
                                                      if (true) {
                                                        List<SparePart> array =
                                                            [];
                                                        array.addAll(
                                                            (selectedBag ??
                                                                []));
                                                        setState(() {
                                                          selectedBag = [];
                                                          selectedJobSpareParts =
                                                              [];
                                                        });
                                                        if (!array.contains(
                                                            itemList?[
                                                                tappedIndex])) {
                                                          array.add(itemList?[
                                                                  tappedIndex] ??
                                                              new SparePart());
                                                        } else {
                                                          array.remove(
                                                              itemList?[
                                                                  tappedIndex]);
                                                        }
                                                        setState(() {
                                                          selectedJobSpareParts =
                                                              [];
                                                          selectedBag = array;
                                                        });
                                                      }
                                                    },
                                                    quantityChanged:
                                                        (int quantity,
                                                            SparePart item) {
                                                      var index = selectedBag
                                                          ?.indexWhere(
                                                              (element) =>
                                                                  element
                                                                      .code ==
                                                                  item.code);

                                                      setState(() {
                                                        selectedBag?[index ?? 0]
                                                                .selectedQuantity =
                                                            quantity;
                                                      });
                                                    },
                                                    currentList:
                                                        (itemList ?? []),
                                                    selectedArray:
                                                        selectedBag ?? [],
                                                    isLeft: true,
                                                    index: index)),
                                          ),
                                          onTap: () async {
                                            // }
                                          },
                                          key: ValueKey(index),
                                        );
                                      },
                                    ),
                                  ))
                            ])
                      : new Container(),
                  buildIconButtons(),
                  (itemList?.length ?? 0) > 0 ||
                          (existingJobSpareParts?.length ?? 0) > 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Row(children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: "Job",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.blue,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: "#${ticketNo}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              ]),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(0.0, 1.5),
                                            blurRadius: 1.5)
                                      ]),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                .48,
                                        minWidth:
                                            MediaQuery.of(context).size.width *
                                                .35,
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                .35,
                                        minHeight:
                                            MediaQuery.of(context).size.height *
                                                .1),
                                    child: ListView.builder(
                                      itemCount: existingJobSpareParts?.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return GestureDetector(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 14.0,
                                              horizontal: 10.0,
                                            ),
                                            child: SparePartItem(
                                                tappedOnItem:
                                                    (tappedIndex, isleft) {
                                                  List<SparePart> array = [];
                                                  array.addAll(
                                                      selectedJobSpareParts ??
                                                          []);
                                                  setState(() {
                                                    selectedBag = [];
                                                    selectedJobSpareParts = [];
                                                  });
                                                  if (!array.contains(
                                                      existingJobSpareParts?[
                                                          tappedIndex])) {
                                                    array.add(
                                                        existingJobSpareParts?[
                                                                tappedIndex] ??
                                                            new SparePart());
                                                  } else {
                                                    array.remove(
                                                        existingJobSpareParts?[
                                                            tappedIndex]);
                                                  }
                                                  setState(() {
                                                    selectedBag = [];
                                                    selectedJobSpareParts =
                                                        array;
                                                  });
                                                },
                                                quantityChanged: (int quantity,
                                                    SparePart item) {
                                                  var index =
                                                      existingJobSpareParts
                                                          ?.indexWhere(
                                                              (element) =>
                                                                  element
                                                                      .code ==
                                                                  item.code);

                                                  setState(() {
                                                    existingJobSpareParts?[
                                                                index ?? 0]
                                                            .selectedQuantity =
                                                        quantity;
                                                  });
                                                },
                                                currentList:
                                                    existingJobSpareParts ?? [],
                                                selectedArray:
                                                    selectedJobSpareParts ?? [],
                                                isLeft: false,
                                                index: index),
                                          ),
                                          onTap: () async {
                                            // }
                                          },
                                          key: ValueKey(index),
                                        );
                                      },
                                    ),
                                  ))
                            ])
                      : new Container(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),
                          Icon(
                            // <-- Icon
                            Icons.indeterminate_check_box,
                            color: Colors.grey,
                            size: 130.0,
                          ),
                          RichText(
                            text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 30.0,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'No data found',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: 400,
                            child: RichText(
                              text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text:
                                          'Currently there are no Spare parts in your bag.',
                                    ),
                                  ]),
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          SizedBox(
                            height: 40.0,
                            child: ElevatedButton(
                                child: const Padding(
                                    padding: EdgeInsets.all(0.0),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )),
                                style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Color(0xFF242A38)),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Color(0xFF242A38)),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            side: const BorderSide(
                                                color: Color(0xFF242A38))))),
                                onPressed: () async {
                                  Navigator.pop(context);
                                }),
                          ),
                        ],
                      ))
                ],
              ),
      ),
      actions: ((bag?.notPartOfBom?.length ?? 0) > 0 &&
              (bag?.notPartOfBom?.length ?? 0) > 0)
          ? <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 40.0,
                    child: ElevatedButton(
                        child: const Padding(
                            padding: EdgeInsets.all(0.0),
                            child: Text(
                              'Cancel',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            )),
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF242A38)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF242A38)),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                    side: const BorderSide(
                                        color: Color(0xFF242A38))))),
                        onPressed: () async {
                          Navigator.pop(context);
                        }),
                  ),
                  SizedBox(width: 20),
                  SizedBox(
                    height: 40.0,
                    child: ElevatedButton(
                        child: const Padding(
                            padding: EdgeInsets.all(0.0),
                            child: Text(
                              'Add Parts From Bag',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            )),
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF242A38)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF242A38)),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                    side: const BorderSide(
                                        color: Color(0xFF242A38))))),
                        onPressed: () async {
                          if ((existingJobSpareParts?.length ?? 0) > 0) {
                            var arr = existingJobSpareParts?.map((e) {
                              e.from = "bag";
                              return e;
                            }).toList();
                            var res = await Repositories.addSparePartsToJob(
                                    jobId ?? "", arr ?? [])
                                .then((value) {
                              Navigator.pop(context);
                            });
                          }
                          print("asdasds");
                        }),
                  )
                ],
              )
            ]
          : [],
    );
  }

  populateList() {
    List<SparePart> list = [];

    setState(() {
      itemList = [];
      list = [];
    });

    if ((bag?.partOfBom?.length ?? 0) > 0) {
      list.add(new SparePart(isSparePart: false, headingTitle: "Part of BOM"));

      bag?.partOfBom?.forEach((element) {
        var e = SparePart.cloneInstance(element);

        setState(() {
          e.isBomSpecific = true;
          list.add(e);
        });
      });
    }

    if ((bag?.notPartOfBom?.length ?? 0) > 0) {
      list.add(new SparePart(isSparePart: false, headingTitle: "Other"));

      bag?.notPartOfBom?.forEach((element) {
        var e = SparePart.cloneInstance(element);
        setState(() {
          list.add(e);
        });
      });
    }

    setState(() {
      itemList = list;
    });
  }

  checkifbuttonEnabled(List<SparePart> parts) {
    try {
      var res =
          parts.where((element) => element.selectedQuantity != "0").toList();
      return res.length > 0;
    } on StateError {
      return false;
    }
  }

  Widget buildIconButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // setState(() {
            //   rightList.addAll(leftSelectedArr);
            //   leftList
            //       .removeWhere((element) => leftSelectedArr.contains(element));
            //   leftSelectedArr = [];
            // });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedBag?.length != 0 &&
                        checkifbuttonEnabled(selectedBag ?? [])
                    ? Colors.black
                    : Colors.black12, // Border color
                width: 1.0, // Border width
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                  color: selectedBag?.length != 0 &&
                          checkifbuttonEnabled(selectedBag ?? [])
                      ? Colors.black
                      : Colors.black12),
              onPressed: () {
                if (selectedBag?.length != 0 &&
                    checkifbuttonEnabled(selectedBag ?? [])) {
                  List<SparePart> list = [];
                  list.addAll(itemList ?? []);

                  if ((selectedBag?.length ?? 0) > 0) {
                    selectedBag?.forEach((element) {
                      var index = list?.indexOf(list
                              ?.where((item) =>
                                  item.description?.toLowerCase() ==
                                  element.description?.toLowerCase())
                              .toList()[0] ??
                          new SparePart());

                      setState(() {
                        var quantityToReduce = (element.selectedQuantity ?? 0);
                        var quantity =
                            (list[index ?? 0].quantity ?? 0) - quantityToReduce;
                        list[index ?? 0].quantity = quantity;
                      });
                    });

                    setState(() {
                      list?.removeWhere((element) =>
                          (element.quantity ?? "0") == 0 &&
                          element.headingTitle == "");
                      List<SparePart> selectedArr = [];
                      selectedArr.addAll(existingJobSpareParts ?? []);
                      selectedBag?.map((e) {
                            SparePart item = SparePart.cloneInstance(e);
                            item.quantity = item.selectedQuantity;
                            item.selectedQuantity = 0;
                            List<SparePart> processedList = selectedArr
                                .where((element) => element.id == item.id)
                                .toList();
                            bool ifExists = processedList.length > 0;
                            if (ifExists) {
                              var index = selectedArr
                                  .indexWhere((element) => element.id == e.id);
                              selectedArr[index].quantity =
                                  ((selectedArr[index].quantity ?? 0) +
                                      (e.selectedQuantity ?? 0));
                            } else {
                              selectedArr.add(item);
                            }

                            return item;
                          }).toList() ??
                          [];

                      existingJobSpareParts = selectedArr;
                      selectedBag = [];
                    });

                    setState(() {
                      itemList = [];
                      itemList?.addAll(list);
                      itemList = list;
                    });
                  }
                }
              },
            ),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedJobSpareParts?.length != 0 &&
                          checkifbuttonEnabled(selectedJobSpareParts ?? [])
                      ? Colors.black
                      : Colors.black12, // Border color
                  width: 1.0, // Border width
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: selectedJobSpareParts?.length != 0 &&
                            checkifbuttonEnabled(selectedJobSpareParts ?? [])
                        ? Colors.black
                        : Colors.black12),
                onPressed: () {
                  if (selectedJobSpareParts?.length != 0 &&
                      checkifbuttonEnabled(selectedJobSpareParts ?? [])) {
                    List<SparePart> list = [];
                    list.addAll(existingJobSpareParts ?? []);

                    if ((selectedJobSpareParts?.length ?? 0) > 0) {
                      selectedJobSpareParts?.forEach((element) {
                        var index = list?.indexOf(list
                                ?.where((item) => item.code == element.code)
                                .toList()[0] ??
                            new SparePart());

                        setState(() {
                          var quantityToReduce =
                              (element.selectedQuantity ?? 0);
                          var quantity = ((list[index ?? 0].quantity ?? 0) -
                              quantityToReduce);
                          list[index ?? 0].quantity = quantity;
                        });
                      });

                      setState(() {
                        list?.removeWhere((element) =>
                            (element.quantity ?? 0) == 0 &&
                            element.headingTitle == "");
                        List<SparePart> selectedArr = [];
                        selectedArr.addAll(itemList ?? []);
                        selectedJobSpareParts?.map((e) {
                              SparePart item = SparePart.cloneInstance(e);
                              item.quantity = item.selectedQuantity;
                              item.selectedQuantity = 0;
                              List<SparePart> processedList = selectedArr
                                  .where((element) => element.id == item.id)
                                  .toList();
                              bool ifExists = processedList.length > 0;
                              if (ifExists) {
                                var index = selectedArr.indexWhere(
                                    (element) => element.id == e.id);
                                selectedArr[index].quantity =
                                    (selectedArr[index].quantity ?? 0) +
                                        (e.selectedQuantity ?? 0);
                              } else {
                                selectedArr.add(item);
                              }

                              return item;
                            }).toList() ??
                            [];

                        itemList = selectedArr;
                        selectedJobSpareParts = [];
                      });

                      // setState(() {
                      //   itemList = [];
                      //   itemList?.addAll(list);
                      //   itemList = list;
                      // });
                    }
                  }
                },
              ),
            ))
      ],
    );
  }
}

class SparePartItem extends StatefulWidget {
  final List<SparePart> currentList;
  final int index;
  final List<SparePart> selectedArray;
  final bool isLeft;
  Function tappedOnItem;
  Function quantityChanged;

  SparePartItem(
      {required this.currentList,
      required this.index,
      required this.tappedOnItem,
      required this.selectedArray,
      required this.isLeft,
      required this.quantityChanged});

  @override
  _SparePartItemState createState() => new _SparePartItemState();
}

class _SparePartItemState extends State<SparePartItem> {
  List<SparePart>? currentList;
  int index = 0;
  List<SparePart>? selectedArray;
  bool? isLeft;
  int selectedQuantity = 1;

  Function? tappedOnItem;

  bool startAnimation = false;

  @override
  void initState() {
    super.initState();
    index = widget.index;
    isLeft = widget.isLeft;
    tappedOnItem = widget.tappedOnItem;
    currentList = widget.currentList;
    selectedArray = widget.selectedArray;
    Future.delayed(Duration(milliseconds: 50 + (widget.index * 100)), () {
      // Trigger the animation only for the first build
      if (!startAnimation) {
        setState(() {
          startAnimation = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(5),
        color: ((widget.selectedArray ?? []).contains(currentList?[index]))
            ? Color(0xFF242A38)
            : Colors.transparent,
        child: GestureDetector(
            child: (currentList?[index].isSparePart ?? false)
                ? (currentList ?? [])[index].quantity != "0"
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .2,
                                    child: Text(
                                        currentList?[index].description ?? "",
                                        style: TextStyle(
                                          color: (((widget.selectedArray ?? [])
                                                  .contains(
                                                      currentList?[index]))
                                              ? Colors.white
                                              : Colors.black),
                                        )),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(currentList?[index].code ?? "",
                                      style: TextStyle(
                                        color: (((widget.selectedArray ?? [])
                                                .contains(currentList?[index]))
                                            ? Colors.white
                                            : Colors.black54),
                                      )),
                                  Text(
                                      'stock : ${currentList?[index].quantity}',
                                      style: TextStyle(
                                        color: (((widget.selectedArray ?? [])
                                                .contains(currentList?[index]))
                                            ? Colors.white
                                            : Colors.black54),
                                      ))
                                ]),
                            (((widget.selectedArray ?? [])
                                    .contains(currentList?[index]))
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                          icon: new Icon(
                                            color:
                                                (currentList?[index].quantity ??
                                                            0) ==
                                                        0
                                                    ? Colors.black54
                                                    : Colors.white,
                                            Icons.remove,
                                            size: 14.0,
                                          ),
                                          onPressed: () async {
                                            if (selectedQuantity > 0) {
                                              setState(() {
                                                selectedQuantity =
                                                    selectedQuantity - 1;
                                              });
                                              await widget?.quantityChanged
                                                  .call(selectedQuantity,
                                                      currentList?[index]);
                                            }
                                          }),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.white,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text:
                                                    selectedQuantity.toString(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                          icon: new Icon(
                                            color: selectedQuantity
                                                        .toString() !=
                                                    currentList?[index].quantity
                                                ? Colors.white
                                                : Colors.black54,
                                            Icons.add,
                                            size: 14.0,
                                          ),
                                          onPressed: () async {
                                            if (selectedQuantity.toString() !=
                                                currentList?[index].quantity) {
                                              setState(() {
                                                selectedQuantity =
                                                    selectedQuantity + 1;
                                              });
                                              await widget?.quantityChanged
                                                  .call(selectedQuantity,
                                                      currentList?[index]);
                                            }
                                          }),
                                    ],
                                  )
                                : new Container()),
                          ])
                    : new Container()
                : (currentList?[index].headingTitle?.toLowerCase() == "other" &&
                        (currentList ?? [])
                                .where((element) =>
                                    !(element.isBomSpecific ?? true) &&
                                    (element.isSparePart ?? false) &&
                                    (element.quantity != "0"))
                                .toList()
                                .length >
                            0)
                    ? new Container(
                        child: Text(
                        currentList?[index].headingTitle ?? "",
                        style: TextStyle(color: Colors.black54),
                      ))
                    : (currentList?[index].headingTitle?.toLowerCase() ==
                                "part of bom" &&
                            (currentList ?? [])
                                    .where((element) =>
                                        (element.isBomSpecific ?? true) &&
                                        (element.isSparePart ?? false) &&
                                        (element.quantity != "0"))
                                    .toList()
                                    .length >
                                0)
                        ? new Container(
                            child: Text(
                            currentList?[index].headingTitle ?? "",
                            style: TextStyle(color: Colors.black54),
                          ))
                        : new Container(),
            onTap: () async {
              if (currentList?[index].isSparePart ?? false) {
                setState(() {
                  selectedQuantity = 1;
                  currentList?[index].selectedQuantity = 1;
                });
                await tappedOnItem?.call(index, isLeft);
              }
            }));
  }
}
