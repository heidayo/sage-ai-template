package calculator_test

import (
	"errors"
	"testing"

	calc "github.com/heidayo/sage-ai-template/src/calculator"
)

func TestAdd加算が正しく動作する(t *testing.T) {
	if got := calc.Add(2, 3); got != 5 {
		t.Fatalf("Add(2,3) = %v, want 5", got)
	}
}

func TestSub減算が正しく動作する(t *testing.T) {
	if got := calc.Sub(10, 4); got != 6 {
		t.Fatalf("Sub(10,4) = %v, want 6", got)
	}
}

func TestMul乗算が正しく動作する(t *testing.T) {
	if got := calc.Mul(6, 7); got != 42 {
		t.Fatalf("Mul(6,7) = %v, want 42", got)
	}
}

func TestDiv除算が正しく動作する(t *testing.T) {
	got, err := calc.Div(20, 4)
	if err != nil {
		t.Fatalf("Div(20,4) unexpected error: %v", err)
	}
	if got != 5 {
		t.Fatalf("Div(20,4) = %v, want 5", got)
	}
}

func TestDiv0除算でエラーを返す(t *testing.T) {
	_, err := calc.Div(1, 0)
	if !errors.Is(err, calc.ErrDivByZero) {
		t.Fatalf("Div(1,0) err = %v, want ErrDivByZero", err)
	}
}

func TestApply既知opが計算結果を返す(t *testing.T) {
	cases := []struct {
		op   string
		a, b float64
		want float64
	}{
		{"add", 1, 2, 3},
		{"sub", 5, 3, 2},
		{"mul", 4, 5, 20},
		{"div", 9, 3, 3},
	}
	for _, c := range cases {
		got, err := calc.Apply(c.op, c.a, c.b)
		if err != nil {
			t.Fatalf("Apply(%q,%v,%v) unexpected error: %v", c.op, c.a, c.b, err)
		}
		if got != c.want {
			t.Fatalf("Apply(%q,%v,%v) = %v, want %v", c.op, c.a, c.b, got, c.want)
		}
	}
}

func TestApply未知opでエラーを返す(t *testing.T) {
	_, err := calc.Apply("mod", 1, 2)
	if err == nil {
		t.Fatal("Apply(mod,1,2) err = nil, want error")
	}
}

func TestApply0除算はErrDivByZeroを返す(t *testing.T) {
	_, err := calc.Apply("div", 1, 0)
	if !errors.Is(err, calc.ErrDivByZero) {
		t.Fatalf("Apply(div,1,0) err = %v, want ErrDivByZero", err)
	}
}
