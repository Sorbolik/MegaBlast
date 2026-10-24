package main

import (
	"math"
	"strconv"

	lua "github.com/yuin/gopher-lua"
)

// appendJSON scrive in JSON un valore Lua fatto di tabelle, numeri, stringhe e
// booleani. Una tabella con solo la parte a lista (o vuota) diventa un array.
// I numeri interi restano interi, gli altri hanno due decimali: bastano per
// posizioni e angoli e tengono piccoli i messaggi.
func appendJSON(b []byte, v lua.LValue) []byte {
	switch v := v.(type) {
	case lua.LNumber:
		f := float64(v)
		switch {
		case math.IsNaN(f) || math.IsInf(f, 0):
			return append(b, '0')
		case f == math.Trunc(f) && math.Abs(f) < 1e15:
			return strconv.AppendInt(b, int64(f), 10)
		default:
			return strconv.AppendFloat(b, f, 'f', 2, 64)
		}
	case lua.LBool:
		return strconv.AppendBool(b, bool(v))
	case lua.LString:
		return appendString(b, string(v))
	case *lua.LTable:
		n := v.Len()
		if n > 0 || isEmpty(v) {
			b = append(b, '[')
			for i := 1; i <= n; i++ {
				if i > 1 {
					b = append(b, ',')
				}
				b = appendJSON(b, v.RawGetInt(i))
			}
			return append(b, ']')
		}
		b = append(b, '{')
		first := true
		v.ForEach(func(k, val lua.LValue) {
			key, ok := k.(lua.LString)
			if !ok {
				return
			}
			if !first {
				b = append(b, ',')
			}
			first = false
			b = appendString(b, string(key))
			b = append(b, ':')
			b = appendJSON(b, val)
		})
		return append(b, '}')
	default:
		return append(b, "null"...)
	}
}

func isEmpty(t *lua.LTable) bool {
	k, _ := t.Next(lua.LNil)
	return k == lua.LNil
}

func appendString(b []byte, s string) []byte {
	b = append(b, '"')
	for i := 0; i < len(s); i++ {
		c := s[i]
		switch {
		case c == '"' || c == '\\':
			b = append(b, '\\', c)
		case c < 0x20:
			b = append(b, `\u00`...)
			b = append(b, "0123456789abcdef"[c>>4], "0123456789abcdef"[c&15])
		default:
			b = append(b, c)
		}
	}
	return append(b, '"')
}
