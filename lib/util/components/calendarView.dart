import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/user.dart';
import 'package:kcs_engineer/themes/app_colors.dart';

class CalendarView extends StatefulWidget with WidgetsBindingObserver {
  int? selectedIndex;
  Function dateSelected;
  CalendarView({this.selectedIndex, required this.dateSelected});

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with WidgetsBindingObserver {
  var _refreshKey = GlobalKey<RefreshIndicatorState>();
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  User? user;
  int? selectedIndex;
  final storage = new FlutterSecureStorage();
  String? token;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedIndex;
    Future.delayed(Duration.zero, () {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          // await this._fetchJobs();
        },
        child: Scaffold(
          key: _scaffoldKey,
          body: CustomPaint(
              child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                                color: Colors.white,
                                height: MediaQuery.of(context).size.height * .1,
                                width: MediaQuery.of(context).size.width * 1,
                                child: Container(
                                    child: Scrollbar(
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    // controller: controller,
                                    shrinkWrap: true,
                                    itemCount: 8,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return Row(children: [
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                .03),
                                        GestureDetector(
                                          onTap: () async {},
                                          child: CalendarItem(
                                              key: ValueKey(index),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              isSelected:
                                                  index == selectedIndex,
                                              onSelectedDate: (index) async {
                                                var abc = widget.dateSelected;
                                                setState(() {
                                                  selectedIndex = index;
                                                });
                                                await widget.dateSelected
                                                    .call(index);
                                              },
                                              index: index),
                                        )
                                      ]);
                                    },
                                  ),
                                ))),
                          ])))),
        ));
  }
}

class CalendarItem extends StatelessWidget {
  const CalendarItem(
      {Key? key,
      required this.width,
      required this.index,
      required this.onSelectedDate,
      required this.isSelected})
      : super(key: key);

  final double width;

  final int index;
  final bool isSelected;
  final Function onSelectedDate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          await onSelectedDate.call(index);
        },
        child: Container(
            color: Colors.white,
            key: ValueKey(this.key),
            child: Container(
              width: MediaQuery.of(context).size.width * .1,
              decoration: BoxDecoration(
                border: Border.all(width: 0.1),
                boxShadow: [
                  BoxShadow(
                      blurRadius: 5,
                      color: Colors.white,
                      offset: Offset(0, 10)),
                ],
                borderRadius: BorderRadius.circular(7.5),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      index == 0
                          ? isSelected
                              ? RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 24.0,
                                        color: Color(0xFFFFB700),
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: "ALL",
                                        ),
                                      ]),
                                )
                              : RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 24.0,
                                        color: Color(0xFFD4D4D4),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: "ALL",
                                        ),
                                      ]),
                                )
                          : isSelected
                              ? RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 24.0,
                                          color: Color(0xFFFFB700),
                                          fontWeight: FontWeight.bold),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: getDateText(index),
                                        ),
                                      ]),
                                )
                              : RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 24.0,
                                          color: Color(0xFFD4D4D4),
                                          fontWeight: FontWeight.bold),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: getDateText(index),
                                        ),
                                      ]),
                                ),
                      SizedBox(
                        height: 10,
                      ),
                      index == 0
                          ? RichText(
                              text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 24.0,
                                      color: Colors.transparent,
                                      fontWeight: FontWeight.bold),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: '00',
                                    ),
                                  ]),
                            )
                          : isSelected
                              ? RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 24.0,
                                          color: Color(0xFFFFB700),
                                          fontWeight: FontWeight.bold),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: '${getDateNumber(index)}',
                                        ),
                                      ]),
                                )
                              : RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 24.0,
                                          color: Color(0xFFD4D4D4),
                                          fontWeight: FontWeight.bold),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: '${getDateNumber(index)}',
                                        ),
                                      ]),
                                ),
                      SizedBox(
                        height: 5,
                      ),
                      isSelected && index != 0
                          ? Container(
                              child: Divider(
                                color: AppColors.amber,
                                thickness: 4,
                              ),
                            )
                          : new Container(),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }

  getDateNumber(index) {
    DateTime dateTime = DateTime.now();
    if (index > 0) {
      dateTime = dateTime.add(Duration(days: index - 1));
    }

    return dateTime.day;
  }

  getDateText(index) {
    DateTime dateTime = DateTime.now();
    if (index > 0) {
      dateTime = dateTime.add(Duration(days: index - 1));
    }

    return getDayOfWeek(dateTime.weekday, dateTime.day);
  }

  getDayOfWeek(int weekday, int date) {
    switch (weekday) {
      case 1:
        return "MON";
      case 2:
        return "TUE";
      case 3:
        return "WED";
      case 4:
        return "THU";
      case 5:
        return "FRI";
      case 6:
        return "SAT";
      case 7:
        return "SUN";
      default:
        return "ALL";
    }
  }
}
