// Giocatori finti per provare l'online nel simulatore (comando "server" degli
// scenari, strumenti/simula/README.md): entrano in coda, nel draft prendono
// l'ultima carta di primarie e secondarie e in partita, quando tocca a loro,
// sparano un colpo.
//
//	go run ./strumenti/simula/finti -url ws://127.0.0.1:8090/ws -modo 2v2 -n 3
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/coder/websocket"
)

func main() {
	url := flag.String("url", "ws://127.0.0.1:8090/ws", "indirizzo del server")
	modo := flag.String("modo", "1v1", "coda in cui entrare")
	n := flag.Int("n", 1, "quanti giocatori finti")
	attesa := flag.Duration("attesa", time.Second, "attesa prima di entrare in coda (il giocatore vero entra per primo)")
	flag.Parse()
	time.Sleep(*attesa)
	var wg sync.WaitGroup
	for i := 0; i < *n; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := gioca(*url, *modo); err != nil {
				log.Printf("finto: %v", err)
			}
		}()
		time.Sleep(100 * time.Millisecond)
	}
	wg.Wait()
}

func gioca(url, modo string) error {
	ctx := context.Background()
	c, _, err := websocket.Dial(ctx, url, nil)
	if err != nil {
		return err
	}
	defer c.CloseNow()
	c.SetReadLimit(1 << 20)
	manda := func(s string) { c.Write(ctx, websocket.MessageText, []byte(s)) }
	manda(fmt.Sprintf(`{"t":"hello","v":3,"mode":%q}`, modo))
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
