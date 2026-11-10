# Porta nel gioco le variabili del Figma dell'interfaccia (docs/figma.md).
# Legge tools/figma/interfaccia.json (lo scrive Claude dal Figma con leggi.js)
# e aggiorna:
#   - i colori di ui.C, ui.GOLD e ui.MEDAL in client/ui/ui.lua
#   - le forme bianche della UI (raggi, bordi, smussi) rifacendo con
#     tools/grafica/ui.py solo le immagini che dipendono dal Figma
# Senza cambiamenti nel Figma non cambia niente (i numeri sono quelli del codice).
#   python3 tools/figma/applica.py [--prova]   (--prova: dice cosa cambierebbe)
import json
import os
import re
import subprocess
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.normpath(os.path.join(QUI, "..", ".."))
UI_LUA = os.path.join(RADICE, "client", "ui", "ui.lua")
ASSETS = os.path.join(RADICE, "client", "assets", "ui")
# le immagini che ui.py disegna con le misure del Figma
DIPENDONO = ["forma", "bordo", "eroe_forma", "eroe_bordo", "slot_arma_forma", "slot_arma_bordo",
             "pillola_forma", "pillola_bordo", "badge_forma", "badge_bordo"]
# il 9-slice di ogni forma in ui.lua (NINE): raggio e bordo devono starci dentro
NOVE = {"forma": 16, "pillola": 24, "badge": 12, "slot_arma": 16}


def numero(v):
    v = round(float(v), 3)
    return "%g" % v


def colore(v):
    r, g, b, a = v
    parti = [numero(r), numero(g), numero(b)] + ([] if round(a, 3) == 1 else [numero(a)])
    return "c(" + ", ".join(parti) + ")"


def lista(dati, prefisso):
    chiavi = sorted(k for k in dati if k.startswith(prefisso + "/"))
    return "{ " + ", ".join(colore(dati[k]) for k in chiavi) + " }"


def nuovo_lua(testo, col):
    def sostituisci(nome, valore, schema):
        nonlocal testo
        nuovo, n = re.subn(schema, lambda m: m.group(1) + valore, testo, count=1, flags=re.M)
        if n != 1:
            sys.exit("applica: non trovo %s in client/ui/ui.lua" % nome)
        testo = nuovo
    for k, v in col.items():
        if "/" not in k:
            sostituisci(k, colore(v), r"^(\t%s = )c\([^)]*\)" % re.escape(k))
    sostituisci("SQUADRA", lista(col, "SQUADRA"), r"^(\tSQUADRA = )\{[^}]*\}")
    sostituisci("GRADI", lista(col, "GRADI"), r"^(\tGRADI = )\{[^}]*\}")
    sostituisci("ui.GOLD", colore(col["EXTRA/CORONA"]), r"^(M\.GOLD = )c\([^)]*\)")
    sostituisci("ui.MEDAL", colore(col["EXTRA/MEDAGLIA"]), r"^(M\.MEDAL = )c\([^)]*\)")
    return testo


def controlla_forme(f):
    # l'angolo della forma (raggio o smusso) deve stare nell'angolo del 9-slice
    for nome, nove in NOVE.items():
        if f[nome + "/raggio"] > nove:
            sys.exit("applica: %s/raggio %s non sta nel 9-slice di %s px (NINE in ui.lua)" % (nome, f[nome + "/raggio"], nove))
    for nome in ("eroe/smusso", "slot_arma/smusso"):
        if f[nome] > 16:
            sys.exit("applica: %s %s non sta nel 9-slice di 16 px (NINE in ui.lua)" % (nome, f[nome]))


def main():
    prova = "--prova" in sys.argv
    dati = json.load(open(os.path.join(QUI, "interfaccia.json")))
    controlla_forme(dati["forme"])
    vecchio = open(UI_LUA).read()
    lua = nuovo_lua(vecchio, dati["colori"])
    print("applica: ui.lua", "cambia" if lua != vecchio else "uguale")
    if prova:
        return
    if lua != vecchio:
        open(UI_LUA, "w").write(lua)
    # rifà le forme, poi rimette com'erano quelle che non dipendono dal Figma
    salvate = {}
    for nome in os.listdir(ASSETS):
        if nome.endswith(".png") and nome[:-4] not in DIPENDONO:
            salvate[nome] = open(os.path.join(ASSETS, nome), "rb").read()
    subprocess.run([sys.executable, os.path.join(RADICE, "tools", "grafica", "ui.py")], check=True)
    for nome, b in salvate.items():
        open(os.path.join(ASSETS, nome), "wb").write(b)
    for nome in os.listdir(ASSETS):
        if nome.endswith(".png") and nome[:-4] not in DIPENDONO and nome not in salvate:
            os.remove(os.path.join(ASSETS, nome))
    print("applica: fatto (controlla con git diff e simula.py)")


main()
