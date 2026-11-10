#!/bin/bash
# Suoni dei colpi, sintetizzati da zero (nessuna licenza): colpo.ogg, boom.ogg, ko.ogg
# in client/assets/sounds/. Serve ffmpeg. Il gioco li suona con tono e volume diversi.
set -e
OUT="$(cd "$(dirname "$0")/../.." && pwd)/client/assets/sounds"
Q="-c:a libvorbis -q:a 4 -ar 44100 -ac 1"
# colpo: tonfo corto che scende di tono + uno schiocco di rumore
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=0.9*sin(2*PI*(55*t+ (140*(0.07))*(1-exp(-t/0.07)) ))*exp(-t/0.06)+0.5*(random(0)*2-1)*exp(-t/0.012):d=0.25:s=44100" $Q "$OUT/colpo.ogg"
# boom: rimbombo di rumore scuro che si spegne piano + tonfo basso
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=0.8*sin(2*PI*(38*t+ (90*(0.12))*(1-exp(-t/0.12)) ))*exp(-t/0.22)+0.9*(random(0)*2-1)*exp(-t/0.09):d=1.0:s=44100" -af "lowpass=f=1800,highpass=f=30,alimiter=limit=0.9" $Q "$OUT/boom.ogg"
# ko: tonfo lungo che affonda
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=0.9*sin(2*PI*(90*t-60*t*t))*exp(-t/0.25)+0.3*(random(0)*2-1)*exp(-t/0.03):d=0.7:s=44100" $Q "$OUT/ko.ogg"
# scaglia: tintinnio d'ottone corto (parziali di campanella 1 / 2,76 / 5,4), una moneta che arriva
# nel portafoglio; il gioco lo suona un semitono più alto a ogni scaglia, più basso per l'Ossidiana
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=(0.6*sin(2*PI*2093*t)*exp(-t/0.09)+0.3*sin(2*PI*2093*2.76*t)*exp(-t/0.04)+0.15*sin(2*PI*2093*5.4*t)*exp(-t/0.02))*min(1\,t/0.002):d=0.25:s=44100" -af "alimiter=limit=0.8" $Q "$OUT/scaglia.ogg"
# martello: il colpo sull'incudine dello scatto di un pezzo (tonfo, schiocco e una nota di metallo)
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=0.7*sin(2*PI*(70*t+12*(1-exp(-t/0.05))))*exp(-t/0.08)+0.5*(random(0)*2-1)*exp(-t/0.01)+0.35*sin(2*PI*1320*t)*exp(-t/0.18)+0.2*sin(2*PI*1320*2.4*t)*exp(-t/0.08):d=0.5:s=44100" -af "alimiter=limit=0.9" $Q "$OUT/martello.ogg"
# xp: un "plin" tondo e caldo (D6 con la sua ottava), una scintilla di esperienza che arriva nella barra;
# il gioco lo suona un semitono più alto a ogni scintilla
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=(0.6*sin(2*PI*1175*t)*exp(-t/0.11)+0.25*sin(2*PI*2350*t)*exp(-t/0.05))*min(1\,t/0.003):d=0.3:s=44100" -af "alimiter=limit=0.8" $Q "$OUT/xp.ogg"
# livello: arpeggio in alto (do-mi-sol-do) che resta come accordo, il salto di livello
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=gte(t\,0)*0.4*sin(2*PI*523*t)*exp(-t/0.5)+gte(t\,0.09)*0.4*sin(2*PI*659*t)*exp(-(t-0.09)/0.5)+gte(t\,0.18)*0.4*sin(2*PI*784*t)*exp(-(t-0.18)/0.5)+gte(t\,0.27)*(0.5*sin(2*PI*1047*t)+0.2*sin(2*PI*2093*t))*exp(-(t-0.27)/0.6):d=1.3:s=44100" -af "alimiter=limit=0.85" $Q "$OUT/livello.ogg"
