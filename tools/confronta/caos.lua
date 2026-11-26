-- Gioca registra.lua con l'ordine di pairs rimescolato e la memoria spostata:
-- se la simulazione dipende dall'ordine delle chiavi di una tabella o dagli
-- indirizzi (che cambiano da un telefono all'altro, e su questo LuaJIT anche
-- da un avvio all'altro per le chiavi di testo), le impronte escono diverse da
-- quelle del giro normale. Lo usa identica.py.
--
--   luajit tools/confronta/caos.lua SEME [argomenti di registra.lua]
local seme = assert(tonumber(arg[1]), "serve il seme")
local s = seme
local function caso(n)
	s = (s * 1103515245 + 12345) % 2147483648
	return 1 + s % n
end

-- un po' di tabelle e di testi prima di tutto: gli indirizzi si spostano
SPOSTA = {}
for i = 1, 1000 + caso(5000) do SPOSTA[i] = { i, tostring(i) .. "x" } end

local pairs_vero = pairs
-- pairs con le chiavi in un ordine a caso (ogni chiamata il suo)
function pairs(t)
	local mt = getmetatable(t)
	if mt and mt.__pairs then return pairs_vero(t) end
	local chiavi = {}
	for k in pairs_vero(t) do chiavi[#chiavi + 1] = k end
	for i = #chiavi, 2, -1 do
		local j = caso(i)
		chiavi[i], chiavi[j] = chiavi[j], chiavi[i]
	end
	local i = 0
	return function()
		i = i + 1
		local k = chiavi[i]
		if k == nil then return nil end
		return k, t[k]
	end, t, nil
end

local argomenti = { [0] = "tools/confronta/registra.lua" }
for i = 2, #arg do argomenti[i - 1] = arg[i] end
arg = argomenti
dofile(arg[0])
