package main

import (
	"fmt"
	gg "classico/golani"
	"g1/_build"
)

func main() {
	if _build.JOJO != "" {
		fmt.Println("JOJO!")
	}
	fmt.Println("Hello, world: ", gg.Getenv("FOO", "nofoo"))
}
