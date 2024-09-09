# kcs-engineer-mobile--flutter

KHIND KCS Engineer App

/// Set [SideMenu] width according to displayMode and notify parent widget
double \_widthSize(SideMenuDisplayMode mode, BuildContext context) {
if (mode == SideMenuDisplayMode.open) {
Global.displayModeState.change(SideMenuDisplayMode.open);
Future.delayed(\_toggleDuration(), () {
Global.showTrailing = true;
for (var update in Global.itemsUpdate) {
update();
}
});
\_notifyParent();
return 85;
}
if (mode == SideMenuDisplayMode.compact) {
if (Global.displayModeState.value != SideMenuDisplayMode.compact) {
Global.displayModeState.change(SideMenuDisplayMode.compact);
\_notifyParent();
Global.showTrailing = false;
}
return 85;
}
return 85;
}
