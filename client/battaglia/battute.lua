-- Le battute dei personaggi: i bot della campagna con un carattere
-- (sim/bot.lua M.CARATTERI) o un custode parlano in una nuvoletta sopra la
-- testa (battaglia/targa.lua battuta) quando succede qualcosa. Solo nel
-- client: non toccano la partita, quindi né il server né le ricette.
--
--   local p = battute.nuove()                    -- per una partita
--   p.chi[robot] = "codardo"                     -- chi parla: il carattere o il custode
--   local robot, testo, forte = p:evento(e, corrente)  -- per ogni evento
--     della partita (corrente: il robot di turno): chi dice cosa, o nil; forte:
--     una battuta che può coprire quella di prima
--   local testo = battute.di(chi, momento, n)    -- la battuta n di quel momento
--
-- Le battute girano in ordine (n: quante volte è già capitato), senza caso.
-- Momenti: turno (comincia il suo turno), colpisce (ferisce qualcuno nel suo
-- turno), colpito (lo feriscono), scappa (si teletrasporta), abbatte, muore.

local M = {}

local BATTUTE = {
	codardo = {
		turno = { "Un colpo e via!", "Non guardarmi così...", "Stavolta non mi prendi!" },
		colpisce = { "Preso! E ora scappo!", "Questo era gratis!", "Colpito e sparito!" },
		colpito = { "Ahia! Non vale!", "Non in faccia!", "Mammaaa!" },
		scappa = { "Prendimi, se ci riesci!", "Ciao ciao!", "Qui non mi trovi!", "Troppo lento!" },
		abbatte = { "Ah ah! Ti ho fregato!", "Chi è il codardo adesso?" },
		muore = { "Tornerò... di nascosto!", "Non era il mio giorno..." },
	},
	testa_calda = {
		turno = { "Arrivo!", "Ora ti spacco!", "Fatti sotto!" },
		colpisce = { "Prendi questa!", "BOOM!" },
		colpito = { "Tutto qui?", "Non sento niente!" },
		abbatte = { "Troppo facile!", "Il prossimo!" },
		muore = { "Rivincita! Subito!", "Non è finita!" },
	},
	cecchino = {
		turno = { "Respira... mira...", "Un colpo solo." },
		colpisce = { "Centro.", "Bersaglio colpito." },
		colpito = { "Questo non era previsto.", "Mi hai trovato..." },
		abbatte = { "Pulito.", "Niente di personale." },
		muore = { "Ricarico e torno.", "Ottima mira. La tua." },
	},
	spingitore = {
		turno = { "Il vuoto ti chiama!", "Che bel bordo..." },
		colpisce = { "Giù di sotto!", "Attento al bordo!" },
		colpito = { "Spingi spingi...", "Ehi, piano!" },
		abbatte = { "Il vuoto ti saluta!", "Volo libero!" },
		muore = { "Ma chi mi ha spinto?" },
	},
	fabbro = {
		turno = { "Il ferro si batte finché è caldo!", "Sull'incudine!" },
		colpisce = { "Martellata!", "Senti il Maglio?" },
		colpito = { "Graffi.", "Il ferro non si piega!" },
		abbatte = { "Un altro per la fornace!", "Forgiato!" },
		muore = { "La Forgia non si spegne...", "Tornerò più duro!" },
	},
}

function M.di(chi, momento, n)
	local b = BATTUTE[chi]
	local lista = b and b[momento]
	if not lista then return nil end
	return lista[n % #lista + 1]
end

function M.nuove()
	return setmetatable({ chi = {}, n = {} }, { __index = M })
end

-- Il momento dell'evento e chi lo dice: chi lo subisce, o chi è di turno
local function momento(chi, e, corrente)
	if e.type == "turn" then
		return e.robot, "turno"
	elseif e.type == "teleport" then
		return e.robot, "scappa"
	elseif e.type == "damage" and e.amount > 0 then
		if chi[e.robot] then return e.robot, "colpito" end
		if e.robot ~= corrente then return corrente, "colpisce" end
	elseif e.type == "death" then
		if chi[e.robot] then return e.robot, "muore" end
		return e.by, "abbatte"
	end
	return nil
end

local FORTI = { muore = true, abbatte = true, scappa = true }

function M.evento(p, e, corrente)
	local i, m = momento(p.chi, e, corrente)
	local chi = i and p.chi[i]
	if not chi then return nil end
	local k = chi .. m
	local n = p.n[k] or 0
	p.n[k] = n + 1
	-- all'inizio del turno uno sì e uno no
	if m == "turno" and n % 2 == 1 then return nil end
	local s = M.di(chi, m, n)
	return s and i, s, FORTI[m] == true
end

return M
