// Il contrario di leggi.js: porta nel Figma i numeri di tools/figma/interfaccia.json
// quando cambiano nel codice (una PR che tocca ui.C o le forme di tools/grafica/ui.py).
// Claude incolla qui sotto, al posto di DATI, il contenuto di interfaccia.json e
// passa lo script a use_figma. I componenti usano le variabili: si aggiornano da soli.
const DATI = {/* contenuto di interfaccia.json */};
const cols = await figma.variables.getLocalVariableCollectionsAsync();
const cambiate = [];
for (const col of cols) {
  const modo = col.modes[0].modeId;
  for (const id of col.variableIds) {
    const v = await figma.variables.getVariableByIdAsync(id);
    if (col.name === "Colori ui C" && DATI.colori[v.name]) {
      const [r, g, b, a] = DATI.colori[v.name]; v.setValueForMode(modo, { r, g, b, a }); cambiate.push(v.name);
    }
    if (col.name === "Misure ui lua" && DATI.forme[v.name] !== undefined) { v.setValueForMode(modo, DATI.forme[v.name]); cambiate.push(v.name); }
  }
}
return { cambiate };
