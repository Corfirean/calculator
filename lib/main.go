package main

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
)

func enableCORS(w *http.ResponseWriter) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	(*w).Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func calcHandler(w http.ResponseWriter, r *http.Request) {
	enableCORS(&w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	var request struct {
		Expression string `json:"expression"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, `{"error":"Invalid JSON"}`, http.StatusBadRequest)
		return
	}

	result, err := evaluate(request.Expression)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error":"%v"}`, err), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]float64{"result": result})
}

func evaluate(expr string) (float64, error) {
	expr = strings.TrimSpace(expr)
	if len(expr) == 0 {
		return 0, fmt.Errorf("empty expression")
	}

	// баланс
	if !isBalanced(expr) {
		return 0, fmt.Errorf("unbalanced parentheses")
	}

	// удаляем внешние скобки если они есть
	expr = trimOuterParentheses(expr)

	// базовая операция
	if num, err := strconv.ParseFloat(expr, 64); err == nil {
		return num, nil
	}

	// возведение в степень с наивысшим приоритетом
	if index, _ := findOperator(expr, []string{"^"}); index != -1 {
		left, err := evaluate(expr[:index])
		if err != nil {
			return 0, err
		}
		right, err := evaluate(expr[index+1:])
		if err != nil {
			return 0, err
		}
		return math.Pow(left, right), nil
	}

	// ищем операторы с низким приоритетом (+,-)
	if index, op := findOperator(expr, []string{"+", "-"}); index != -1 {
		left, err := evaluate(expr[:index])
		if err != nil {
			return 0, err
		}
		right, err := evaluate(expr[index+1:])
		if err != nil {
			return 0, err
		}
		switch op {
		case "+":
			return left + right, nil
		case "-":
			return left - right, nil
		}
	}

	// ищем операторы с высоким приоритетом (*,/)
	if index, op := findOperator(expr, []string{"*", "/"}); index != -1 {
		left, err := evaluate(expr[:index])
		if err != nil {
			return 0, err
		}
		right, err := evaluate(expr[index+1:])
		if err != nil {
			return 0, err
		}
		switch op {
		case "*":
			return left * right, nil
		case "/":
			if right == 0 {
				return 0, fmt.Errorf("division by zero")
			}
			return left / right, nil
		}
	}

	return 0, fmt.Errorf("invalid expression: %s", expr)
}

func findOperator(expr string, ops []string) (int, string) {
	parenthesesCount := 0
	// Ищем справа налево операторы
	for i := len(expr) - 1; i >= 0; i-- {
		char := expr[i]
		if char == ')' {
			parenthesesCount++
		} else if char == '(' {
			parenthesesCount--
		} else if parenthesesCount == 0 {
			for _, op := range ops {
				if string(char) == op {
					if op == "-" && i == 0 {
						continue
					}
					return i, op
				}
			}
		}
	}
	return -1, ""
}

func isBalanced(expr string) bool {
	count := 0
	for _, char := range expr {
		switch char {
		case '(':
			count++
		case ')':
			count--
			if count < 0 {
				return false
			}
		}
	}
	return count == 0
}

func trimOuterParentheses(expr string) string {
	for strings.HasPrefix(expr, "(") && strings.HasSuffix(expr, ")") && isBalanced(expr[1:len(expr)-1]) {
		expr = expr[1 : len(expr)-1]
	}
	return expr
}

func main() {
	http.HandleFunc("/calc", calcHandler)
	fmt.Println("Go server running on http://localhost:8080")
	http.ListenAndServe(":8080", nil)
}
