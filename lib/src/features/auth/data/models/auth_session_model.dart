import 'package:wr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    super.token = '',
    required super.userId,
    required super.userName,
    super.emailId = '',
    super.userRoleNameFk = '',
    super.userTypeFk = '',
    super.departmentFk = '',
    super.designation = '',
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      token: (json['token'] ?? json['accessToken'] ?? json['jwt'] ?? '')
          .toString(),
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? json['userId'] ?? 'User').toString(),
      emailId: (json['emailId'] ?? '').toString(),
      userRoleNameFk: (json['userRoleNameFk'] ?? '').toString(),
      userTypeFk: (json['userTypeFk'] ?? '').toString(),
      departmentFk: (json['departmentFk'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'userId': userId,
      'userName': userName,
      'emailId': emailId,
      'userRoleNameFk': userRoleNameFk,
      'userTypeFk': userTypeFk,
      'departmentFk': departmentFk,
      'designation': designation,
    };
  }
}
