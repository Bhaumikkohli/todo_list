import 'dart:async';
import 'dart:convert';

import 'serialization_util.dart';
import '../backend.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../onboarding/onboarding_widget.dart';
import '../../register/register_widget.dart';
import '../../login/login_widget.dart';
import '../../task_details/task_details_widget.dart';
import '../../my_profile/my_profile_widget.dart';
import '../../edit_profile/edit_profile_widget.dart';
import '../../change_password/change_password_widget.dart';

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler(
      {Key key, this.handlePushNotification, this.child})
      : super(key: key);

  final Function(BuildContext) handlePushNotification;
  final Widget child;

  @override
  _PushNotificationsHandlerState createState() =>
      _PushNotificationsHandlerState();
}

class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  bool _loading = false;

  Future handleOpenedPushNotification() async {
    final notification = await FirebaseMessaging.instance.getInitialMessage();
    if (notification != null) {
      await _handlePushNotification(notification);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotification);
  }

  Future _handlePushNotification(RemoteMessage message) async {
    setState(() => _loading = true);
    try {
      final initialPageName = message.data['initialPageName'] as String;
      final initialParameterData = getInitialParameterData(message.data);
      final pageBuilder = pageBuilderMap[initialPageName];
      if (pageBuilder != null) {
        final page = await pageBuilder(initialParameterData);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    handleOpenedPushNotification();
  }

  @override
  Widget build(BuildContext context) => _loading
      ? Container(
          color: FlutterFlowTheme.customColor2,
          child: Center(
            child: Builder(
              builder: (context) => Image.asset(
                'assets/images/logo_splash.png',
                width: 150,
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        )
      : widget.child;
}

final pageBuilderMap = <String, Future<Widget> Function(Map<String, dynamic>)>{
  'Onboarding': (data) async => OnboardingWidget(),
  'Register': (data) async => RegisterWidget(),
  'Login': (data) async => LoginWidget(),
  'Dashboard': (data) async => NavBarPage(initialPage: 'DashboardWidget'),
  'CompletedTasks': (data) async =>
      NavBarPage(initialPage: 'CompletedTasksWidget'),
  'TaskDetails': (data) async => TaskDetailsWidget(
        toDoNote: getParameter(data, 'toDoNote'),
      ),
  'MyProfile': (data) async => MyProfileWidget(),
  'EditProfile': (data) async => EditProfileWidget(),
  'ChangePassword': (data) async => ChangePasswordWidget(),
};

bool hasMatchingParameters(Map<String, dynamic> data, Set<String> params) =>
    params.any((param) => getParameter(data, param) != null);

Map<String, dynamic> getInitialParameterData(Map<String, dynamic> data) {
  try {
    final parameterDataStr = data['parameterData'];
    if (parameterDataStr == null ||
        parameterDataStr is! String ||
        parameterDataStr.isEmpty) {
      return {};
    }
    return jsonDecode(parameterDataStr) as Map<String, dynamic>;
  } catch (e) {
    print('Error parsing parameter data: $e');
    return {};
  }
}
