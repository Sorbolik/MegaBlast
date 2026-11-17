//go:build unix

package main

import "syscall"

// lowPriority gives a process the lowest CPU priority (nice 19).
func lowPriority(pid int) {
	_ = syscall.Setpriority(syscall.PRIO_PROCESS, pid, 19)
}
