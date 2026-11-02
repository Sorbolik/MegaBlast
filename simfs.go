// Package megablast holds the game simulation in Lua, shared between the
// Defold client and the Go server. The server embeds it in the executable.
package megablast

import "embed"

//go:embed client/sim/*.lua
var SimFS embed.FS
