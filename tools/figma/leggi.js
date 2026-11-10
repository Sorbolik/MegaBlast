// Legge le variabili del Figma dell'interfaccia e restituisce il contenuto di
// tools/figma/interfaccia.json (docs/figma.md). Claude lo passa così com'è al
// tool use_figma sul file MegaBlast · Interfaccia, poi salva il risultato in
// interfaccia.json (la chiave "nota" si tiene) e lancia tools/figma/applica.py.
const cols = await figma.variables.getLocalVariableCollectionsAsync();
const out = { colori: {}, forme: {} };
const r3 = v => Math.round(v * 1000) / 1000;
for (const col of cols) {
  const modo = col.modes[0].modeId;
  for (const id of col.variableIds) {
    const v = await figma.variables.getVariableByIdAsync(id);
    let val = v.valuesByMode[modo];
    if (val && val.type === "VARIABLE_ALIAS") val = (await figma.variables.getVariableByIdAsync(val.id)).valuesByMode[modo];
    if (col.name === "Colori ui C" && v.resolvedType === "COLOR") out.colori[v.name] = [r3(val.r), r3(val.g), r3(val.b), r3(val.a)];
    if (col.name === "Misure ui lua" && /^(forma\/(raggio|bordo)|eroe\/smusso|slot_arma\/(raggio|smusso)|pillola\/raggio|badge\/(raggio|bordo))$/.test(v.name)) out.forme[v.name] = val;
  }
}
return out;
