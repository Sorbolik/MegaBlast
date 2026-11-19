package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
)

// The recovery code brings the profile to a new phone (with a new key: the
// old one stops working), a wrong code nothing; the panel finds, blocks and
// imports again (server/recovery.go).
func TestRecovery(t *testing.T) {
	url, acc := accountsServer(t)
	code, body := postProfile(t, url+"/profilo/nuovo", "", "")
	if code != http.StatusOK {
		t.Fatalf("nuovo: %d %s", code, body)
	}
	var a Account
	json.Unmarshal(body, &a)
	auth := "Profilo " + itoa(a.ID) + "." + a.Key
	if code, _ = postProfile(t, url+"/profilo/codice", "", ""); code != http.StatusUnauthorized {
		t.Fatalf("codice senza chiave: %d", code)
	}
	code, body = postProfile(t, url+"/profilo/codice", auth, "")
	var c struct {
		Code string `json:"codice"`
	}
	json.Unmarshal(body, &c)
	if code != http.StatusOK || len(c.Code) != 14 || cleanCode(c.Code) == "" {
		t.Fatalf("codice: %d %s", code, body)
	}
	if code, _ = postProfile(t, url+"/profilo/recupera", "", "ABCD-EFGH-JKMN"); code != http.StatusNotFound {
		t.Fatalf("codice sbagliato: %d", code)
	}
	// typed by hand: small letters and spaces count the same
	code, body = postProfile(t, url+"/profilo/recupera", "", strings.ToLower(strings.ReplaceAll(c.Code, "-", " ")))
	var back Account
	json.Unmarshal(body, &back)
	if code != http.StatusOK || back.ID != a.ID || back.Key == "" || back.Key == a.Key || back.Profile != a.Profile {
		t.Fatalf("recupero: %d %s", code, body)
	}
	if code, _ = postProfile(t, url+"/profilo/fai", auth, ""); code != http.StatusUnauthorized {
		t.Fatalf("la chiave vecchia vale ancora: %d", code)
	}
	auth = "Profilo " + itoa(a.ID) + "." + back.Key
	if code, _ = postProfile(t, url+"/profilo/fai", auth, ""); code != http.StatusOK {
		t.Fatalf("la chiave nuova: %d", code)
	}

	// the panel
	var out strings.Builder
	if err := profileAdmin(acc, []string{"cerca", "Diavoletto"}, &out); err != nil || !strings.Contains(out.String(), a.Name) ||
		!strings.Contains(out.String(), "livello 1") || !strings.Contains(out.String(), "ha il codice") {
		t.Fatalf("cerca: %v %q", err, out.String())
	}
	if err := profileAdmin(acc, []string{"blocca", itoa(a.ID)}, &out); err != nil {
		t.Fatal(err)
	}
	if code, _ = postProfile(t, url+"/profilo/fai", auth, ""); code != http.StatusForbidden {
		t.Fatalf("bloccato: %d", code)
	}
	if code, _ = postProfile(t, url+"/profilo/recupera", "", c.Code); code != http.StatusNotFound {
		t.Fatalf("recupero di un bloccato: %d", code)
	}
	if err := profileAdmin(acc, []string{"sblocca", itoa(a.ID)}, &out); err != nil {
		t.Fatal(err)
	}
	if code, _ = postProfile(t, url+"/profilo/fai", auth, ""); code != http.StatusOK {
		t.Fatalf("sbloccato: %d", code)
	}
	if err := profileAdmin(acc, []string{"reimporta", itoa(a.ID)}, &out); err == nil {
		t.Fatal("reimporta senza la copia del telefono")
	}
	out.Reset()
	if err := profileAdmin(acc, []string{"registro", itoa(a.ID)}, &out); err != nil {
		t.Fatal(err)
	}
	for _, k := range []string{"nascita", "codice", "recupero", "blocca", "sblocca"} {
		if !strings.Contains(out.String(), k) {
			t.Fatalf("registro senza %s: %q", k, out.String())
		}
	}
	if err := profileAdmin(acc, []string{"blocca", "999"}, &out); err == nil {
		t.Fatal("blocca un profilo che non c'è")
	}
}
