//go:build !unix

package main

// lowPriority: only on Unix (the VPS); elsewhere the process keeps its priority.
func lowPriority(pid int) {}
