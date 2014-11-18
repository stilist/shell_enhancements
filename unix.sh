#!/bin/sh

# http://stackoverflow.com/questions/6796982/clang-and-the-default-compiler-in-os-x-lion

psg () {
	ps auxww | grep "$1" | grep -v grep
}
