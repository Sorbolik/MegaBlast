#!/usr/bin/env python3
"""Ogni elemento dei menu usa il pezzo del kit del suo scopo (Sergio, 23 nov: «lo facciamo
una volta per tutte»; catalogo in docs/ui-catalogo.md). Segnala nel client i disegni fuori
dal kit: i pulsanti vecchi (ui.button), le barre vecchie (ui.bar, guscio, barra_brace...),
le piastrine e le piastre usate come pulsanti, tab, scelte o etichette. Il kit
(client/ui/kit.lua) e ui.lua dove sono definiti non contano. Una riga che deve restare
cosi' porta il commento «kit: eccezione» con il perche'."""
import os
import re
import sys

RADICE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
CLIENT = os.path.join(RADICE, "client")
FUORI = {os.path.join("ui", "kit.lua"), os.path.join("ui", "ui.lua"), os.path.join("ui", "pieces.lua")}
VIETATI = [
    (re.compile(r"\bui\.button\("), "pulsante vecchio: kit.secondary o kit.action (scopi 1 e 2)"),
    (re.compile(r"\bui\.bar\("), "barra vecchia: kit.bar (scopo 10)"),
    (re.compile(r'"(guscio|barra_brace|barra_gelo|barra_chiara|riga_scura)"'), "barra vecchia: kit.bar o kit.bar_parts (scopo 10)"),
    (re.compile(r'"(piastrina|piastrina_chiara|piastrina_calda|piastra_storta|piastra_calda)"'),
     "piastra: pulsante (kit.secondary), tab o scelta (parola incandescente), etichetta o filtro (kit.thread_chip)"),
    (re.compile(r'"(primario_acceso|gioca_sigillo|scheda_brace|scheda_ferro|scheda_gelo|scheda_spenta)"'), "pezzo tolto il 23 nov"),
]


def main():
    trovati = []
    for cartella, _, file in os.walk(CLIENT):
        for f in sorted(file):
            if not f.endswith((".lua", ".gui_script", ".script")):
                continue
            percorso = os.path.join(cartella, f)
            rel = os.path.relpath(percorso, CLIENT)
            if rel in FUORI:
                continue
            with open(percorso, encoding="utf-8") as h:
                for i, riga in enumerate(h, 1):
                    if "kit: eccezione" in riga or riga.lstrip().startswith("--"):
                        continue
                    for regola, perche in VIETATI:
                        if regola.search(riga):
                            trovati.append("client/%s:%d: %s" % (rel, i, perche))
    for t in trovati:
        print(t)
    if trovati:
        print("fuori dal kit: %d (docs/ui-catalogo.md)" % len(trovati))
        return 1
    print("tutto dal kit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
