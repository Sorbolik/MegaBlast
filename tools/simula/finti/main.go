// Giocatori finti per provare l'online nel simulatore (comando "server" degli
// scenari, tools/simula/README.md): entrano in coda, nel draft prendono
// l'ultima carta di primarie e secondarie, premono PRONTO e in partita, quando tocca a loro,
// sparano un colpo.
//
//	go run ./tools/simula/finti -url ws://127.0.0.1:8090/ws -modo 2v2 -n 3
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
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
		// la vetrina del finto: i quattro pezzi di una famiglia (il secondo forgiato: livello 30)
		vetrina := ""
		if len(famiglie) > 0 {
			f, liv := famiglie[i%len(famiglie)], 1+29*(i%2)
			pz := fmt.Sprintf(`{"set":%q,"liv":%d}`, f, liv)
			vetrina = fmt.Sprintf(`,"vetrina":{"liv":%d,"pz":[%s,%s,%s,%s]}`, 5+i, pz, pz, pz, pz)
			// e quello che conta per le statistiche del robot (server/net.lua, equip_stats)
			vetrina += fmt.Sprintf(`,"eq":{"liv":%d,"gear":{"mask":%q,"chest":%q,"legs":%q,"cloak":%q},"lv":{"mask":%d,"chest":%d,"legs":%d,"cloak":%d}}`,
				5+i, f, f, f, f, liv, liv, liv, liv)
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

func gioca(url, modo, vetrina string) error {
	ctx := context.Background()
	c, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		return err
	}
	defer c.CloseNow()
	c.SetReadLimit(1 << 20)
	manda := func(s string) { c.Write(ctx, websocket.MessageText, []byte(s)) }
	manda(fmt.Sprintf(`{"t":"hello","v":9,"mode":%q%s}`, modo, vetrina))
	scelto, sparato, you := false, -1, 0
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
			Robot  int      `json:"robot"`
			Phase  string   `json:"phase"`
			Robots []struct {
				Tu int `json:"tu"`
			} `json:"r"`
		}
		if json.Unmarshal(data, &m) != nil {
			continue
		}
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
		case "left":
			// nel log del server (scenari/esci_online.txt): chi è uscito lo sappiamo subito
			log.Printf("finto %d: il giocatore %d è uscito", you, m.Robot)
		case "state":
			if m.Cur == you && m.Phase == "aim" && len(m.Robots) >= you && m.Robots[you-1].Tu != sparato {
				sparato = m.Robots[you-1].Tu
				manda(`{"t":"fire","a":1.2,"p":0.5}`)
			}
		}
	}
}
