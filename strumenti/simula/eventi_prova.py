"""Il calendario di prova degli eventi con le date di oggi, per provare la
bacheca sul PC senza riscrivere le date a mano:

    python3 strumenti/simula/eventi_prova.py      (dalla radice del repository)
    go run ./server -eventi simulazione/eventi.json

Scrive simulazione/eventi.json da strumenti/simula/scenari/eventi_prova.json
("OGGI+N" diventa la data vera), lo stesso che usa lo scenario eventi.txt.
Il server accetta solo date vere: le date relative restano qui, fuori dal gioco."""
import simula

out = simula.REPO / "simulazione"
out.mkdir(exist_ok=True)
f, eventi = simula.calendario_prova("eventi_prova.json", out)
print(f"{len(eventi)} eventi in {f.relative_to(simula.REPO)}")
print(f"go run ./server -eventi {f.relative_to(simula.REPO).as_posix()}")
