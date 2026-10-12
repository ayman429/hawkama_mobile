/// Lets the HTTP client notify auth without a circular dependency.
class SessionEvents {
  void Function()? onUnauthorized;
}
