package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"
)

const (
	tickRate      = 60
	snapshotEvery = 3 // 20 stati al secondo
)

// Messaggio da un client: {"t":"in","l":true,"r":false} | {"t":"jump"} | {"t":"fire","a":1.2,"p":0.7}
type clientMsg struct {
	T string  `json:"t"`
	L bool    `json:"l"`
	R bool    `json:"r"`
	A float64 `json:"a"`
	P float64 `json:"p"`
}

type playerMsg struct {
	from int // 1 o 2
	msg  clientMsg
	left bool // il giocatore si è disconnesso
}

type held struct {
	left, right, jump, fire bool
	angle, power            float64
}

// Match è una partita 1 contro 1: una goroutine che fa girare la simulazione.
type Match struct {
	players [2]*Player
	in      chan playerMsg
	seed    int64
}

func NewMatch(a, b *Player, seed int64) *Match {
	m := &Match{players: [2]*Player{a, b}, in: make(chan playerMsg, 64), seed: seed}
	a.match, a.index = m, 1
	b.match, b.index = m, 2
	return m
}

func (m *Match) broadcast(msg string) {
	for _, p := range m.players {
		p.Send(msg)
	}
}

func (m *Match) Run() {
	sim, err := NewSim(m.seed)
	if err != nil {
		log.Printf("errore simulazione: %v", err)
		m.broadcast(`{"t":"error"}`)
		return
	}
	defer sim.Close()

	for _, p := range m.players {
		p.Send(fmt.Sprintf(`{"t":"start","seed":%d,"you":%d}`, m.seed, p.index))
	}

	var inputs [3]held
	ticker := time.NewTicker(time.Second / tickRate)
	defer ticker.Stop()

	for tick := 0; ; tick++ {
		select {
		case pm := <-m.in:
			if pm.left {
				m.broadcast(`{"t":"left"}`)
				return
			}
			h := &inputs[pm.from]
			switch pm.msg.T {
			case "in":
				h.left, h.right = pm.msg.L, pm.msg.R
			case "jump":
				h.jump = true
			case "fire":
				h.fire, h.angle, h.power = true, pm.msg.A, pm.msg.P
			}
			tick--
			continue
		case <-ticker.C:
		}

		cur := sim.Current()
		h := inputs[cur]
		if err := sim.Step(Input{Left: h.left, Right: h.right, Jump: h.jump, Fire: h.fire, Angle: h.angle, Power: h.power}); err != nil {
			log.Printf("errore step: %v", err)
			m.broadcast(`{"t":"error"}`)
			return
		}
		// salto e sparo valgono per un solo tick; i tasti tenuti premuti restano
		for i := range inputs {
			inputs[i].jump, inputs[i].fire = false, false
		}

		for _, e := range sim.Events() {
			m.broadcast(e)
		}
		if tick%snapshotEvery == 0 || sim.Over() {
			m.broadcast(sim.Snapshot())
		}
		if sim.Over() {
			return
		}
	}
}

func parseClientMsg(data []byte) (clientMsg, error) {
	var msg clientMsg
	err := json.Unmarshal(data, &msg)
	return msg, err
}
