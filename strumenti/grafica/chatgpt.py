# Parla con ChatGPT (API di OpenAI) da qui: genera o modifica immagini e fa domande
# di testo, senza passare dalla chat di ChatGPT.
#
# Serve la chiave nella variabile d'ambiente OPENAI_API_KEY (mai nel repository) e
# api.openai.com tra i domini permessi dell'ambiente. Solo libreria standard di Python.
#
# Immagini nuove:
#   python3 strumenti/grafica/chatgpt.py immagine "testa del diavoletto, contorno nero spesso" --nome testa
# Immagini partendo da riferimenti (lo stampino, il diavoletto attuale...):
#   python3 strumenti/grafica/chatgpt.py immagine --prompt-file prompt.txt --rif stampino.png --rif stile.png
# Testo (chiedere un parere, un prompt, una descrizione):
#   python3 strumenti/grafica/chatgpt.py testo "come renderesti più leggibile questa sagoma?" --rif foto.png
#
# Ogni immagine finisce in /mnt/project-files/chatgpt/ (o --cartella) con accanto
# un .txt con prompt, modello, qualità e riferimenti, così si ritrova come è nata.
# --prova stampa la richiesta senza mandarla (e senza spendere).
import argparse
import base64
import datetime
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.request
import uuid

API = "https://api.openai.com/v1"
CARTELLA = "/mnt/project-files/chatgpt"


def chiave(prova):
    k = os.environ.get("OPENAI_API_KEY", "")
    if not k and not prova:
        sys.exit("Manca OPENAI_API_KEY nell'ambiente.")
    return k


def manda(percorso, corpo, tipo, k, prova):
    if prova:
        print(f"POST {API}{percorso}  ({tipo.split(';')[0]}, {len(corpo)} byte)")
        if tipo == "application/json":
            print(corpo.decode())
        return None
    req = urllib.request.Request(API + percorso, data=corpo, method="POST", headers={
        "Authorization": "Bearer " + k, "Content-Type": tipo})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"OpenAI ha risposto {e.code}: {e.read().decode(errors='replace')}")


def multipart(campi, file):
    # campi: [(nome, valore)], file: [(nome, percorso)]
    confine = uuid.uuid4().hex
    parti = []
    for nome, valore in campi:
        parti.append(f'--{confine}\r\nContent-Disposition: form-data; name="{nome}"\r\n\r\n{valore}\r\n'.encode())
    for nome, percorso in file:
        tipo = mimetypes.guess_type(percorso)[0] or "application/octet-stream"
        with open(percorso, "rb") as f:
            dati = f.read()
        testa = (f'--{confine}\r\nContent-Disposition: form-data; name="{nome}"; '
                 f'filename="{os.path.basename(percorso)}"\r\nContent-Type: {tipo}\r\n\r\n')
        parti.append(testa.encode() + dati + b"\r\n")
    parti.append(f"--{confine}--\r\n".encode())
    return b"".join(parti), "multipart/form-data; boundary=" + confine


def leggi_prompt(a):
    if a.prompt_file:
        with open(a.prompt_file, encoding="utf-8") as f:
            return f.read().strip()
    if not a.prompt:
        sys.exit("Serve un prompt (testo o --prompt-file).")
    return a.prompt


def immagine(a):
    k = chiave(a.prova)
    prompt = leggi_prompt(a)
    campi = [("model", a.modello), ("prompt", prompt), ("n", str(a.n)), ("size", a.misura),
             ("quality", a.qualita), ("background", a.sfondo), ("output_format", "png")]
    if a.rif:
        # con riferimenti: endpoint delle modifiche, le immagini guidano forma e stile
        file = [("image[]", p) for p in a.rif]
        if a.maschera:
            file.append(("mask", a.maschera))
        corpo, tipo = multipart(campi, file)
        risp = manda("/images/edits", corpo, tipo, k, a.prova)
    else:
        corpo = json.dumps({n: (int(v) if n == "n" else v) for n, v in campi}, ensure_ascii=False).encode()
        risp = manda("/images/generations", corpo, "application/json", k, a.prova)
    if risp is None:
        return
    os.makedirs(a.cartella, exist_ok=True)
    base = datetime.datetime.now().strftime("%Y%m%d_%H%M%S") + "_" + a.nome
    nota = {"prompt": prompt, "modello": a.modello, "qualita": a.qualita, "misura": a.misura,
            "sfondo": a.sfondo, "riferimenti": a.rif or [], "maschera": a.maschera,
            "uso": risp.get("usage")}
    for i, d in enumerate(risp["data"]):
        percorso = os.path.join(a.cartella, f"{base}_{i + 1}.png" if a.n > 1 else f"{base}.png")
        with open(percorso, "wb") as f:
            f.write(base64.b64decode(d["b64_json"]))
        print(percorso)
    with open(os.path.join(a.cartella, base + ".txt"), "w", encoding="utf-8") as f:
        json.dump(nota, f, ensure_ascii=False, indent=2)


def testo(a):
    k = chiave(a.prova)
    contenuto = [{"type": "input_text", "text": leggi_prompt(a)}]
    for p in a.rif or []:
        tipo = mimetypes.guess_type(p)[0] or "image/png"
        with open(p, "rb") as f:
            url = f"data:{tipo};base64," + base64.b64encode(f.read()).decode()
        contenuto.append({"type": "input_image", "image_url": url})
    corpo = json.dumps({"model": a.modello, "input": [{"role": "user", "content": contenuto}]},
                       ensure_ascii=False).encode()
    risp = manda("/responses", corpo, "application/json", k, a.prova)
    if risp is None:
        return
    for uscita in risp.get("output", []):
        for c in uscita.get("content", []) or []:
            if c.get("type") == "output_text":
                print(c["text"])


def main():
    p = argparse.ArgumentParser(description="Parla con ChatGPT (API OpenAI) da qui.")
    sub = p.add_subparsers(dest="cosa", required=True)

    i = sub.add_parser("immagine", help="genera o modifica immagini")
    i.add_argument("prompt", nargs="?")
    i.add_argument("--prompt-file")
    i.add_argument("--rif", action="append", help="immagine di riferimento (ripetibile)")
    i.add_argument("--maschera", help="PNG: le zone trasparenti sono quelle da ridisegnare")
    i.add_argument("--nome", default="immagine", help="nome del file in uscita")
    i.add_argument("--modello", default="gpt-image-1.5")
    i.add_argument("--qualita", default="medium", choices=["low", "medium", "high", "auto"])
    i.add_argument("--misura", default="1024x1024", help="1024x1024, 1536x1024, 1024x1536, auto")
    i.add_argument("--sfondo", default="transparent", choices=["transparent", "opaque", "auto"])
    i.add_argument("--n", type=int, default=1, help="quante varianti")
    i.add_argument("--cartella", default=CARTELLA)
    i.add_argument("--prova", action="store_true")
    i.set_defaults(fai=immagine)

    t = sub.add_parser("testo", help="domanda di testo (anche con immagini da guardare)")
    t.add_argument("prompt", nargs="?")
    t.add_argument("--prompt-file")
    t.add_argument("--rif", action="append", help="immagine da far guardare (ripetibile)")
    t.add_argument("--modello", default="gpt-5")
    t.add_argument("--prova", action="store_true")
    t.set_defaults(fai=testo)

    a = p.parse_args()
    a.fai(a)


if __name__ == "__main__":
    main()
