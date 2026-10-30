#!/usr/bin/env python3
"""Simula MegaBlast senza aprire Defold: compila, avvia il gioco su uno schermo
virtuale, gioca uno scenario di comandi e salva foto, video e log.

Passi:
  1. controlla.py   i controlli dell'editor che bob non fa
  2. test della simulazione (tests/sim_test.lua con luajit)
     (se 1 o 2 falliscono si va avanti lo stesso, ma il risultato è FALLITO)
  3. build con bob.jar 1.14 per Linux, con megablast.simula = 1
  4. gioco su Xvfb: scenario (strumenti/simula/scenari/base.txt), foto, video
     e controllo del log: qualsiasi ERROR del motore o di Lua fa fallire

Uso (dalla radice del repository):
  python3 strumenti/simula/simula.py                 tutto, scenario base
  python3 strumenti/simula/simula.py -s mio.txt      un altro scenario
  python3 strumenti/simula/simula.py --solo-build    solo i passi 1-3

Risultati in simulazione/ (ignorata da git): foto/*.png, foto/riepilogo.png, video.mp4,
log.txt. Gli strumenti si installano con strumenti/simula/prepara.sh.
"""
import argparse
import os
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

import senza_estensioni

QUI = Path(__file__).resolve().parent
REPO = QUI.parents[1]
CLIENT = REPO / "client"
CACHE = Path(os.environ.get("MEGABLAST_CACHE", Path.home() / ".cache" / "megablast"))
BOB = CACHE / "bob.jar"
JAVA = Path("/usr/lib/jvm/java-25-openjdk-amd64/bin/java")
W, H = 1280, 720
# lo schermo virtuale è S volte più grande (--scala): come un telefono ad alta densità
S = 1

# Nomi comodi dei tasti (quelli di input/game.input_binding)
TASTI = {"sinistra": "Left", "destra": "Right", "salta": "space", "su": "Up"}
# Il controller finto (comando "pad"): nella build del simulatore ogni tasto
# del controller ha anche un tasto della tastiera (azione pad_NOME di
# input/game.input_binding): (tasto di Defold, tasto di xdotool). Le levette
# così vanno solo fino in fondo, in otto direzioni.
PAD = {"a": ("F1", "F1"), "b": ("F2", "F2"), "x": ("F3", "F3"), "y": ("F4", "F4"),
       "lb": ("F5", "F5"), "rb": ("F6", "F6"), "lt": ("F7", "F7"), "rt": ("F8", "F8"),
       "start": ("F9", "F9"), "select": ("F10", "F10"),
       "su": ("PAGEUP", "Prior"), "giu": ("PAGEDOWN", "Next"), "sinistra": ("HOME", "Home"), "destra": ("END", "End"),
       "sx_sinistra": ("F", "f"), "sx_destra": ("H", "h"), "sx_su": ("Y", "y"), "sx_giu": ("G", "g"),
       "dx_sinistra": ("J", "j"), "dx_destra": ("L", "l"), "dx_su": ("I", "i"), "dx_giu": ("K", "k")}
# Righe del log del motore che non sono errori del gioco (nel container non c'è audio)
IGNORA = re.compile(r"^(ERROR|WARNING):SOUND|^WARNING:(DLIB: Variable LANG|ENGINE: Failed to initialize sound)")
ERRORE = re.compile(r"^(ERROR|FATAL):|Assertion|Segmentation fault|stack traceback")


def info(msg):
    print(f"[simula] {msg}", flush=True)


class Fallito(Exception):
    pass


def esegui(cmd, **kw):
    return subprocess.run(cmd, text=True, capture_output=True, **kw)


def prepara():
    mancano = [n for n in ("Xvfb", "xdotool", "ffmpeg") if not shutil.which(n)]
    if mancano or not BOB.exists() or not JAVA.exists():
        info("installo gli strumenti (prepara.sh)...")
        if subprocess.run(["bash", str(QUI / "prepara.sh")]).returncode != 0:
            raise Fallito("prepara.sh non è riuscito a installare gli strumenti")


# 1-3. Controlli e build ----------------------------------------------------------

def controlli():
    info("1. controlli dell'editor")
    if subprocess.run([sys.executable, str(QUI / "controlla.py"), str(CLIENT)]).returncode != 0:
        raise Fallito("l'editor di Defold segnalerebbe degli errori (vedi sopra)")


def test_sim():
    lua = shutil.which("luajit") or shutil.which("lua5.1") or shutil.which("lua")
    if not lua:
        info("2. test della simulazione saltati: manca luajit")
        return
    info("2. test della simulazione, di assetto e podio, del personaggio e della camera")
    for test in ("tests/sim_test.lua", "tests/assetto_test.lua", "tests/battaglia_test.lua", "tests/bot_test.lua", "tests/campagna_test.lua"):
        r = esegui([lua, test], cwd=REPO)
        sys.stdout.write(r.stdout[-2000:] + r.stderr[-2000:])
        if r.returncode != 0:
            raise Fallito(f"i test di {test} falliscono")


def impostazioni(scenario):
    """Righe "imposta chiave valore" dello scenario: vanno nella sezione [megablast] della build."""
    righe = []
    for riga in scenario.read_text().splitlines():
        p = shlex.split(riga, comments=True)
        if p and p[0] == "imposta":
            if len(p) != 3 or not re.fullmatch(r"[a-z_]+", p[1]):
                raise Fallito(f"imposta vuole una chiave e un valore: {riga.strip()}")
            righe.append(f"{p[1]} = {p[2]}\n")
    return "".join(righe)


def build(out, extra=""):
    info("3. build con bob")
    # niente estensione WebSocket né estensioni native del client (si compilano sul
    # build server di Defold, che da qui non si raggiunge: si compila una copia del
    # client senza, senza_estensioni.py) e log di simulazione acceso
    settings = out / "simula.ini"
    settings.write_text("[project]\ndependencies#0 =\n\n[native_extension]\napp_manifest =\n\n[megablast]\nsimula = 1\n" + extra)
    bundle = out / "bundle"
    shutil.rmtree(bundle, ignore_errors=True)
    radice = senza_estensioni.copia(out / "client")
    with open(radice / "input" / "game.input_binding", "a") as f:
        for nome, (tasto, _) in PAD.items():
            f.write(f'key_trigger {{\n  input: KEY_{tasto}\n  action: "pad_{nome}"\n}}\n')
    cmd = [str(JAVA), "-jar", str(BOB), "--root", str(radice), "--output", "build/simula/default",
           "--settings", str(settings), "--platform", "x86_64-linux", "--architectures", "x86_64-linux",
           "--variant", "debug", "--archive", "--texture-compression", "true", "--bundle-output", str(bundle), "build", "bundle"]
    r = esegui(cmd)
    righe = [l for l in (r.stdout + r.stderr).splitlines()
             if not l.startswith(("Picked up JAVA_TOOL", " ")) and " INFO " not in l]
    (out / "build.txt").write_text(r.stdout + r.stderr)
    errori = [l for l in righe if re.search(r"\bERROR\b|error:|Exception", l)]
    if r.returncode != 0 or errori:
        print("\n".join(errori or righe[-40:]))
        raise Fallito("la build di bob è fallita (log completo in simulazione/build.txt)")
    exe = next(bundle.glob("*/*.x86_64"), None)
    if not exe:
        raise Fallito("bob non ha prodotto l'eseguibile")
    return exe


# 4. Partita sullo schermo virtuale -----------------------------------------------

class Gioco:
    def __init__(self, exe, out, video):
        self.out, self.foto = out, out / "foto"
        shutil.rmtree(self.foto, ignore_errors=True)
        self.foto.mkdir(parents=True)
        self.log_path = out / "log.txt"
        self.letto = 0          # righe del log già lette
        self.eventi = []        # eventi SIMULA non ancora consumati da aspetta_evento
        self.stato = {}
        self.proc = self.xvfb = self.rec = None
        self.server = []        # server e giocatori finti del comando "server"
        n = 99
        while Path(f"/tmp/.X{n}-lock").exists():
            n += 1
        self.display = f":{n}"
        # una casa vuota a ogni prova: il profilo salvato (sys.save) riparte da zero
        casa = out / "casa"
        shutil.rmtree(casa, ignore_errors=True)
        casa.mkdir(parents=True)
        self.env = dict(os.environ, DISPLAY=self.display, LANG="C.UTF-8", HOME=str(casa))
        self.xvfb = subprocess.Popen(["Xvfb", self.display, "-screen", "0", f"{W * S}x{H * S}x24", "-nolisten", "tcp"],
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            if esegui(["xdpyinfo"], env=self.env).returncode == 0:
                break
            time.sleep(0.1)
        if video:
            self.rec = subprocess.Popen(
                ["ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-framerate", "30",
                 "-video_size", f"{W * S}x{H * S}", "-i", self.display, "-c:v", "libx264", "-preset", "ultrafast",
                 "-pix_fmt", "yuv420p", str(out / "video.mp4")],
                stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=self.env)
        self.log = open(self.log_path, "w")
        # stdbuf: il motore scrive il log su un file, senza buffer così lo leggiamo subito
        self.proc = subprocess.Popen(["stdbuf", "-oL", "-eL", f"./{exe.name}"], cwd=exe.parent,
                                     stdout=self.log, stderr=subprocess.STDOUT, env=self.env)
        self.win = None
        for _ in range(100):
            r = esegui(["xdotool", "search", "--name", "MegaBlast"], env=self.env)
            if r.stdout.strip():
                self.win = r.stdout.split()[0]
                break
            self.vivo()
            time.sleep(0.1)
        if not self.win:
            raise Fallito("la finestra del gioco non si è aperta")
        esegui(["xdotool", "windowmove", self.win, "0", "0", "windowfocus", self.win], env=self.env)
        if S != 1 or (W, H) != (1280, 720):
            # la finestra grande come lo schermo: il gioco disegna a S volte la
            # risoluzione, o con le proporzioni di un altro schermo (--schermo)
            esegui(["xdotool", "windowsize", "--sync", self.win, str(W * S), str(H * S)], env=self.env)

    # log ------------------------------------------------------------------------
    def leggi(self):
        self.log.flush()
        with open(self.log_path, errors="replace") as f:
            righe = f.read().splitlines()
        nuove, self.letto = righe[self.letto:], len(righe)
        for l in nuove:
            if ERRORE.search(l) and not IGNORA.search(l):
                raise Fallito(f"errore nel log del gioco: {l}")
            m = re.search(r"SIMULA evento (\w+)", l)
            if m:
                self.eventi.append(m.group(1))
            m = re.search(r"SIMULA stato (.*)", l)
            if m:
                self.stato = dict(kv.split("=", 1) for kv in m.group(1).split())

    def vivo(self):
        if self.proc.poll() is not None:
            self.leggi()
            raise Fallito(f"il gioco si è chiuso da solo (codice {self.proc.returncode})")

    def attendi(self, secondi):
        fine = time.time() + secondi
        while time.time() < fine:
            self.vivo()
            self.leggi()
            time.sleep(min(0.05, max(0, fine - time.time())))

    # input --------------------------------------------------------------------
    def xdo(self, *args):
        esegui(["xdotool", *map(str, args)], env=self.env)

    def punta(self, x, y):
        # coordinate del gioco (y verso l'alto) -> schermo (y verso il basso)
        self.xdo("mousemove", "--sync", round(x * S), round((H - y) * S))

    def robot(self):
        self.leggi()
        if "x" not in self.stato:
            raise Fallito("non so dove sia il robot: manca la riga SIMULA stato nel log")
        # dove si vede il centro del robot sullo schermo (con la camera); i
        # giochi di prima scrivono solo x, y del mondo
        if "sx" in self.stato:
            # il gioco lo scrive stirato su 1280 x 720, come i tocchi (--schermo)
            return round(int(self.stato["sx"]) * W / 1280), round(int(self.stato["sy"]) * H / 720)
        return int(self.stato["x"]), int(self.stato["y"]) + 8

    def scatta(self, nome):
        r = esegui(["ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-video_size", f"{W * S}x{H * S}",
                    "-i", self.display, "-frames:v", "1", str(self.foto / f"{nome}.png")], env=self.env)
        if r.returncode != 0:
            raise Fallito(f"foto {nome} non riuscita: {r.stderr.strip()}")
        info(f"   foto {nome}.png")

    def zoom(self, nome, z=2):
        """foto ingrandita z volte attorno al robot di turno (contando lo zoom
        che la camera del gioco ha già)"""
        x, y = self.robot()
        z = max(1, z / float(self.stato.get("zoom", 1)))
        cw, ch = round(800 / z), round(450 / z)
        cx = min(max(x - cw / 2, 0), W - cw)
        cy = min(max(H - y - ch * 0.62, 0), H - ch)
        cx, cy, cw, ch = round(cx * S), round(cy * S), cw * S, ch * S
        r = esegui(["ffmpeg", "-loglevel", "error", "-y", "-f", "x11grab", "-video_size", f"{W * S}x{H * S}",
                    "-i", self.display, "-frames:v", "1", "-vf", f"crop={cw}:{ch}:{cx}:{cy},scale=800:450",
                    str(self.foto / f"{nome}.png")], env=self.env)
        if r.returncode != 0:
            raise Fallito(f"zoom {nome} non riuscito: {r.stderr.strip()}")
        info(f"   zoom {nome}.png")

    def chiudi(self):
        if self.rec:
            try:
                self.rec.communicate(b"q", timeout=10)
            except subprocess.TimeoutExpired:
                self.rec.kill()
        for p in (self.proc, self.xvfb, *self.server):
            if p and p.poll() is None:
                p.send_signal(signal.SIGTERM)
                try:
                    p.wait(5)
                except subprocess.TimeoutExpired:
                    p.kill()
        self.log.close()


def aspetta_che(g, cond, timeout, cosa):
    fine = time.time() + timeout
    while time.time() < fine:
        g.vivo()
        g.leggi()
        if cond():
            return
        time.sleep(0.05)
    raise Fallito(f"dopo {timeout:g} s non è successo: {cosa} (ultimo stato: {g.stato})")


PORTA_SERVER = 8090


def avvia_server(g, modo, n):
    """Il server vero e N giocatori finti (strumenti/simula/finti) nella coda modo.
    Lo scenario deve dire al gioco dove sta: imposta server_url ws://127.0.0.1:8090/ws"""
    if g.server:
        raise Fallito("il server è già partito")
    bin = g.out / "bin"
    for nome, pacchetto in (("server", "./server"), ("finti", "./strumenti/simula/finti")):
        r = esegui(["go", "build", "-o", str(bin / nome), pacchetto], cwd=REPO)
        if r.returncode != 0:
            print(r.stdout + r.stderr)
            raise Fallito(f"go build {pacchetto} fallito")
    log = open(g.out / "server.txt", "w")
    g.server.append(subprocess.Popen([str(bin / "server"), "-addr", f"127.0.0.1:{PORTA_SERVER}"],
                                     stdout=log, stderr=subprocess.STDOUT))
    url = f"ws://127.0.0.1:{PORTA_SERVER}/ws"
    # i finti entrano dopo un attimo: il giocatore vero, che entra subito, è il robot 1
    argomenti = ["-url", url, "-modo", modo, "-n", str(n), "-attesa", "3s"]
    g.server.append(subprocess.Popen([str(bin / "finti"), *argomenti], stdout=log, stderr=subprocess.STDOUT))


def comando(g, riga):
    p = shlex.split(riga, comments=True)
    if not p:
        return
    c, a = p[0], p[1:]
    num = lambda i, d=None: float(a[i]) if len(a) > i else d
    if c == "imposta":
        pass  # già usata nella build
    elif c == "aspetta":
        g.attendi(num(0))
    elif c == "server":
        avvia_server(g, a[0], int(num(1, 1)))
    elif c == "foto":
        g.scatta(a[0])
    elif c == "zoom":
        g.zoom(a[0], num(1, 2))
    elif c in ("tocca", "tocca_centro", "tocca_bordo"):
        # tocca: pixel dello schermo; tocca_centro: pixel del gioco a 16:9, dove
        # stanno i menu, centrati su ogni schermo; tocca_bordo DX DY alto|basso
        # sinistra|destra: a DX, DY pixel del gioco da quell'angolo (ui/schermo.lua)
        u = min(W / 1280, H / 720)
        x, y = num(0), num(1)
        if c == "tocca_centro":
            x, y = (x - 640) * u + W / 2, (y - 360) * u + H / 2
        elif c == "tocca_bordo":
            x = W - x * u if a[3] == "destra" else x * u
            y = H - y * u if a[2] == "alto" else y * u
        g.punta(x, y)
        g.xdo("mousedown", 1)
        g.attendi(0.1)
        g.xdo("mouseup", 1)
        g.attendi(0.1)
    elif c in ("tieni", "premi"):
        tasto = TASTI.get(a[0], a[0])
        g.xdo("keydown", tasto)
        g.attendi(num(1, 0.6) if c == "tieni" else 0.08)
        if c == "tieni" and len(a) > 2:
            # zoom prima di lasciare il tasto (per vedere il movimento)
            g.zoom(a[2], num(3, 2))
        g.xdo("keyup", tasto)
    elif c == "pad":
        # pad A+RT [S]: tiene premuti insieme quei tasti del controller finto per S secondi
        tasti = [PAD[n][1] for n in a[0].split("+")]
        for t in tasti:
            g.xdo("keydown", t)
        g.attendi(num(1, 0.1))
        for t in tasti:
            g.xdo("keyup", t)
        g.attendi(0.05)
    elif c in ("pad_tieni", "pad_lascia"):
        # pad_tieni dx_su+dx_destra ... pad_lascia dx_su+dx_destra: tasti tenuti fra altri comandi
        for n in a[0].split("+"):
            g.xdo("keydown" if c == "pad_tieni" else "keyup", PAD[n][1])
        g.attendi(0.05)
    elif c == "cammina":
        # tiene premuto destra o sinistra finché il robot di turno passa X nel
        # mondo (non dipende da quanto va veloce il gioco nel simulatore)
        tasto, x = TASTI[a[0]], num(1)
        oltre = (lambda v: v >= x) if a[0] == "destra" else (lambda v: v <= x)
        g.xdo("keydown", tasto)
        try:
            aspetta_che(g, lambda: "x" in g.stato and oltre(float(g.stato["x"])), num(2, 10), f"robot a x {x:g}")
        finally:
            g.xdo("keyup", tasto)
    elif c == "trascina":
        g.punta(num(0), num(1))
        g.xdo("mousedown", 1)
        passi = 10
        for i in range(1, passi + 1):
            g.attendi(num(4, 0.5) / passi)
            g.punta(num(0) + (num(2) - num(0)) * i / passi, num(1) + (num(3) - num(1)) * i / passi)
        g.xdo("mouseup", 1)
    elif c == "mira":
        # tiene premuto il dito a (dx, dy) dal robot di turno e poi lascia: spara
        x, y = g.robot()
        g.punta(x + num(0), y + num(1))
        g.xdo("mousedown", 1)
        g.attendi(0.1)
        g.punta(x + num(0) + 1, y + num(1))  # un movimento per aggiornare la mira
        g.attendi(num(2, 0.5))
        if len(a) > 4:
            g.zoom(a[3], num(4))
        elif len(a) > 3:
            g.scatta(a[3])
        g.xdo("mouseup", 1)
    elif c == "mira_arco":
        # tiene il dito a R pixel dal robot e lo gira da A1 a A2 gradi (in su
        # positivi) in N passi, con una foto ingrandita a ogni passo, poi lascia
        import math
        x, y = g.robot()
        a1, a2, n, r = num(0), num(1), int(num(2)), num(3, 150)
        punto = lambda gr: (x + r * math.cos(math.radians(gr)), y + r * math.sin(math.radians(gr)))
        g.punta(*punto(a1))
        g.xdo("mousedown", 1)
        for i in range(n + 1):
            gr = a1 + (a2 - a1) * i / max(1, n)
            g.punta(*punto(gr))
            g.attendi(0.15)
            g.zoom(f"arco_{i:02d}_{gr:.0f}", num(4, 3))
        g.xdo("mouseup", 1)
    elif c in ("levetta", "levetta_mira"):
        # dito sulla levetta del movimento (o della mira) del telefono, spostato
        # di (dx, dy) dal punto d'appoggio e tenuto S secondi; facoltativamente
        # una foto prima di lasciare. Serve "imposta comandi telefono".
        cx, cy = (115, 117) if c == "levetta" else (W - 115, 117)
        g.punta(cx, cy)
        g.xdo("mousedown", 1)
        g.attendi(0.05)
        for i in range(1, 5):  # qualche passo, come un pollice vero
            g.punta(cx + num(0) * i / 4, cy + num(1) * i / 4)
            g.attendi(0.02)
        g.attendi(num(2, 0.5))
        if len(a) > 3:
            g.scatta(a[3])
        g.xdo("mouseup", 1)
    elif c == "levetta_annulla":
        # mira con la levetta del telefono a (dx, dy) e la annulla col tasto destro
        # (fa quello che fa un secondo dito), facoltativamente una foto, poi lascia
        cx, cy = W - 115, 117
        g.punta(cx, cy)
        g.xdo("mousedown", 1)
        g.attendi(0.05)
        for i in range(1, 5):
            g.punta(cx + num(0) * i / 4, cy + num(1) * i / 4)
            g.attendi(0.02)
        g.attendi(0.3)
        g.xdo("mousedown", 3)
        g.attendi(0.1)
        g.xdo("mouseup", 3)
        g.attendi(0.2)
        if len(a) > 2:
            g.scatta(a[2])
        g.xdo("mouseup", 1)
    elif c == "annulla":
        # mira a (dx, dy) col sinistro, annulla col destro, poi lascia il sinistro
        x, y = g.robot()
        g.punta(x + num(0), y + num(1))
        g.xdo("mousedown", 1)
        g.attendi(0.1)
        g.punta(x + num(0) + 1, y + num(1))
        g.attendi(0.3)
        g.xdo("mousedown", 3)
        g.attendi(0.1)
        g.xdo("mouseup", 3)
        g.attendi(0.2)
        if len(a) > 2:
            g.scatta(a[2])
        g.xdo("mouseup", 1)
    elif c == "niente_evento":
        tipo = a[0]
        fine = time.time() + num(1, 1)
        while time.time() < fine:
            g.vivo()
            g.leggi()
            if tipo in g.eventi:
                raise Fallito(f"evento {tipo} che non doveva succedere")
            time.sleep(0.05)
    elif c == "aspetta_evento":
        tipo = a[0]
        def visto():
            if tipo in g.eventi:
                del g.eventi[:g.eventi.index(tipo) + 1]
                return True
        aspetta_che(g, visto, num(1, 10), f"evento {tipo}")
    elif c == "aspetta_stato":
        voluto = dict(kv.split("=", 1) for kv in a if "=" in kv)
        resto = [x for x in a if "=" not in x]
        aspetta_che(g, lambda: all(g.stato.get(k) == v for k, v in voluto.items()),
                    float(resto[0]) if resto else 10, " ".join(f"{k}={v}" for k, v in voluto.items()))
    else:
        raise Fallito(f"comando sconosciuto: {c}")


def gioca(exe, out, scenario, video):
    info(f"4. partita: {scenario.relative_to(REPO) if scenario.is_relative_to(REPO) else scenario}")
    g = Gioco(exe, out, video)
    try:
        for n, riga in enumerate(scenario.read_text().splitlines(), 1):
            if riga.strip() and not riga.strip().startswith("#"):
                info(f"   {n}: {riga.strip()}")
            try:
                comando(g, riga)
            except Fallito as e:
                g.scatta("errore")
                raise Fallito(f"riga {n} ({riga.strip()}): {e}")
        g.attendi(0.5)
    finally:
        g.chiudi()
    avvisi = [l for l in open(g.log_path, errors="replace").read().splitlines()
              if l.startswith("WARNING:") and not IGNORA.search(l)]
    for l in avvisi:
        info(f"avviso: {l}")
    riepilogo(g.foto)


def riepilogo(cartella):
    foto = sorted(f for f in cartella.glob("*.png") if f.name != "riepilogo.png")
    if not foto:
        return
    col = 3
    righe = (len(foto) + col - 1) // col
    ingressi = sum((["-i", str(f)] for f in foto), [])
    vuote = col * righe - len(foto)
    filtro = "".join(f"[{i}]scale=640:360[s{i}];" for i in range(len(foto)))
    filtro += "".join(f"color=black:640x360:d=1[v{i}];" for i in range(vuote))
    tutti = "".join(f"[s{i}]" for i in range(len(foto))) + "".join(f"[v{i}]" for i in range(vuote))
    layout = "|".join(f"{(i % col) * 640}_{(i // col) * 360}" for i in range(col * righe))
    filtro += f"{tutti}xstack=inputs={col * righe}:layout={layout}"
    esegui(["ffmpeg", "-loglevel", "error", "-y", *ingressi, "-filter_complex", filtro,
            "-frames:v", "1", str(cartella / "riepilogo.png")])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-s", "--scenario", type=Path, default=QUI / "scenari" / "base.txt")
    ap.add_argument("--solo-build", action="store_true", help="controlli, test e build, senza avviare il gioco")
    ap.add_argument("--senza-video", action="store_true")
    ap.add_argument("--scala", type=int, default=1, help="schermo S volte più grande (foto ad alta densità)")
    ap.add_argument("--schermo", default="1280x720",
                    help="LxA: schermo con altre proporzioni, per esempio 1600x720 (telefono 20:9) o 960x720 (tablet 4:3)")
    args = ap.parse_args()
    global S, W, H
    S = args.scala
    W, H = map(int, args.schermo.lower().split("x"))
    out = REPO / "simulazione"
    out.mkdir(parents=True, exist_ok=True)
    problemi = []
    try:
        prepara()
        # controlli e test non fermano la simulazione: il gioco si prova lo stesso
        for passo in (controlli, test_sim):
            try:
                passo()
            except Fallito as e:
                problemi.append(str(e))
        exe = build(out, "" if args.solo_build else impostazioni(args.scenario.resolve()))
        if not args.solo_build:
            gioca(exe, out, args.scenario.resolve(), not args.senza_video)
    except Fallito as e:
        problemi.append(str(e))
    dove = f"risultati in {out.relative_to(REPO)}/"
    if problemi:
        for p in problemi:
            info(f"FALLITO: {p}")
        info(dove)
        return 1
    info(f"OK, {dove}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
