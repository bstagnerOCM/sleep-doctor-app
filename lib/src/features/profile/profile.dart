import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/settings_screen.dart';
import 'package:sleep_doctor/main.dart' as auth_provider;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  // Example placeholders to indicate login status and user info.
  // Replace these with your actual authentication logic.

  bool isLoggedIn = false;
  String? firstName;
  String? lastName;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
        final nameParts = user.displayName?.split(' ') ?? [];
        firstName = nameParts.isNotEmpty ? nameParts.first : null;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;
        profileImageUrl = user.photoURL;
      });
    }
  }

  void _loginWithApple() {
    // TODO: Implement Apple login logic here
    // After successful login, setState to update isLoggedIn and user details
  }

  Future<void> _loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // User is now signed in
      final user = userCredential.user;
      setState(() {
        isLoggedIn = user != null;
        if (user != null) {
          // Extract user details
          final nameParts = user.displayName?.split(' ') ?? [];
          firstName = nameParts.isNotEmpty ? nameParts.first : null;
          lastName =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;
          profileImageUrl = user.photoURL;
        }
      });
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!authProvider.isLoggedIn) ...[
              const Text(
                "Login or Register",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.apple),
                  label: const Text("Login with Apple"),
                  onPressed: _loginWithApple,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/icons/google_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text("Login with Google"),
                  onPressed: _loginWithGoogle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  if (authProvider.profileImageUrl != null)
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(authProvider.profileImageUrl!),
                      radius: 30,
                    )
                  else
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${authProvider.firstName ?? ''} ${authProvider.lastName ?? ''}'
                          .trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Welcome back!"),
            ],
          ],
        ),
      ),
    );
  }
}
