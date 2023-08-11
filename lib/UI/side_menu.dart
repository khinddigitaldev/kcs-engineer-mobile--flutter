import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:kcs_engineer/UI/jobHistory.dart';
import 'package:kcs_engineer/UI/jobs.dart';
import 'package:kcs_engineer/UI/payment_history.dart';
import 'package:kcs_engineer/UI/spareparts_history.dart';
import 'package:kcs_engineer/UI/user_profile.dart';
import 'package:kcs_engineer/history_icons_icons.dart';
import 'package:kcs_engineer/side_menu_icons_icons.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';

class MyHomePage extends StatefulWidget {
  int? data;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController page = PageController();
  SideMenuController sidemenuController = SideMenuController();

  @override
  void initState() {
    if (page == null) {
      page = PageController();
    }
    sidemenuController = SideMenuController();
    super.initState();
  }

  @override
  void dispose() {
    sidemenuController.dispose();
    super.dispose();
  }

  //PageController page = new PageController();

  Future<bool> _logout() async {
    return await Repositories.handleLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          renderSideMenu(),
          Expanded(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: page,
              children: [
                Container(
                  color: Colors.white,
                  child: Center(
                    child: JobList(),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: JobHistory(),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: new PaymentHistory(),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: SparepartHistory(),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: UserProfile(),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: new Container(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget renderSideMenu() {
    return SideMenu(
      controller: sidemenuController,
      alwaysShowFooter: true,
      showToggle: false,
      style: SideMenuStyle(
          displayMode: SideMenuDisplayMode.open,
          openSideMenuWidth: 80,
          iconSize: 53,
          itemHeight: 130,
          backgroundColor: const Color(0xFF242a38),
          compactSideMenuWidth: 90,
          hoverColor: const Color(0xFF191d27),
          selectedColor: const Color(0xFF191d27),
          unselectedTitleTextStyle: TextStyle(color: const Color(0xFF959595)),
          selectedTitleTextStyle: TextStyle(color: const Color(0xFFFFB700)),
          selectedIconColor: const Color((0xFFFFB700)),
          unselectedIconColor: const Color(0xFF959595)),
      items: [
        SideMenuItem(
          priority: 0,
          onTap: (index, controller) {
            sidemenuController.changePage(index);
            page.jumpToPage(index);
          },
          icon: const Icon(
            SideMenuIcons.home,
          ),
        ),
        SideMenuItem(
          priority: 1,
          onTap: (index, controller) {
            sidemenuController.changePage(index);
            page.jumpToPage(index);
          },
          icon: const Icon(
            HistoryIcons.job_history,
          ),
        ),
        SideMenuItem(
          priority: 2,
          onTap: (index, controller) {
            sidemenuController.changePage(index);
            page.jumpToPage(index);
          },
          icon: const Icon(
            HistoryIcons.payment_history,
          ),
        ),
        SideMenuItem(
          priority: 3,
          onTap: (index, controller) {
            sidemenuController.changePage(index);

            page.jumpToPage(index);
          },
          icon: const Icon(
            HistoryIcons.part_history,
            size: 10,
          ),
        ),
        SideMenuItem(
          priority: 4,
          onTap: (index, controller) {
            sidemenuController.changePage(index);
            page.jumpToPage(index);
          },
          icon: const Icon(SideMenuIcons.profile),
        ),
        SideMenuItem(
          priority: 5,
          onTap: (index, controller) async {
            Helpers.showAlert(context);
            var res = await _logout();
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'signIn');
            //Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(SideMenuIcons.logout),
        ),
      ],
    );
  }
}
