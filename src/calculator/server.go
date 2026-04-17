package calculator

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
)

// Response is the JSON envelope returned by the HTTP handler.
type Response struct {
	Result float64 `json:"result,omitempty"`
	Error  string  `json:"error,omitempty"`
}

// NewMux builds an http.ServeMux with a single /calc endpoint that
// reads op/a/b from the query string and returns a JSON Response.
func NewMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/calc", handleCalc)
	return mux
}

func handleCalc(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	q := r.URL.Query()
	op := q.Get("op")
	aStr := q.Get("a")
	bStr := q.Get("b")

	a, err := strconv.ParseFloat(aStr, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid 'a' parameter")
		return
	}
	b, err := strconv.ParseFloat(bStr, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid 'b' parameter")
		return
	}

	result, err := Apply(op, a, b)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, ErrDivByZero) {
			status = http.StatusUnprocessableEntity
		}
		writeError(w, status, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, Response{Result: result})
}

func writeJSON(w http.ResponseWriter, status int, body Response) {
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, Response{Error: msg})
}
