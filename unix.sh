#!/bin/sh

psg () {
	ps auxww | grep "$1" | grep -v grep
}
