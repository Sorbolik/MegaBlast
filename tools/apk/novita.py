"""Scrive il messaggio Telegram che accompagna l'APK: per ogni PR entrata in main
dalla build precedente il titolo, il numero, il ramo e la sezione "Per Telegram"
del corpo della PR (cosa cambia nel gioco, detto per una persona).

Da un ramo che non è main (build lanciata a mano da Actions) il messaggio lo dice
nella prima riga, ben in vista, e mostra la PR di quel ramo.

Uso: python3 novita.py COMMIT_PRIMA [RAMO]   (vuoto: solo l'ultimo commit)
     python3 novita.py --didascalia RAMO     (la riga sotto il file dell'APK)
Legge GITHUB_REPOSITORY e GITHUB_TOKEN per chiedere le PR a GitHub."""
import json
import os
import re
import subprocess
import sys
import urllib.request

LIMITE = 4000  # Telegram accetta messaggi fino a 4096 caratteri


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout.strip()


def commit_nuovi(prima):
    giro = "HEAD~1..HEAD"
    if prima and not re.fullmatch(r"0+", prima):
        try:
            git("cat-file", "-e", prima + "^{commit}")
            giro = prima + "..HEAD"
        except subprocess.CalledProcessError:
            pass
    righe = git("log", "--first-parent", "--format=%H", giro)
    return righe.split() if righe else []


def github(percorso):
    repo, token = os.environ.get("GITHUB_REPOSITORY"), os.environ.get("GITHUB_TOKEN")
    if not repo or not token:
        return []
    req = urllib.request.Request(
        f"https://api.github.com/repos/{repo}/{percorso}",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.load(r)
    except Exception as e:  # senza PR il messaggio usa il titolo del commit
        print(f"novita: {percorso} non trovato ({e})", file=sys.stderr)
        return []


def pr_del_commit(sha):
    prs = github(f"commits/{sha}/pulls")
    unite = [p for p in prs if p.get("merged_at")]
    return (unite or prs or [None])[0]


def pr_del_ramo(ramo):
    """La PR aperta di un ramo (se non ce n'è una aperta, l'ultima)."""
    proprietario = os.environ.get("GITHUB_REPOSITORY", "").split("/")[0]
    prs = github(f"pulls?state=all&head={proprietario}:{ramo}")
    aperte = [p for p in prs if p.get("state") == "open"]
    return (aperte or prs or [None])[0]


def da_main(ramo):
    return ramo in ("", "main")


def testata(ramo, pr=None):
    """Prima riga di didascalia e messaggio: si vede subito da dove viene l'APK."""
    commit = git("log", "-1", "--format=%h")
    if da_main(ramo):
        return f"✅ MAIN · MegaBlast {commit}"
    numero = f", PR #{pr['number']}" if pr else ""
    return f"🧪 PROVA, NON È MAIN · ramo {ramo}{numero} · MegaBlast {commit}"


def per_telegram(corpo):
    """Sezione "## Per Telegram" del corpo; se manca, il primo paragrafo di testo."""
    corpo = (corpo or "").replace("\r\n", "\n")
    m = re.search(r"^#+\s*Per Telegram\s*\n(.*?)(?=^#+\s|\Z)", corpo, re.S | re.M | re.I)
    if m:
        return m.group(1).strip()
    for blocco in corpo.split("\n\n"):
        b = blocco.strip()
        if b and not b.startswith(("<!--", "_Requested", "#", "🤖", "https://", "---")):
            return b
    return ""


def voce(sha, pr=None):
    pr = pr or pr_del_commit(sha)
    if not pr:
        titolo = git("log", "-1", "--format=%s", sha)
        if titolo.startswith("Merge pull request"):  # il titolo vero della PR è nel corpo
            titolo = (git("log", "-1", "--format=%b", sha).splitlines() or [titolo])[0]
        return "• " + titolo
    testa = f"• {pr['title']} (#{pr['number']}, ramo {pr['head']['ref']})"
    testo = per_telegram(pr.get("body"))
    return testa + ("\n" + testo if testo else "")


def main():
    if sys.argv[1:2] == ["--didascalia"]:
        ramo = sys.argv[2] if len(sys.argv) > 2 else ""
        print(testata(ramo, None if da_main(ramo) else pr_del_ramo(ramo)))
        return
    prima = sys.argv[1] if len(sys.argv) > 1 else ""
    ramo = sys.argv[2] if len(sys.argv) > 2 else ""
    if da_main(ramo):
        voci = [voce(h) for h in commit_nuovi(prima)]
        testo = testata(ramo) + ": cosa c'è di nuovo\n\n" + "\n\n".join(voci)
    else:  # su un ramo conta la sua PR, non i commit uno per uno
        pr = pr_del_ramo(ramo)
        testo = (testata(ramo, pr) + "\nQuesta versione non è ancora sul main.\n\n"
                 + voce(git("rev-parse", "HEAD"), pr))
    if len(testo) > LIMITE:
        testo = testo[:LIMITE - 2] + "\n…"
    print(testo)


if __name__ == "__main__":
    main()
