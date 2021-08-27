enum UserChangeEnum { PASS_KEY, USER_ID, WARDEN }

abstract class UserChangeListener {
  void update(UserChangeEnum? userChangeEnum);
}
