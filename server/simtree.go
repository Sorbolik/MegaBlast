package main

import (
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"sort"

	megablast "github.com/Sorbolik/MegaBlast"
)

// simTree is the fingerprint of the simulation the server runs: the hash git
// gives to the client/sim folder (git rev-parse HEAD:client/sim), worked out from
// the embedded files. The APK and the web build carry the same hash
// (megablast.sim in the build's settings, apk.yml and tools/web/build.sh) and
// send it with the greeting: a phone with another simulation would play a
// different match and drop every few seconds with "stato diverso" (Sergio, 23
// Nov: the loop of reconnections), so it is told to update instead. Who sends
// nothing (the simulator, a build from the editor) isn't checked.
var simTree = mustSimTree()

func mustSimTree() string {
	h, err := gitTree("client/sim")
	if err != nil {
		panic(err)
	}
	return h
}

// gitTree: the git hash of a folder of plain files (mode 100644, no subfolders)
// in the embedded files
func gitTree(dir string) (string, error) {
	entries, err := megablast.SimFS.ReadDir(dir)
	if err != nil {
		return "", err
	}
	names := make([]string, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() {
			return "", fmt.Errorf("%s/%s: sottocartella non prevista", dir, e.Name())
		}
		names = append(names, e.Name())
	}
	sort.Strings(names)
	var tree []byte
	for _, name := range names {
		src, err := megablast.SimFS.ReadFile(dir + "/" + name)
		if err != nil {
			return "", err
		}
		blob := sha1.Sum(append(fmt.Appendf(nil, "blob %d\x00", len(src)), src...))
		tree = append(fmt.Appendf(tree, "100644 %s\x00", name), blob[:]...)
	}
	sum := sha1.Sum(append(fmt.Appendf(nil, "tree %d\x00", len(tree)), tree...))
	return hex.EncodeToString(sum[:]), nil
}
