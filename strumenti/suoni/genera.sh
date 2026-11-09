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
