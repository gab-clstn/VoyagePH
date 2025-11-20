/// Declared admin accounts (emails). Sign-in with these accounts will open the admin portal.
/// Replace or extend with your real admin emails or replace with a custom-claims check.
const List<String> adminEmails = [
  'voyageph.admin@gmail.com',
  // add more admin emails here
];

/// Optional hardcoded fallback admin credentials (insecure — for local/dev only).
/// If you use this, remove in production and create the admin user in Firebase Authentication.
const String hardcodedAdminEmail = 'voyageph.admin@gmail.com';
const String hardcodedAdminPassword = 'admin'; // <- set to desired dev password