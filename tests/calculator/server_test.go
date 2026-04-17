package calculator_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	calc "github.com/heidayo/sage-ai-template/src/calculator"
)

func do(t *testing.T, url string) (int, calc.Response) {
	t.Helper()
	srv := httptest.NewServer(calc.NewMux())
	defer srv.Close()

	resp, err := http.Get(srv.URL + url)
	if err != nil {
		t.Fatalf("http.Get(%s) error: %v", url, err)
	}
	defer resp.Body.Close()

	var body calc.Response
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatalf("decode %s: %v", url, err)
	}
	return resp.StatusCode, body
}

func TestServer正常系_加算(t *testing.T) {
	status, body := do(t, "/calc?op=add&a=1&b=2")
	if status != http.StatusOK {
		t.Fatalf("status = %d, want 200", status)
	}
	if body.Result != 3 {
		t.Fatalf("result = %v, want 3", body.Result)
	}
}

func TestServer正常系_除算(t *testing.T) {
	status, body := do(t, "/calc?op=div&a=10&b=4")
	if status != http.StatusOK || body.Result != 2.5 {
		t.Fatalf("status=%d result=%v, want 200 / 2.5", status, body.Result)
	}
}

func TestServer不正aパラメータで400(t *testing.T) {
	status, body := do(t, "/calc?op=add&a=xxx&b=2")
	if status != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", status)
	}
	if body.Error == "" {
		t.Fatal("expected error message, got empty")
	}
}

func TestServer不正bパラメータで400(t *testing.T) {
	status, _ := do(t, "/calc?op=add&a=1&b=yyy")
	if status != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", status)
	}
}

func TestServer0除算で422(t *testing.T) {
	status, body := do(t, "/calc?op=div&a=1&b=0")
	if status != http.StatusUnprocessableEntity {
		t.Fatalf("status = %d, want 422", status)
	}
	if body.Error == "" {
		t.Fatal("expected error message on div-by-zero")
	}
}

func TestServer未知opで400(t *testing.T) {
	status, body := do(t, "/calc?op=mod&a=1&b=2")
	if status != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", status)
	}
	if body.Error == "" {
		t.Fatal("expected error message for unknown op")
	}
}
