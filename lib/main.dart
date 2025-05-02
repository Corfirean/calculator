import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      minimumSize: const Size(500, 700),
      maximumSize: const Size(800, 1200),
    );
    await windowManager.setMinimumSize(windowOptions.minimumSize!);
    await windowManager.setMaximumSize(windowOptions.maximumSize!);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent[400]!,
          secondary: Colors.tealAccent[400]!,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var userInput = '';
  var answer = '0';
  bool shouldResetInput = false;
  bool _shouldStartNewExpression = false;

  static const double minButtonSize = 60.0;
  static const double spacing = 8.0;

  final List<String> buttons = [
    'C', '+/-', '%', 'DEL',
    '(', ')', '^', '/',
    '7', '8', '9', 'x',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '0', '.', '=', ''
  ];

  Widget buildButton(String buttonText, double size) {
    if (buttonText.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: getButtonColor(buttonText),
        borderRadius: BorderRadius.circular(size / 2),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () => onButtonPressed(buttonText),
          splashColor: Colors.tealAccent[400]!.withOpacity(0.3),
          highlightColor: Colors.tealAccent[400]!.withOpacity(0.1),
          child: Center(
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: size * 0.35,
                color: getTextColor(buttonText),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonAreaHeight = constraints.maxHeight * 0.6;
            final buttonSize = min(
              (constraints.maxWidth - spacing * 5) / 4,
              (buttonAreaHeight - spacing * 6) / 5,
            );
            return Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            userInput,
                            style: const TextStyle(fontSize: 24, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          answer,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(spacing),
                  child: GridView.count(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: buttons.map((button) {
                    return buildButton(button, buttonSize);
                    }).toList(),
                    ),
                  ),
               ]
             );
          },
        ),
      ),
    );
  }


  bool isParenthesesBalanced(String expr) {
    int balance = 0;
    for (var char in expr.split('')) {
      if (char == '(') balance++;
      if (char == ')') balance--;
      if (balance < 0) return false;
    }
    return balance == 0;
  }

  bool isOperator(String x) {
    return ['/', 'x', '-', '+', '%', '^'].contains(x);
  }

  Color getButtonColor(String buttonText) {
    if (buttonText == 'C') return Colors.grey[850]!;
    if (buttonText == 'DEL') return Colors.grey[850]!;
    if (buttonText == '=') return Colors.tealAccent[400]!;
    if (buttonText == '(' || buttonText == ')') return Colors.grey[800]!;
    if (isOperator(buttonText)) return Colors.grey[800]!;
    return Colors.grey[900]!;
  }

  Color getTextColor(String buttonText) {
    if (buttonText == '=') return Colors.black;
    if (isOperator(buttonText)) return Colors.tealAccent[400]!;
    if (buttonText == 'C' || buttonText == 'DEL') return Colors.tealAccent[400]!;
    return Colors.white;
  }

  void onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText.isEmpty) return;

      if (buttonText == '(' || buttonText == ')') {
        handleParenthesis(buttonText);
        return;
      }

      if (buttonText == 'C') {
        userInput = '';
        answer = '0';
        shouldResetInput = false;
        return;
      }

      if (buttonText == 'DEL') {
        if (userInput.isNotEmpty) {
          userInput = userInput.substring(0, userInput.length - 1);
          shouldResetInput = false;
        }
        return;
      }

      if (buttonText == '=') {
        equalPressed();
        return;
      }

      if (_shouldStartNewExpression && isOperator(buttonText)) {
        userInput = answer + buttonText;
        _shouldStartNewExpression = false;
        return;
      }

      if (isOperator(buttonText)) {
        if (userInput.isEmpty && buttonText == '-') {
          userInput = '-';
          return;
        }
        
        if (userInput.isEmpty) return;

        final lastChar = userInput[userInput.length - 1];

        if (isOperator(lastChar)) {
          if (buttonText == '-') {
            if (lastChar != '-') {
              userInput += '-';
            }
          } else {
            while (userInput.isNotEmpty && isOperator(userInput[userInput.length - 1])) {
              userInput = userInput.substring(0, userInput.length - 1);
            }
            userInput += buttonText;
          }
        } else {
          userInput += buttonText;
        }
      } else {
        if (answer != '0' && userInput.isEmpty) {
          userInput = buttonText;
          answer = '0';
        } else {
          userInput += buttonText;
        }
      }
    });
  }

  void handleParenthesis(String parenthesis) {
    if (parenthesis == '(') {
      if (userInput.isNotEmpty && 
          !isOperator(userInput[userInput.length - 1]) && 
          userInput[userInput.length - 1] != '(') {
        userInput += '*(';
      } else {
        userInput += '(';
      }
    } else {
      userInput += ')';
    }
  }

  Future<void> equalPressed() async {
    try {
      if (userInput.isEmpty) {
        setState(() => answer = "Error: Empty input");
        return;
      }

      if (!isParenthesesBalanced(userInput)) {
        setState(() => answer = "Error: Unbalanced parentheses");
        return;
      }

      final operatorMatch = RegExp(r'([\+\-\x\*\/\%\^])').firstMatch(userInput);
      if (operatorMatch == null) {
        setState(() => answer = "Error: No operator found");
        return;
      }

      String expression = userInput.replaceAll('x', '*');

      final response = await http.post(
        Uri.parse('http://localhost:8080/calc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'expression': expression,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => answer = data['result'].toString());
        _shouldStartNewExpression = true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        setState(() => answer = "Server error: $error");
      }
    } catch (e) {
      setState(() => answer = "Error: ${e.toString()}");
    }
  }
}