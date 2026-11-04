# strumenti/grafica/ui_nuova.py
# Generatore di asset grafici vettoriali Hi-DPI per l'interfaccia di MegaBlast.
# Usa esclusivamente la libreria standard di Python (math, struct, zlib): zero dipendenze esterne.
# Calcola con precisione sub-pixel (antialiasing 4x/8x) le maschere delle varie categorie di pulsanti:
#   1. forma.png / bordo.png               -> Base universale 9-slice ad alta risoluzione
#   2. eroe_forma.png / eroe_bordo.png     -> Pulsanti Eroe (GIOCA, AVANTI, CONFERMA) con chamfer
#   3. menu_forma.png / menu_bordo.png     -> Pulsanti Menu (CAMPAGNA, ALLENAMENTO, ARMERIA)
#   4. slot_arma_forma.png / slot_arma_bordo.png -> Slot Armi da Battaglia con castone
#   5. gettone_forma.png / gettone_bordo.png     -> Gettoni Mobilità / Teletrasporto ottagonali
#   6. oggetto_forma.png / oggetto_bordo.png     -> Oggetti Tattici Menta compatti
#   7. sistema_forma.png / sistema_bordo.png     -> Controlli Sistema (Indietro, Rotellina, Zoom)
#   8. badge_forma.png / badge_bordo.png         -> Badge Munizioni ad alto contrasto

import math
import os
import struct
import zlib

OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "client", "assets", "ui"))
os.makedirs(OUT, exist_ok=True)

def write_png_rgba(width, height, rgba_data, filepath):
    """Scrive un file PNG RGBA standard usando zlib e struct."""
    raw = bytearray()
    row_bytes = width * 4
    for y in range(height):
        raw.append(0)  # Filter type 0 (None)
        start = y * row_bytes
        raw.extend(rgba_data[start : start + row_bytes])

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)  # 8 bit, RGBA (color type 6)
    idat = zlib.compress(bytes(raw), 9)

    with open(filepath, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))
    print(f"Generato con successo: {os.path.basename(filepath)} ({width}x{height})")

def render_sdf_pair(n, sdf_func, linea, nome_forma, nome_bordo, ss=6):
    """
    Esegue il rendering con supersampling subpixel di una funzione Signed Distance Field (SDF).
    sdf_func(x, y) restituisce la distanza dal bordo (negativa dentro, positiva fuori).
    """
    forma_rgba = bytearray(n * n * 4)
    bordo_rgba = bytearray(n * n * 4)

    half = n / 2.0
    sub_step = 1.0 / ss
    sub_offset = sub_step * 0.5
    total_samples = ss * ss

    for py in range(n):
        for px in range(n):
            inside_forma = 0
            inside_bordo = 0
            for sy in range(ss):
                sub_y = (py + sy * sub_step + sub_offset) - half
                for sx in range(ss):
                    sub_x = (px + sx * sub_step + sub_offset) - half
                    d = sdf_func(sub_x, sub_y)
                    if d <= 0.0:
                        inside_forma += 1
                        if d >= -linea:
                            inside_bordo += 1

            idx = (py * n + px) * 4

            # Forma (pieno bianco con alpha)
            af = int(round((inside_forma / total_samples) * 255.0))
            forma_rgba[idx] = 255
            forma_rgba[idx + 1] = 255
            forma_rgba[idx + 2] = 255
            forma_rgba[idx + 3] = af

            # Bordo (solo contorno bianco con alpha)
            ab = int(round((inside_bordo / total_samples) * 255.0))
            bordo_rgba[idx] = 255
            bordo_rgba[idx + 1] = 255
            bordo_rgba[idx + 2] = 255
            bordo_rgba[idx + 3] = ab

    write_png_rgba(n, n, forma_rgba, os.path.join(OUT, nome_forma))
    write_png_rgba(n, n, bordo_rgba, os.path.join(OUT, nome_bordo))

# ----------------------------------------------------------------------
# 1. BASE RETTANGOLARE UNIVERSALE (Hi-DPI 96x96, Slice9 = 24)
# ----------------------------------------------------------------------
def genera_base():
    n = 96
    hw, hh = n / 2.0 - 2, n / 2.0 - 2
    raggio = 20.0
    linea = 4.0
    def sdf(x, y):
        qx = abs(x) - (hw - raggio)
        qy = abs(y) - (hh - raggio)
        fuori = math.hypot(max(qx, 0.0), max(qy, 0.0))
        dentro = min(max(qx, qy), 0.0)
        return fuori + dentro - raggio
    render_sdf_pair(n, sdf, linea, "forma.png", "bordo.png")

# ----------------------------------------------------------------------
# 2. PULSANTE EROE (GIOCA, AVANTI) CON DOPPIO CHAMFER A 45°
# ----------------------------------------------------------------------
def genera_eroe():
    n = 96
    hw, hh = n / 2.0 - 2, n / 2.0 - 2
    smusso = 22.0
    linea = 4.5
    sqrt2 = 1.41421356
    def sdf(x, y):
        d_box = max(abs(x) - hw, abs(y) - hh)
        d_tr = (x + y) - (hw + hh - smusso * sqrt2)
        d_bl = (-x - y) - (hw + hh - smusso * sqrt2)
        return max(d_box, d_tr, d_bl)
    render_sdf_pair(n, sdf, linea, "eroe_forma.png", "eroe_bordo.png")

# ----------------------------------------------------------------------
# 3. PULSANTE MENU STRUTTURALE (CAMPAGNA, ALLENAMENTO, ARMERIA)
# ----------------------------------------------------------------------
def genera_menu():
    n = 96
    hw, hh = n / 2.0 - 2, n / 2.0 - 2
    raggio = 14.0
    linea = 3.5
    def sdf(x, y):
        qx = abs(x) - (hw - raggio)
        qy = abs(y) - (hh - raggio)
        fuori = math.hypot(max(qx, 0.0), max(qy, 0.0))
        dentro = min(max(qx, qy), 0.0)
        return fuori + dentro - raggio
    render_sdf_pair(n, sdf, linea, "menu_forma.png", "menu_bordo.png")

# ----------------------------------------------------------------------
# 4. SLOT ARMA DA COMBATTIMENTO (PRIMARIE & SECONDARIE)
# ----------------------------------------------------------------------
def genera_slot_arma():
    n = 96
    hw, hh = n / 2.0 - 2, n / 2.0 - 2
    smusso_top = 16.0
    linea = 4.0
    sqrt2 = 1.41421356
    def sdf(x, y):
        d_box = max(abs(x) - hw, abs(y) - hh)
        # Angoli in alto (y < 0) tagliati a 45°
        d_top_right = (x - y) - (hw + hh - smusso_top * sqrt2)
        d_top_left = (-x - y) - (hw + hh - smusso_top * sqrt2)
        return max(d_box, d_top_right, d_top_left)
    render_sdf_pair(n, sdf, linea, "slot_arma_forma.png", "slot_arma_bordo.png")

# ----------------------------------------------------------------------
# 5. GETTONE MOBILITÀ & TELETRASPORTO (OTTAGONALE REGOLARE)
# ----------------------------------------------------------------------
def genera_gettone():
    n = 96
    r = n / 2.0 - 3.0
    linea = 4.0
    sqrt2 = 1.41421356
    def sdf(x, y):
        d_box = max(abs(x) - r, abs(y) - r)
        d_diag = (abs(x) + abs(y)) / sqrt2 - r
        return max(d_box, d_diag)
    render_sdf_pair(n, sdf, linea, "gettone_forma.png", "gettone_bordo.png")

# ----------------------------------------------------------------------
# 6. OGGETTI TATTICI MENTA (ESAGONALE COMPATTO)
# ----------------------------------------------------------------------
def genera_oggetto():
    n = 80
    r = n / 2.0 - 3.0
    linea = 3.5
    def sdf(x, y):
        d1 = abs(x) - r * 0.866025
        d2 = (abs(x) * 0.5 + abs(y) * 0.866025) - r * 0.866025
        return max(d1, d2)
    render_sdf_pair(n, sdf, linea, "oggetto_forma.png", "oggetto_bordo.png")

# ----------------------------------------------------------------------
# 7. CONTROLLI DI SISTEMA (INDIETRO, ROTELLINA, ZOOM)
# ----------------------------------------------------------------------
def genera_sistema():
    n = 80
    hw, hh = n / 2.0 - 2, n / 2.0 - 2
    raggio = 16.0
    linea = 3.5
    def sdf(x, y):
        qx = abs(x) - (hw - raggio)
        qy = abs(y) - (hh - raggio)
        fuori = math.hypot(max(qx, 0.0), max(qy, 0.0))
        dentro = min(max(qx, qy), 0.0)
        return fuori + dentro - raggio
    render_sdf_pair(n, sdf, linea, "sistema_forma.png", "sistema_bordo.png")

# ----------------------------------------------------------------------
# 8. BADGE MUNIZIONI AD ALTO CONTRASTO
# ----------------------------------------------------------------------
def genera_badge():
    n = 48
    hw, hh = n / 2.0 - 1, n / 2.0 - 1
    raggio = 10.0
    linea = 2.5
    def sdf(x, y):
        qx = abs(x) - (hw - raggio)
        qy = abs(y) - (hh - raggio)
        fuori = math.hypot(max(qx, 0.0), max(qy, 0.0))
        dentro = min(max(qx, qy), 0.0)
        return fuori + dentro - raggio
    render_sdf_pair(n, sdf, linea, "badge_forma.png", "badge_bordo.png")


if __name__ == "__main__":
    print(f"Generazione asset Hi-DPI in corso verso: {OUT}")
    genera_base()
    genera_eroe()
    genera_menu()
    genera_slot_arma()
    genera_gettone()
    genera_oggetto()
    genera_sistema()
    genera_badge()
    print("Completata generazione di tutti gli asset.")
