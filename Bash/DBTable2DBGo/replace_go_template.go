package main

import (
	"fmt"
	"os"
	"text/template"
)

func readFileAll(filename string) ([]byte, error) {
	fp, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer fp.Close()

	fileInfo, err := fp.Stat()
	if err != nil {
		return nil, err
	}
	buffer := make([]byte, fileInfo.Size())
	_, err = fp.Read(buffer)
	if err != nil {
		return nil, err
	}

	return buffer, nil
}

func usage() {
	fmt.Fprintf(os.Stderr, `
	Usage:
	    template_file registers_file  types_file 
		`)
	os.Exit(-1)
}

func main() {

	arg_num := len(os.Args)
	if arg_num < 4 {
		usage()
	}

	type GoTemplKey struct {
		Types     string
		Registers string
	}

	tplFile := os.Args[1]
	registersFile := os.Args[2]
	typesFile := os.Args[3]
	registersContent, err := readFileAll(registersFile)
	if err != nil {
		fmt.Fprintln(os.Stderr, "read regsiter.go error: ", err)
		os.Exit(-1)
	}

	typesContent, err := readFileAll(typesFile)
	if err != nil {
		fmt.Fprintln(os.Stderr, "read regsiter.go error: ", err)
		os.Exit(-1)
	}

	k := GoTemplKey{Types: string(typesContent), Registers: string(registersContent)}
	templ, err := template.ParseFiles(tplFile)
	if err != nil {
		fmt.Fprintln(os.Stderr, "parse template regsiter.go error: ", err)
		os.Exit(-1)
	}

	err = templ.Execute(os.Stdout, k)
	if err != nil {
		fmt.Fprintln(os.Stderr, "execute parse error: ", err)
		os.Exit(-1)
	}
}
