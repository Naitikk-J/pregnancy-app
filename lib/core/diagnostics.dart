/// TEMP diagnostic sink. Holds the underlying error from `Firebase.initializeApp`
/// so the splash can display the real reason instead of the downstream
/// `[core/no-app]`. Remove once the release startup issue is resolved.
String? firebaseInitError;
