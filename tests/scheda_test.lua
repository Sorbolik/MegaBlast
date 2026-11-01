-- Test della scheda personaggio: badge e statistiche (menu/traguardi.lua,
-- menu/profilo.lua), vetrine dei cartellini (menu/vetrina.lua), la conta di
-- fine partita (menu/conta.lua) e il replay (sim/replay.lua). Dalla radice:
--   luajit tests/scheda_test.lua
package.path = "client/?.lua;" .. package.path

local traguardi = require "menu.traguardi"
local profilo = require "menu.profilo"
local vetrina = require "menu.vetrina"
local conta = require "menu.conta"
local replay = require "sim.replay"
local game = require "sim.game"
local equip = require "sim.equipaggiamento"

local failures = 0
local function check(cond, msg)
	if cond then
		print("ok   " .. msg)
	else
		print("FAIL " .. msg)
		failures = failures + 1
	end
end

-- Badge ------------------------------------------------------------------------
local mira = traguardi.BY_ID.a_segno
check(traguardi.grado(mira, 9) == 0 and traguardi.grado(mira, 10) == 1 and traguardi.grado(mira, 10000) == 4,
	"badge: un grado per soglia")
local soglia, f = traguardi.prossima(mira, 55)
check(soglia == 100 and math.abs(f - 0.5) < 1e-9, "badge: la prossima soglia e quanto manca dalla soglia di prima")
check(traguardi.prossima(mira, 20000) == nil, "badge: dopo l'ultima soglia non c'è una prossima")
local presi = traguardi.presi({ a_segno = 150, globi = 12, casse = 120, cadute = 999 })
check(#presi == 3 and presi[1].id == "a_segno" and presi[2].id == "casse" and presi[3].id == "globi",
	"badge: dal grado più alto, a pari grado nell'ordine della lista; le cadute non danno badge")
local m = traguardi.mostrati({ a_segno = 150, globi = 12, casse = 120, vinte = 10 }, { "vinte", "danno" })
check(#m == traguardi.MOSTRATI and m[1].id == "vinte" and m[2].id == "a_segno",
	"badge: prima quelli scelti (se presi), poi i più alti, al massimo tre")
check(traguardi.valido({ id = "globi", grado = 2 }) and not traguardi.valido({ id = "globi", grado = 5 })
	and not traguardi.valido({ id = "cadute", grado = 1 }) and not traguardi.valido({ id = "x", grado = 1 }),
	"badge: quelli arrivati da fuori si controllano")

-- Profilo: registra, statistiche, scegli_badge -----------------------------------
local p = profilo.nuovo()
local function partita(gruppo, vinta, valori)
	return { gruppo = gruppo, vinta = vinta, valori = valori, armi = { missile = 100 },
		partita = { gruppo = gruppo, esito = vinta and "V" or "S", punti = { 1, 0 }, giocatori = {}, momenti = {} } }
end
for i = 1, 12 do profilo.registra(p, partita(i % 2 == 0 and "2v2" or "1v1", i > 9, { a_segno = 3, colpo_lungo = i * 100 })) end
check(#p.partite == profilo.PARTITE and p.partite[1].numero == 12 and p.partite[profilo.PARTITE].numero == 3,
	"profilo: si tengono le ultime partite, la più nuova in cima")
local due = profilo.statistiche(p, "2v2")
check(due.partite == 6 and due.a_segno == 18 and due.colpo_lungo == 1200 and due.vinte == 2,
	"profilo: le statistiche si sommano per modo, il record è il massimo")
local tutte = profilo.statistiche(p, "tutte")
check(tutte.partite == 12 and tutte.a_segno == 36 and tutte.colpo_lungo == 1200 and tutte.armi.missile == 1200,
	"profilo: TUTTE somma i modi (e il danno per arma), il record resta il massimo")
check(p.serie == 3 and tutte.serie == 3, "profilo: la serie di vittorie")
check(profilo.posto_replay(1) == 1 and profilo.posto_replay(11) == 1 and profilo.posto_replay(12) == 2,
	"profilo: i file dei replay si riusano a giro")
profilo.scegli_badge(p, "globi")
profilo.scegli_badge(p, "casse")
profilo.scegli_badge(p, "vinte")
profilo.scegli_badge(p, "danno")
check(#p.badge == 3 and p.badge[1] == "danno" and p.badge[3] == "casse", "profilo: si scelgono al massimo tre badge, l'ultimo davanti")
check(profilo.scegli_badge(p, "danno") == false and p.badge[1] == "vinte", "profilo: toccando un badge scelto si toglie")

-- Vetrina --------------------------------------------------------------------------
local q = profilo.nuovo()
local a = profilo.assetto_attivo(q)
for _, s in ipairs(equip.SLOTS) do a.gear[s.id] = "corvo" end
q.maestria["corvo_" .. equip.SLOTS[1].id] = 25
local v = vetrina.da_profilo(q, "Rosso", 1, "TU")
check(v.pezzi[1].livello == 25 and v.pezzi[1].tier == 3 and v.pezzi[2].livello == 0,
	"vetrina: ogni pezzo col suo livello e il tier degli scatti a 10, 20, 30")
check(#v.poteri >= 1 and v.poteri[1] == "doppio salto", "vetrina: il set completo dà il suo potere")
local righe = vetrina.righe(v)
check(#righe == 4 and righe[1].nome == "VITA", "vetrina: quattro barre, la vita per prima")
local base = vetrina.righe(vetrina.semplice("Blu", 2, "AVVERSARIO"))
check(base[2].valore == "=" and base[2].scarto == 0, "vetrina: senza pezzi le barre stanno al centro")
local st = game.base_stats()
st.jump_height = st.jump_height * 1.06
local r6 = vetrina.righe(vetrina.con_stats(vetrina.semplice("Blu", 2, ""), st))
check(r6[2].valore == "+6%" and math.abs(r6[2].scarto - 0.6) < 1e-6, "vetrina: +6% e lo scarto in decimi di SCALA")
local rete = vetrina.da_rete({ liv = 1e9, bdg = { { id = "globi", grado = 2 }, { id = "boh", grado = 1 }, "x" } }, "Blu", 2, "")
check(rete.livello == 999 and #rete.badge == 1 and rete.badge[1].id == "globi", "vetrina: quella arrivata online si controlla")
local pr = vetrina.per_rete(p)
check(pr.liv == p.livello and #(pr.bdg or {}) <= traguardi.MOSTRATI, "vetrina: col saluto vanno livello e badge")
check(vetrina.per_rete(profilo.nuovo()).bdg == nil, "vetrina: senza badge niente bdg (in JSON sarebbe un oggetto)")

-- Conta e replay su una partita vera: due bot, rigiocata uguale ------------------
local r = replay.nuova(7, "forgia", { players = { { team = 1, bot = "normale" }, { team = 2, bot = "normale" } } })
local g, bots = replay.partita(r)
local c = conta.nuova(g, 1, { "Rosso", "Blu" })
while g.phase ~= "over" and g.tick < 60 * 60 * 3 do
	local inp = replay.input(r, g, bots)
	if inp.fire and g.current == 1 then conta.sparo(c, g, inp.fire.weapon) end
	g:step(inp)
	replay.dopo(r, g)
	for _, e in ipairs(g:pop_events()) do conta.evento(c, g, e) end
	conta.tick(c, g)
end
local fine = conta.fine(c, g, g:results(), { gruppo = "1v1", mappa = g.map, quando = 0, giocatori = {} })
check(fine.valori.colpi > 0 and fine.valori.a_segno <= fine.valori.colpi, "conta: colpi e colpi a segno")
local danno_armi = 0
for _, n in pairs(fine.armi) do danno_armi = danno_armi + n end
check(danno_armi <= fine.valori.danno + 1 and danno_armi >= fine.valori.danno * 0.5,
	"conta: il danno per arma sta dentro il danno della classifica (" .. danno_armi .. " su " .. fine.valori.danno .. ")")
check(#fine.partita.fune >= 2 and fine.partita.esito:match("^[VSP]$"), "conta: la fune giro per giro e l'esito")
local ok, tick = replay.verifica(r, g.tick)
check(ok, "replay: la partita rigiocata dalla ricetta torna uguale" .. (ok and "" or (" (diverge al tick " .. tostring(tick) .. ")")))
-- il lettore rilegge i tasti come li ha registrati: anche durata cambiata a mano
local r2 = replay.nuova(3, "forgia", { players = { { team = 1 }, { team = 2, bot = "normale" } } })
local g2, b2 = replay.partita(r2)
r2.durata = 600
g2.match_left = r2.durata
local mosse = { [5] = { right = true }, [40] = { left = true }, [80] = { fire = { weapon = "missile", angle = 0.6, power = 0.7 } } }
while g2.phase ~= "over" and g2.tick < 900 do
	local inp = replay.input(r2, g2, b2, mosse[g2.tick] or {})
	g2:step(inp)
	replay.dopo(r2, g2)
	g2:pop_events()
end
local g3, b3 = replay.partita(r2)
check(g3.match_left == 600, "replay: la durata cambiata (negli scenari) torna anche nel replay")
local l = replay.lettore(r2)
while g3.tick < g2.tick and g3.phase ~= "over" do g3:step(replay.rileggi(l, g3, b3)) end
check(g3:impronta() == g2:impronta(), "replay: rileggendo i tasti si arriva allo stesso stato")

if failures > 0 then
	print(failures .. " test falliti")
	os.exit(1)
end
print("tutti i test superati")
