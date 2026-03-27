import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      themeMode: _themeMode,
      theme: ThemeData(
        primaryColor: Color(0xFF6FE6FC),
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF6FE6FC),
          secondary: Color(0xFF4FD8F0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6FE6FC), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: TextStyle(color: Colors.black),
          menuStyle: MenuStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.blueGrey[800],
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blueGrey[800]!,
          secondary: Colors.blueGrey[600]!,
          surface: Colors.grey[900]!,
          background: Colors.grey[850]!,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF6FE6FC), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: TextStyle(color: Colors.white),
          menuStyle: MenuStyle(
            backgroundColor: MaterialStateProperty.all(Colors.grey[900]),
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(toggleTheme: toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
      },
    );
  }
}

// Task model to represent data
class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  Timestamp createdAt;
  Timestamp? dueDate; // Add due date field
  String priority; // High, Medium, Low
  String category; // Work, Personal, etc.

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.priority = 'Medium',
    this.category = 'General',
  });

  // Convert Task object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'priority': priority,
      'category': category,
    };
  }

  // Create Task object from Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      dueDate: data['dueDate'],
      priority: data['priority'] ?? 'Medium',
      category: data['category'] ?? 'General',
    );
  }

  // Calculate urgency based on due date
  String get urgency {
    if (dueDate == null) return 'No Due Date';
    
    final now = DateTime.now();
    final due = dueDate!.toDate();
    final difference = due.difference(now);
    
    if (difference.isNegative) return 'Overdue';
    if (difference.inDays == 0) return 'Due Today';
    if (difference.inDays == 1) return 'Due Tomorrow';
    if (difference.inDays <= 7) return 'Due This Week';
    return 'Due Later';
  }

  // Get color based on urgency
  Color get urgencyColor {
    switch (urgency) {
      case 'Overdue':
        return Colors.red;
      case 'Due Today':
        return Colors.orange;
      case 'Due Tomorrow':
        return Colors.deepOrange;
      case 'Due This Week':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class UserStats {
  int currentStreak;
  int longestStreak;
  int totalTasksCompleted;
  Map<String, int> badges;
  List<MoodEntry> moodHistory;

  UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTasksCompleted = 0,
    Map<String, int>? badges,
    List<MoodEntry>? moodHistory,
  }) : 
    badges = badges ?? {},
    moodHistory = moodHistory ?? [];

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalTasksCompleted': totalTasksCompleted,
      'badges': badges,
      'moodHistory': moodHistory.map((entry) => entry.toMap()).toList(),
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      totalTasksCompleted: map['totalTasksCompleted'] ?? 0,
      badges: Map<String, int>.from(map['badges'] ?? {}),
      moodHistory: (map['moodHistory'] as List<dynamic>?)
          ?.map((entry) => MoodEntry.fromMap(entry as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class MoodEntry {
  final String mood; // Happy, Neutral, Sad, etc.
  final String note;
  final Timestamp timestamp;
  final int productivityLevel; // 1-5 scale

  MoodEntry({
    required this.mood,
    required this.note,
    required this.timestamp,
    required this.productivityLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'note': note,
      'timestamp': timestamp,
      'productivityLevel': productivityLevel,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      mood: map['mood'] ?? 'Neutral',
      note: map['note'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      productivityLevel: map['productivityLevel'] ?? 3,
    );
  }
}

class PomodoroTimer extends StatefulWidget {
  final VoidCallback onComplete;
  
  const PomodoroTimer({
    super.key,
    required this.onComplete,
  });

  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int workDuration = 25 * 60; // 25 minutes in seconds
  static const int breakDuration = 5 * 60; // 5 minutes in seconds
  int _timeLeft = workDuration;
  bool _isRunning = false;
  bool _isWorkTime = true;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          if (_isWorkTime) {
            // Switch to break
            setState(() {
              _isWorkTime = false;
              _timeLeft = breakDuration;
            });
            _showBreakNotification();
          } else {
            // Switch to work
            setState(() {
              _isWorkTime = true;
              _timeLeft = workDuration;
            });
            widget.onComplete();
          }
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timeLeft = _isWorkTime ? workDuration : breakDuration;
    });
    _timer?.cancel();
  }

  void _showBreakNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Time for a break!'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Start Break',
          onPressed: _startTimer,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isWorkTime ? 'Work Time' : 'Break Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Text(
              _formatTime(_timeLeft),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> loginUser() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed.';
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Incorrect password.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF6FE6FC);
    final Color secondaryColor = Color(0xFF4FD8F0);

    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(primary: primaryColor),
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                secondaryColor,
              ],
            ),
          ),
          child: SafeArea(
        child: SingleChildScrollView(
              child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 60),
                      // Logo and Welcome Text
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.task_alt,
                          size: 60,
                          color: Colors.white,
                        ),
                ),
                SizedBox(height: 40),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 60),
                      // Login Form
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                TextFormField(
                  controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(color: primaryColor),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                ),
                  validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email cannot be empty';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: primaryColor,
                                    ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle: TextStyle(color: primaryColor),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password cannot be empty';
                                  }
                    return null;
                  },
                ),
                              SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                  ),
                ),
                              SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                                height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      loginUser();
                                    }
                    },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                      SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> registerUser() async {
    try {
      // Register the user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Store user data in Firestore
      User? user = userCredential.user;
      if (user != null) {
        // Create a batch to perform multiple operations
        WriteBatch batch = FirebaseFirestore.instance.batch();
        
        // Reference to the user document
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        // Reference to the user stats document
        DocumentReference statsRef = userRef.collection('stats').doc('user_stats');
        
        // Set initial user data
        batch.set(userRef, {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });
        
        // Set initial stats
        batch.set(statsRef, {
          'currentStreak': 0,
          'longestStreak': 0,
          'totalTasksCompleted': 0,
          'badges': {},
          'moodHistory': [],
          'lastUpdate': FieldValue.serverTimestamp(),
        });
        
        // Commit the batch
        await batch.commit();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ));

        // Navigate to the login page after successful registration
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/');
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Registration failed.';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password should be at least 6 characters.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF6FE6FC);
    final Color secondaryColor = Color(0xFF4FD8F0);

    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(primary: primaryColor),
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                secondaryColor,
              ],
            ),
      ),
          child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    SizedBox(height: 40),
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Sign up to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 40),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                TextFormField(
                  controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: primaryColor),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                  validator: (value) => value!.isEmpty ? 'Enter a username' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: primaryColor),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                  validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email cannot be empty';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: primaryColor,
                                  ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: primaryColor),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password cannot be empty';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: primaryColor,
                                  ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: primaryColor),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirm password cannot be empty';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                    return null;
                  },
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                              height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    registerUser();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                  ),
                ),
              ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Reset theme to light mode before navigating to login
    if (isDarkMode) {
      toggleTheme();
    }
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30, color: Theme.of(context).primaryColor),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Task Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.task),
              title: Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.emoji_events),
              title: Text('Streaks & Rewards'),
              subtitle: Text('Track your progress'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StreaksPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.timer),
              title: Text('Pomodoro Timer'),
              subtitle: Text('Focus on your tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PomodoroPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.mood),
              title: Text('Mood Tracker'),
              subtitle: Text('Track your daily mood'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MoodTrackerPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: TaskListScreen(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addTask',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTaskScreen()),
              );
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage()),
              );
            },
            child: Icon(Icons.dashboard),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('stats')
            .doc('user_stats')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
        child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading stats: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry loading
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          UserStats stats = UserStats.fromMap(
            snapshot.data?.data() as Map<String, dynamic>? ?? {}
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section with gradient background
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Here\'s your productivity overview',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Section
                      Text(
                        'Quick Stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Current Streak',
                              '${stats.currentStreak}',
                              'days',
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Tasks Done',
                              '${stats.totalTasksCompleted}',
                              'tasks',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Achievements',
                              '${stats.badges.length}',
                              'unlocked',
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24), // Add spacing between stats and actions
                      // Quick Actions Section
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
            Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Start Timer',
                              'Focus on your tasks',
                              Icons.timer,
                              Colors.blue,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PomodoroPage()),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'Track Mood',
                              'Record your feelings',
                              Icons.mood,
                              Colors.purple,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MoodTrackerPage()),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16),
            Expanded(
                            child: _buildQuickActionCard(
                              context,
                              'View Rewards',
                              'Check achievements',
                              Icons.emoji_events,
                              Colors.amber,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => StreaksPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Recent Activity Section
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('tasks')
                            .orderBy('createdAt', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, taskSnapshot) {
                          if (!taskSnapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          return Column(
                            children: taskSnapshot.data!.docs.map((doc) {
                              Task task = Task.fromFirestore(doc);
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: task.isCompleted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: task.isCompleted ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(task.priority).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                            child: Text(
                                              task.priority,
                                              style: TextStyle(
                                                color: _getPriorityColor(task.priority),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              task.category,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 24),

                      // Mood Summary Section
                      if (stats.moodHistory.isNotEmpty) ...[
                        Text(
                          'Mood Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stats.moodHistory.length > 1) // Only show chart if at least 2 entries
                                Container(
                                  height: 120,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: false),
                                      titlesData: FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _generateMoodSpots(stats.moodHistory),
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                          dotData: FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.blue.withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Recent Mood Entries',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => MoodTrackerPage()),
                                            );
                                          },
                                          icon: Icon(Icons.history, size: 18),
                                          label: Text('View All'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: stats.moodHistory.length > 3 ? 3 : stats.moodHistory.length,
                                      itemBuilder: (context, index) {
                                        final entry = stats.moodHistory[index];
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 12),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey.withOpacity(0.1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _getMoodColor(entry.mood).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  _getMoodIcon(entry.mood),
                                                  color: _getMoodColor(entry.mood),
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          entry.mood,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                              child: Text(
                                                            'Productivity: ${entry.productivityLevel}/5',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.blue,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (entry.note.isNotEmpty) ...[
                                                      SizedBox(height: 4),
                                                      Text(
                                                        entry.note,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[700],
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                    SizedBox(height: 4),
                                                    Text(
                                                      _formatDate(entry.timestamp),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
                        );
                      },
                    ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
          fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateMoodSpots(List<MoodEntry> moodHistory) {
    final spots = <FlSpot>[];
    for (int i = 0; i < moodHistory.length; i++) {
      final entry = moodHistory[i];
      final moodValue = _getMoodValue(entry.mood);
      spots.add(FlSpot(i.toDouble(), moodValue));
    }
    return spots;
  }

  double _getMoodValue(String mood) {
    switch (mood) {
      case 'Happy':
        return 5.0;
      case 'Good':
        return 4.0;
      case 'Neutral':
        return 3.0;
      case 'Tired':
        return 2.0;
      case 'Stressed':
        return 1.0;
      default:
        return 3.0;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Good':
        return Icons.sentiment_satisfied;
      case 'Neutral':
        return Icons.sentiment_neutral;
      case 'Tired':
        return Icons.sentiment_dissatisfied;
      case 'Stressed':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Neutral':
        return Colors.orange;
      case 'Tired':
        return Colors.deepOrange;
      case 'Stressed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class StreaksPage extends StatefulWidget {
  @override
  _StreaksPageState createState() => _StreaksPageState();
}

class _StreaksPageState extends State<StreaksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Streaks & Rewards'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('stats')
            .doc('user_stats')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading stats: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry loading
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          UserStats stats = UserStats.fromMap(
            snapshot.data?.data() as Map<String, dynamic>? ?? {}
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Progress',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Current Streak',
                              '${stats.currentStreak} days',
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                            _buildStatItem(
                              'Longest Streak',
                              '${stats.longestStreak} days',
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                            _buildStatItem(
                              'Tasks Completed',
                              '${stats.totalTasksCompleted}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 16),
                        _buildAchievementItem(
                          'First Task',
                          'Complete your first task',
                          Icons.star,
                          stats.totalTasksCompleted > 0,
                        ),
                        _buildAchievementItem(
                          'Task Master',
                          'Complete 10 tasks',
                          Icons.star,
                          stats.totalTasksCompleted >= 10,
                        ),
                        _buildAchievementItem(
                          'Streak Warrior',
                          'Maintain a 7-day streak',
                          Icons.star,
                          stats.currentStreak >= 7,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
          fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, bool unlocked) {
    return ListTile(
      leading: Icon(
        icon,
        color: unlocked ? Colors.amber : Colors.grey,
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: Icon(
        unlocked ? Icons.check_circle : Icons.lock,
        color: unlocked ? Colors.green : Colors.grey,
      ),
    );
  }
}

class PomodoroPage extends StatefulWidget {
  @override
  _PomodoroPageState createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  Future<void> _updateUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('user_stats')
        .update({
      'totalPomodoroSessions': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pomodoro Timer'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Focus Timer',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 20),
                      PomodoroTimer(
                        onComplete: _updateUserStats,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Use',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      _buildInstructionItem(
                        '1. Set your task',
                        'Choose what you want to work on',
                      ),
                      _buildInstructionItem(
                        '2. Start the timer',
                        'Work for 25 minutes',
                      ),
                      _buildInstructionItem(
                        '3. Take a break',
                        'Rest for 5 minutes',
                      ),
                      _buildInstructionItem(
                        '4. Repeat',
                        'Complete 4 sessions for a longer break',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
          fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoodTrackerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Tracker'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Mood',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 20),
                    MoodTracker(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood History',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('stats')
                          .doc('user_stats')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        UserStats stats = UserStats.fromMap(
                          snapshot.data?.data() as Map<String, dynamic>? ?? {}
                        );

                        if (stats.moodHistory.isEmpty) {
                          return Center(
                            child: Text('No mood entries yet'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: stats.moodHistory.length,
                          itemBuilder: (context, index) {
                            final entry = stats.moodHistory[index];
                            final mappedMood = _moodFromProductivity(entry.productivityLevel);
                            return ListTile(
                              leading: Icon(
                                _getMoodIcon(mappedMood),
                                color: _getMoodColor(mappedMood),
                              ),
                              title: Text(mappedMood),
                              subtitle: Text(
                                'Productivity: ${entry.productivityLevel}/5\n${entry.note}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatDate(entry.timestamp),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete entry',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Delete Mood Entry'),
                                          content: Text('Are you sure you want to delete this mood entry?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteMoodEntry(entry);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMoodEntry(MoodEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('user_stats')
        .update({
      'moodHistory': FieldValue.arrayRemove([entry.toMap()]),
    });
  }

  String _moodFromProductivity(int productivityLevel) {
    switch (productivityLevel) {
      case 1:
        return 'Happy';
      case 2:
        return 'Good';
      case 3:
        return 'Neutral';
      case 4:
        return 'Tired';
      case 5:
        return 'Stressed';
      default:
        return 'Neutral';
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Good':
        return Icons.sentiment_satisfied;
      case 'Neutral':
        return Icons.sentiment_neutral;
      case 'Tired':
        return Icons.sentiment_dissatisfied;
      case 'Stressed':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Neutral':
        return Colors.orange;
      case 'Tired':
        return Colors.deepOrange;
      case 'Stressed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}

// CRUD Screens Implementation

// Screen to display all tasks (Read operation)
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _searchQuery = '';
  String _selectedPriority = 'All';
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Due Date'; // Add sorting option
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Center(child: Text('Please login to view tasks'));
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.filter_alt, color: Theme.of(context).primaryColor),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      items: ['All', 'High', 'Medium', 'Low']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      items: ['All', 'Work', 'Personal', 'General']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      items: ['Due Date', 'Priority', 'Category', 'Created Date']
                          .map((sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(
                                  sort,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSortBy = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Checkbox(
                    value: _showCompleted,
                    onChanged: (value) {
                      setState(() {
                        _showCompleted = value!;
                      });
                    },
                  ),
                  Text('Show completed'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No tasks found. Add a new task!'));
        }
              
              var filteredTasks = snapshot.data!.docs
                  .map((doc) => Task.fromFirestore(doc))
                  .where((task) {
                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      if (!task.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                          !task.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return false;
                      }
                    }
                    // Apply priority filter
                    if (_selectedPriority != 'All' && task.priority != _selectedPriority) {
                      return false;
                    }
                    // Apply category filter
                    if (_selectedCategory != 'All' && task.category != _selectedCategory) {
                      return false;
                    }
                    // Apply completion filter
                    if (!_showCompleted && task.isCompleted) {
                      return false;
                    }
                    return true;
                  })
                  .toList();

              // Sort tasks based on selected sort option
              filteredTasks.sort((a, b) {
                switch (_selectedSortBy) {
                  case 'Due Date':
                    if (a.dueDate == null && b.dueDate == null) return 0;
                    if (a.dueDate == null) return 1;
                    if (b.dueDate == null) return -1;
                    return a.dueDate!.compareTo(b.dueDate!);
                  case 'Priority':
                    return _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority));
                  case 'Category':
                    return a.category.compareTo(b.category);
                  case 'Created Date':
                    return b.createdAt.compareTo(a.createdAt);
                  default:
                    return 0;
                }
              });
              
              if (filteredTasks.isEmpty) {
                return Center(child: Text('No tasks match your filters'));
              }
        
        return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
                  Task task = filteredTasks[index];
            return Dismissible(
              key: Key(task.id),
              background: Container(
                      decoration: BoxDecoration(
                color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                deleteTask(currentUser.uid, task.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Task deleted'))
                );
              },
              child: Card(
                      elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                                  fontSize: 18,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                            ),
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (bool? value) {
                          updateTaskStatus(currentUser.uid, task.id, value ?? false);
                        },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6),
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(task.priority).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.flag, size: 16, color: _getPriorityColor(task.priority)),
                                      SizedBox(width: 4),
                                      Text(
                                        task.priority,
                                        style: TextStyle(
                                          color: _getPriorityColor(task.priority),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.category, size: 16, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text(
                                        task.category,
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (task.dueDate != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: task.urgencyColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: task.urgencyColor),
                                        SizedBox(width: 4),
                                        Text(
                                          task.urgency,
                                          style: TextStyle(
                                            color: task.urgencyColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          );
                        },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
          ),
        ),
      ],
    );
  }

  int _getPriorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // Delete a task (Delete operation)
  Future<void> deleteTask(String userId, String taskId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }
  
  // Update task completion status (Update operation)
  Future<void> updateTaskStatus(String userId, String taskId, bool isCompleted) async {
    // Update task completion status
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'isCompleted': isCompleted,
    });

    // Only update stats if the task is being marked as completed
    if (isCompleted) {
      final statsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('user_stats');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsRef);
        if (!snapshot.exists) {
          transaction.set(statsRef, UserStats().toMap());
          return;
        }

        final stats = UserStats.fromMap(snapshot.data() as Map<String, dynamic>);
        stats.totalTasksCompleted++;
        
        // Update streak
        final lastUpdate = snapshot.data()?['lastUpdate'] as Timestamp?;
        final now = Timestamp.now();
        if (lastUpdate != null) {
          final daysSinceLastUpdate = (now.toDate().difference(lastUpdate.toDate()).inHours / 24).round();
          if (daysSinceLastUpdate == 1) {
            stats.currentStreak++;
            if (stats.currentStreak > stats.longestStreak) {
              stats.longestStreak = stats.currentStreak;
            }
          } else if (daysSinceLastUpdate > 1) {
            stats.currentStreak = 1;
          }
        }

        // Update badges based on achievements
        if (stats.totalTasksCompleted == 1) {
          stats.badges['first_task'] = 1;
        }
        if (stats.totalTasksCompleted >= 10) {
          stats.badges['task_master'] = 1;
        }
        if (stats.currentStreak >= 7) {
          stats.badges['streak_warrior'] = 1;
        }

        transaction.update(statsRef, {
          ...stats.toMap(),
          'lastUpdate': now,
        });
      });
    }
  }
}

// Screen to add a new task (Create operation)
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'General';
  DateTime? _selectedDueDate;
  
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null,
        'priority': _selectedPriority,
        'category': _selectedCategory,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task created successfully!'), backgroundColor: Colors.green)
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Task'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[850]
                                : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[850]
                                : Colors.grey[50],
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.priority_high),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[850]
                                      : Colors.grey[50],
                      ),
                      items: ['High', 'Medium', 'Low']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[850]
                                      : Colors.grey[50],
                      ),
                      items: ['Work', 'Personal', 'General']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
                        SizedBox(height: 20),
                        InkWell(
                          onTap: () => _selectDueDate(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today),
                                SizedBox(width: 12),
                                Text(
                                  _selectedDueDate == null
                                      ? 'Select Due Date'
                                      : 'Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDueDate == null
                                        ? Colors.grey
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createTask,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

// Screen to edit an existing task (Update operation)
class EditTaskScreen extends StatefulWidget {
  final Task task;
  
  const EditTaskScreen({super.key, required this.task});
  
  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isCompleted;
  late String _selectedPriority;
  late String _selectedCategory;
  late DateTime? _selectedDueDate;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _isCompleted = widget.task.isCompleted;
    _selectedPriority = widget.task.priority;
    _selectedCategory = widget.task.category;
    _selectedDueDate = widget.task.dueDate?.toDate();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }
  
  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isCompleted': _isCompleted,
        'priority': _selectedPriority,
        'category': _selectedCategory,
        'dueDate': _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task updated successfully!'), backgroundColor: Colors.green)
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e'), backgroundColor: Colors.red)
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: ['High', 'Medium', 'Low']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ['Work', 'Personal', 'General']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () => _selectDueDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 12),
                      Text(
                        _selectedDueDate == null
                            ? 'Select Due Date'
                            : 'Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                        style: TextStyle(
                          color: _selectedDueDate == null
                              ? Colors.grey
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _isCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isCompleted = value ?? false;
                      });
                    },
                  ),
                  Text('Mark as completed'),
                ],
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateTask,
                child: Text('Update Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen to view task details (Read operation)
class TaskDetailScreen extends StatelessWidget {
  final Task task;
  
  const TaskDetailScreen({super.key, required this.task});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTaskScreen(task: task),
                ),
              ).then((_) => Navigator.pop(context));
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              // Show confirmation dialog
              bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Task'),
                  content: Text('Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirmDelete == true) {
                User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('tasks')
                      .doc(task.id)
                      .delete();
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        task.isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: task.isCompleted ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  'Created at: ${task.createdAt.toDate().toString()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoodTracker extends StatefulWidget {
  @override
  _MoodTrackerState createState() => _MoodTrackerState();
}

class _MoodTrackerState extends State<MoodTracker> {
  String _selectedMood = 'Neutral';
  int _productivityLevel = 3;
  final _noteController = TextEditingController();

  final List<String> _moods = [
    'Happy',
    'Good',
    'Neutral',
    'Tired',
    'Stressed',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moods.map((mood) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMood = mood;
                });
              },
              child: Column(
                children: [
                  Icon(
                    _getMoodIcon(mood),
                    size: 32,
                    color: _selectedMood == mood ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  SizedBox(height: 4),
                  Text(
                    mood,
                    style: TextStyle(
                      color: _selectedMood == mood ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text('Productivity Level'),
        Slider(
          value: _productivityLevel.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: _productivityLevel.toString(),
          onChanged: (value) {
            setState(() {
              _productivityLevel = value.round();
            });
          },
        ),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Add a note about your day...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveMoodEntry,
          child: Text('Save Mood Entry'),
        ),
      ],
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy':
        return Icons.sentiment_very_satisfied;
      case 'Good':
        return Icons.sentiment_satisfied;
      case 'Neutral':
        return Icons.sentiment_neutral;
      case 'Tired':
        return Icons.sentiment_dissatisfied;
      case 'Stressed':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Future<void> _saveMoodEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final moodEntry = MoodEntry(
      mood: _selectedMood,
      note: _noteController.text,
      timestamp: Timestamp.now(),
      productivityLevel: _productivityLevel,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stats')
        .doc('user_stats')
        .update({
      'moodHistory': FieldValue.arrayUnion([moodEntry.toMap()]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mood entry saved!')),
    );

    _noteController.clear();
    setState(() {
      _selectedMood = 'Neutral';
      _productivityLevel = 3;
    });
  }
}
