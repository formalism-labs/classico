
package golani

import "os"

type _Path struct {
    path string
}

func Path(path string) _Path {
	return _Path {path}
}

func (path _Path) Exists() bool {
	_, err := os.Stat(path.path)
    if err == nil { return true }
    if os.IsNotExist(err) { return false }
    return true
}

func (path _Path) IsDir() bool {
	if fi, err := os.Stat(path.path); err == nil {
        if fi.Mode().IsDir() {
            return true
        }
    }
    return false	
}
