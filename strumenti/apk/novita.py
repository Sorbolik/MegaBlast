"""Scrive il messaggio Telegram che accompagna l'APK: per ogni PR entrata in main
dalla build precedente il titolo, il numero, il ramo e la sezione "Per Telegram"
del corpo della PR (cosa cambia nel gioco, detto per una persona).

Uso: python3 novita.py COMMIT_PRIMA   (vuoto: solo l'ultimo commit)
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


def pr_del_commit(sha):
    repo, token = os.environ.get("GITHUB_REPOSITORY"), os.environ.get("GITHUB_TOKEN")
    if not repo or not token:
        return None
    req = urllib.request.Request(
        f"https://api.github.com/repos/{repo}/commits/{sha}/pulls",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            prs = json.load(r)
    except Exception as e:  # senza PR il messaggio usa il titolo del commit
        print(f"novita: PR di {sha[:7]} non trovata ({e})", file=sys.stderr)
        return None
    unite = [p for p in prs if p.get("merged_at")]
    return (unite or prs or [None])[0]


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


def voce(sha):
    pr = pr_del_commit(sha)
    if not pr:
        titolo = git("log", "-1", "--format=%s", sha)
        if titolo.startswith("Merge pull request"):  # il titolo vero della PR è nel corpo
            titolo = (git("log", "-1", "--format=%b", sha).splitlines() or [titolo])[0]
        return "• " + titolo
    testa = f"• {pr['title']} (#{pr['number']}, ramo {pr['head']['ref']})"
    testo = per_telegram(pr.get("body"))
    return testa + ("\n" + testo if testo else "")


def main():
    prima = sys.argv[1] if len(sys.argv) > 1 else ""
    voci = [voce(h) for h in commit_nuovi(prima)]
    testo = f"MegaBlast {git('log', '-1', '--format=%h')}: cosa c'è di nuovo\n\n" + "\n\n".join(voci)
    if len(testo) > LIMITE:
        testo = testo[:LIMITE - 2] + "\n…"
    print(testo)


if __name__ == "__main__":
    main()
