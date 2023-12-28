// login exceptions
class InvalidCredentialsAuthException implements Exception {}

// register exceptions
class WeakPasswordAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

class EmailAlreadyTakenAuthException implements Exception {}

// generic exception
class GenericAuthException implements Exception {}

// application exceptions
class UserNotLoggedInAuthException implements Exception {}
