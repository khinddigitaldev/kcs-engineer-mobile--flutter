import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class JobItem extends StatefulWidget {
  final double width;
  final Job job;
  final int index;
  final List<Job>? history;

  JobItem(
      {required this.width,
      required this.job,
      required this.index,
      required this.history});

  @override
  _JobItemState createState() => new _JobItemState();
}

class _JobItemState extends State<JobItem> {
  Job? job;
  int? index;
  double? width;
  List<Job>? history;

  @override
  void initState() {
    super.initState();
    job = widget.job;
    index = widget.index;
    history = widget.history;
    width = widget.width;
  }

  final imageUrls = [
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png"
  ];

  Color getColor() {
    if (job?.serviceJobStatus?.toLowerCase() == "request created" ||
        job?.serviceJobStatus == "PENDING REPAIR") {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(width: 0.1),
        color: getColor(),
        boxShadow: [
          BoxShadow(
              blurRadius: 5, color: Colors.grey[200]!, offset: Offset(0, 10)),
        ],
        borderRadius: BorderRadius.circular(7.5),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.blue,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: job != null
                                          ? '# ${job?.serviceJobNo}'.toString()
                                          : '#-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            (job?.isPaid ?? false)
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF56C568),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Center(
                                        child: Text(
                                          'Paid',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : new Container(),
                            SizedBox(
                              width: 20,
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.2,
                              height: MediaQuery.of(context).size.height * 0.03,
                              child: Stack(
                                children: List.generate(4, (index) {
                                  double position = index.toDouble() *
                                      25; // Adjust the overlapping position
                                  return Positioned(
                                    left: position,
                                    child: Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 2.0)),
                                        child: CircleAvatar(
                                          radius: 15.0,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  imageUrls[index]),
                                        )),
                                  );
                                }),
                              ),
                            )
                          ]),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF323F4B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                child: Center(
                                  child: Text(
                                    '${job != null ? job?.serviceType : ""}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF56C568),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                child: Center(
                                  child: Text(
                                    '${job?.serviceJobStatus}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ])
                    ]),
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black87,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: job?.serviceDate != null
                                            ? job?.serviceDate
                                            : '-',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              // RichText(
                              //   text: TextSpan(
                              //
                              //
                              //     style: const TextStyle(
                              //       fontSize: 14.0,
                              //       color: Colors.red,
                              //     ),
                              //     children: <TextSpan>[
                              //       TextSpan(
                              //           text: job.serviceTime != null
                              //               ? job.serviceTime
                              //               : '10:00 AM TO 02:00PM',
                              //           style: const TextStyle(
                              //               fontWeight: FontWeight.bold)),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black45,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      // text:
                                      //     "3517 W. Gray St. Utica, Pennsylvania 57867",

                                      text: job != null
                                          ? '${job?.serviceAddressStreet},${job?.serviceAddressCity},${job?.serviceAddressPostcode},${job?.serviceAddressState}, '
                                          : '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 10,
                          ),
                          // RichText(
                          //   text: TextSpan(
                          //
                          //
                          //     style: const TextStyle(
                          //       fontSize: 14.0,
                          //       color: Colors.black87,
                          //     ),
                          //     children: <TextSpan>[
                          //       TextSpan(
                          //           text: job != null
                          //               ? job.postcode
                          //                   .toString()
                          //                   .replaceAll("\n", " ")
                          //               : '',
                          //           style: const TextStyle(
                          //               fontWeight: FontWeight.bold)),
                          //     ],
                          //   ),
                          // ),
                          SizedBox(
                            height: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black54,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text: job != null
                                    ? '${job?.customerName} (${job?.customerTelephone})'
                                    : '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black45,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text:
                                    job != null ? job?.productDescription : '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black45,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text: job != null ? job?.productCode : '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  )),
                  Container(
                      alignment: Alignment.topRight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0,
                                MediaQuery.of(context).size.height * 0.03),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                this.job?.serviceAddressStreet != ""
                                    ? GestureDetector(
                                        onTap: () async {
                                          var address = this
                                              .job
                                              ?.serviceAddressStreet
                                              ?.replaceAll("\n", "");
                                          launch(
                                              "https://www.google.com/maps/search/?api=1&query=${'${job?.serviceAddressStreet},${job?.serviceAddressCity},${job?.serviceAddressPostcode},${job?.serviceAddressState},'}");
                                        },
                                        child: Icon(
                                          // <-- Icon
                                          Icons.location_pin,
                                          color: Colors.black54,
                                          size: 25.0,
                                        ),
                                      )
                                    : new Container(),
                                SizedBox(
                                  width: 10,
                                ),
                                Icon(
                                  Icons.navigate_next_outlined,
                                  color: Colors.black54,
                                  size: 25.0,
                                ),
                              ],
                            ),
                          )
                        ],
                      )),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: ReadMoreText(
                    job != null
                        ? job?.remarks
                                .toString()
                                .toLowerCase()
                                .replaceAll("\n", " ") ??
                            "-"
                        : '-',
                    trimLines: 2,
                    colorClickableText: Colors.black54,
                    trimMode: TrimMode.Line,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black54,
                    ),
                    trimCollapsedText: 'Show more',
                    trimExpandedText: 'Show less',
                    moreStyle:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  // RichText(
                  //   text: TextSpan(
                  //
                  //
                  //     style: const TextStyle(
                  //       fontSize: 14.0,
                  //       color: Colors.black54,
                  //     ),
                  //     children: <TextSpan>[
                  //       TextSpan(
                  //           text: job != null
                  //               ? job.problem
                  //                   .toString()
                  //                   .toLowerCase()
                  //                   .replaceAll("\n", " ")
                  //               : 'Changed order missed by pro',
                  //           style: const TextStyle(
                  //               fontWeight: FontWeight.bold)),
                  //     ],
                  //   ),
                  // ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: Row(
                  children: [
                    Icon(
                      // <-- Icon
                      Icons.chat_outlined,
                      color: Colors.black54,
                      size: 19.0,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Container(
                      width: 500,
                      child: ReadMoreText(
                        (job?.actualProblemCode != null
                            ? job?.actualProblemDescription != null
                                ? (job?.actualProblemDescription
                                        .toString()
                                        .toLowerCase() ??
                                    "")
                                : (job?.reportedProblemCode != null
                                    ? job?.reportedProblemCode
                                            .toString()
                                            .toLowerCase() ??
                                        ""
                                    : "-")
                            : ""),
                        trimLines: 2,
                        colorClickableText: Colors.black54,
                        trimMode: TrimMode.Line,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.red,
                        ),
                        trimCollapsedText: 'Show more',
                        trimExpandedText: 'Show less',
                        moreStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      // RichText(
                      //   maxLines: 5,
                      //   text: TextSpan(
                      //
                      //
                      //     style: const TextStyle(
                      //       fontSize: 14.0,
                      //       color: Colors.red,
                      //     ),
                      //     children: <TextSpan>[
                      //       TextSpan(
                      //           text: job.comment != null
                      //               ? job.comment.toString().toLowerCase()
                      //               : '-',
                      //           style: const TextStyle(
                      //               fontWeight: FontWeight.bold)),
                      //     ],
                      //   ),
                      // ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
