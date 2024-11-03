
package golani

import "os"

func Getenv(name, _default string) string {
	val, exists := os.LookupEnv(name)
	if exists {
		return val
	} else {
		return _default
	}
}
