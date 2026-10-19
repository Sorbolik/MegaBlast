// Package megablast contiene la simulazione di gioco in Lua, condivisa tra
// il client Defold e il server Go. Il server la incorpora nell'eseguibile.
package megablast

import "embed"

//go:embed client/sim/*.lua
var SimFS embed.FS
