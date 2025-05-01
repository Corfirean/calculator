import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, devicetype) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: HomePage(),
    );
    }
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

 final List<String> buttons = [
  'C', '+/-', '%', 'DEL',
  '(', ')', '^', '/',
  '7', '8', '9', 'x',
  '4', '5', '6', '-',
  '1', '2', '3', '+',
  '0', '.', '=', ''
];

Widget buildButton(String buttonText) {
  if (buttonText.isEmpty) {
    return Container();
  } //пустая кнопка справа внизу, чтоб не рушить сетку
  
  return Material(
    color: getButtonColor(buttonText),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onButtonPressed(buttonText),
      child: Center(
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 24,
            color: getTextColor(buttonText),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Scientific Calculator"),
    ),
    body: Column(
      children: [
        Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Поле ввода выражения
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      userInput,
                      style: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Поле результата
                  Text(
                    answer,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ),
        // Кнопки
        Expanded(
          flex: 3,
          child: GridView.builder(
            itemCount: buttons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            padding: EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return buildButton(buttons[index]);
            },
          ),
        ),      
      ],
    ),
  );
}
//показываем баланс скобок
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
  if (buttonText == 'C') return Colors.red[400]!;
  if (buttonText == '=') return Colors.orange;
  if (buttonText == '(' || buttonText == ')') return Colors.blue[300]!;
  if (isOperator(buttonText)) return Colors.blue[700]!;
  return Colors.grey[200]!;
}

  Color getTextColor(String buttonText) {
    return (buttonText == 'C' || isOperator(buttonText) || buttonText == '=')
        ? Colors.white
        : Colors.black;
  }

//логика кнопок с проверкой отрицательных чисел
void onButtonPressed(String buttonText) {
    setState(() {

      if (buttonText.isEmpty) return;

          if (buttonText == '(' || buttonText == ')') {
      handleParenthesis(buttonText);
      return;
    }
    //добавление * между скобками, если нет другого оператора

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
      // Разрешаем минус в пустом поле
      if (userInput.isEmpty && buttonText == '-') {
        userInput = '-';
        return;
      }
      
      // Запрещаем другие операторы в пустом поле
      if (userInput.isEmpty) return;

      final lastChar = userInput[userInput.length - 1];

      // Если последний символ - оператор
      if (isOperator(lastChar)) {
        // Нажатие минуса после оператора (для отрицательных чисел)
        if (buttonText == '-') {
          // Разрешаем только один минус после оператора
          if (lastChar != '-') {
            userInput += '-';
          }
        } 
        // Нажатие другого оператора
        else {
          // Удаляем все операторы в конце
          while (userInput.isNotEmpty && isOperator(userInput[userInput.length - 1])) {
            userInput = userInput.substring(0, userInput.length - 1);
          }
          userInput += buttonText;
        }
      } 
      // Если последний символ - число
      else {
        userInput += buttonText;
      }
    } 
    // Обработка цифр и точки
    else {
      // Если было вычисление, начинаем новое выражение
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
    // Автоматически добавляем умножение перед открывающей скобкой, если нужно
    if (userInput.isNotEmpty && 
        !isOperator(userInput[userInput.length - 1]) && 
        userInput[userInput.length - 1] != '(') {
      userInput += '*(';
    } else {
      userInput += '(';
    }
  } else {
    // Просто добавляем закрывающую скобку
    userInput += ')';
  }
      }

//нажали =
Future<void> equalPressed() async {
  try {
    // проверка пустого ввода
    if (userInput.isEmpty) {
      setState(() => answer = "Error: Empty input");
      return;
    }

    // проверка баланса скобок
    if (!isParenthesesBalanced(userInput)) {
      setState(() => answer = "Error: Unbalanced parentheses");
      return;
    }

    // проверка операторов
    final operatorMatch = RegExp(r'([\+\-\x\*\/\%\^])').firstMatch(userInput);
    if (operatorMatch == null) {
      setState(() => answer = "Error: No operator found");
      return;
    }

    String expression = userInput.replaceAll('x', '*');

    // отправили на сервер
    final response = await http.post(
    Uri.parse('http://localhost:8080/calc'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
        'expression': expression,
      }),
);

    // проверка ответа
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
// виджет кнопок
class MyButton extends StatelessWidget {
  final Color? color;
  final Color textColor;
  final String buttonText;
  final VoidCallback? buttontapped;

  const MyButton({super.key, 
    this.color,
    this.textColor = Colors.black,
    required this.buttonText,
    this.buttontapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Material(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: buttontapped,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.blue.withOpacity(0.3),
          highlightColor: Colors.blue.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                buttonText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}