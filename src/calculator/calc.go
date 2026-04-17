// Package calculator provides minimal arithmetic operations and an HTTP
// server that exposes them. It exists as the SPEC-0009 dogfooding sample
// for the SAGE template; the public surface is intentionally narrow.
package calculator

import (
	"errors"
	"fmt"
)

// ErrDivByZero is returned by Div when the divisor is zero.
var ErrDivByZero = errors.New("calculator: division by zero")

// Add returns a + b.
func Add(a, b float64) float64 { return a + b }

// Sub returns a - b.
func Sub(a, b float64) float64 { return a - b }

// Mul returns a * b.
func Mul(a, b float64) float64 { return a * b }

// Div returns a / b, or ErrDivByZero when b == 0.
func Div(a, b float64) (float64, error) {
	if b == 0 {
		return 0, ErrDivByZero
	}
	return a / b, nil
}

// Apply dispatches on op and calls the matching function. Unknown ops
// return a wrapped error so callers can distinguish input errors from
// the math-specific ErrDivByZero.
func Apply(op string, a, b float64) (float64, error) {
	switch op {
	case "add":
		return Add(a, b), nil
	case "sub":
		return Sub(a, b), nil
	case "mul":
		return Mul(a, b), nil
	case "div":
		return Div(a, b)
	default:
		return 0, fmt.Errorf("calculator: unknown op %q", op)
	}
}
