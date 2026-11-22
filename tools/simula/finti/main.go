// Giocatori finti per provare l'online nel simulatore (comando "server" degli
// scenari, tools/simula/README.md): entrano in coda, nel draft prendono
// l'ultima carta di primarie e secondarie, premono PRONTO e in partita, quando tocca a loro,
// sparano un colpo. Nel loro turno fanno come un telefono: mandano i tasti di
// ogni tick ("k", 60 al secondo), e la partita li aspetta.
//
//	go run ./tools/simula/finti -url ws://127.0.0.1:8090/ws -modo 2v2 -n 3
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/coder/websocket"
)

func main() {
	url := flag.String("url", "ws://127.0.0.1:8090/ws", "indirizzo del server")
	modo := flag.String("modo", "1v1", "coda in cui entrare")
	n := flag.Int("n", 1, "quanti giocatori finti")
	attesa := flag.Duration("attesa", time.Second, "attesa prima di entrare in coda (il giocatore vero entra per primo)")
	pezzi := flag.String("pezzi", "", "famiglie dei pezzi che indossano i finti, a turno (per esempio fornace,leviatano)")
	flag.Parse()
	famiglie := []string{}
	if *pezzi != "" {
		famiglie = strings.Split(*pezzi, ",")
	}
	time.Sleep(*attesa)
	var wg sync.WaitGroup
	for i := 0; i < *n; i++ {
		wg.Add(1)
		// il profilo del finto sul server, coi quattro pezzi di una famiglia (il
		// secondo forgiato: il server li taglia al livello 20, server/accounts.go):
		// il cartellino e le statistiche del robot online vengono da lì
		vetrina := ""
		if len(famiglie) > 0 {
			f, liv := famiglie[i%len(famiglie)], 1+29*(i%2)
			id, err := profilo(*url, f, liv, 5+i)
			if err != nil {
				log.Printf("finto: profilo non creato: %v", err)
			} else {
				vetrina = fmt.Sprintf(`,"profilo":%q`, id)
			}
		}
		go func() {
			defer wg.Done()
			if err := gioca(*url, *modo, vetrina); err != nil {
				log.Printf("finto: %v", err)
			}
		}()
		time.Sleep(100 * time.Millisecond)
	}
	wg.Wait()
}

// profilo crea sul server il profilo ospite di un finto (POST /profilo/nuovo,
// col profilo da importare scritto come le ricette, sim/replay.lua) e
// risponde "<id>.<chiave>" per il saluto
func profilo(url, famiglia string, liv, livello int) (string, error) {
	posti := []string{"mask", "chest", "legs", "cloak"}
	var pos, pz, gear []string
	for _, p := range posti {
		k := famiglia + "_" + p
		pos = append(pos, fmt.Sprintf(`[%q]=true`, k))
		pz = append(pz, fmt.Sprintf(`[%q]=%d`, k, liv))
		gear = append(gear, fmt.Sprintf(`[%q]=%q`, p, famiglia))
	}
	testo := fmt.Sprintf(`{["versione"]=2,["livello"]=%d,["posseduti"]={%s},["pezzi"]={%s},["loadouts"]={{["gear"]={%s}}}}`,
		livello, strings.Join(pos, ","), strings.Join(pz, ","), strings.Join(gear, ","))
	h := "http" + strings.TrimSuffix(strings.TrimPrefix(url, "ws"), "/ws") + "/profilo/nuovo?p=finto"
	res, err := http.Post(h, "text/plain", strings.NewReader(testo))
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	var a struct {
		ID  int64  `json:"id"`
		Key string `json:"chiave"`
	}
	if err := json.NewDecoder(res.Body).Decode(&a); err != nil || a.ID == 0 {
		return "", fmt.Errorf("risposta %d", res.StatusCode)
	}
	return fmt.Sprintf("%d.%s", a.ID, a.Key), nil
}

func gioca(url, modo, vetrina string) error {
	ctx := context.Background()
	c, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		return err
	}
	defer c.CloseNow()
	c.SetReadLimit(1 << 20)
	manda := func(s string) { c.Write(ctx, websocket.MessageText, []byte(s)) }
	manda(fmt.Sprintf(`{"t":"hello","v":11,"mode":%q%s}`, modo, vetrina))
	scelto, sparato, you := false, -1, 0
	// il tick da giocare, di chi è il turno e se sparare: li legge il ciclo
	// dei messaggi, li usa quello che manda i tasti
	var mu sync.Mutex
	cur, next, spara := 0, 0, false
	go func() {
		t := time.NewTicker(100 * time.Millisecond)
		defer t.Stop()
		for range t.C {
			mu.Lock()
			if you == 0 || cur != you {
				mu.Unlock()
				continue
			}
			codes := []string{"", "", "", "", "", ""}
			if spara {
				codes[0], spara = "fmissile,1.2,0.5", false
			}
			k, _ := json.Marshal(codes)
			msg := fmt.Sprintf(`{"t":"k","n":%d,"k":%s}`, next, k)
			next += len(codes)
			mu.Unlock()
			if c.Write(ctx, websocket.MessageText, []byte(msg)) != nil {
				return
			}
		}
	}()
	for {
		_, data, err := c.Read(ctx)
		if err != nil {
			return nil // partita finita o server chiuso
		}
		var m struct {
			T      string   `json:"t"`
			You    int      `json:"you"`
			Offer  []string `json:"offer"`
			Offer2 []string `json:"offer2"`
			Cur    int      `json:"cur"`
			N      int      `json:"n"`
			K      []string `json:"k"`
			Resume bool     `json:"resume"`
			Robot  int      `json:"robot"`
			Phase  string   `json:"phase"`
			Robots []struct {
				Tu int `json:"tu"`
			} `json:"r"`
		}
		if json.Unmarshal(data, &m) != nil {
			continue
		}
		mu.Lock()
		if m.You > 0 {
			you = m.You // in draft e start
		}
		switch m.T {
		case "draft":
			if !scelto {
				scelto = true
				manda(fmt.Sprintf(`{"t":"pick","w":%q}`, m.Offer[len(m.Offer)-1]))
				manda(fmt.Sprintf(`{"t":"pick","w":%q}`, m.Offer2[len(m.Offer2)-1]))
				manda(`{"t":"ready"}`) // PRONTO: senza aspettare il tempo
			}
		case "start":
			if !m.Resume {
				cur, next = m.Cur, 0
			}
		case "k":
			// i tasti giocati: chi è di turno, e da che tick si continua
			// (quelli già mandati restano in coda sul server)
			if m.Cur != cur || m.N+len(m.K) > next {
				next = m.N + len(m.K)
			}
			cur = m.Cur
		case "left":
			// nel log del server (scenari/esci_online.txt): chi è uscito lo sappiamo subito
			log.Printf("finto %d: il giocatore %d è uscito", you, m.Robot)
		case "state":
			if m.Cur == you && m.Phase == "aim" && len(m.Robots) >= you && m.Robots[you-1].Tu != sparato {
				sparato = m.Robots[you-1].Tu
				spara = true
			}
		}
		mu.Unlock()
	}
}
