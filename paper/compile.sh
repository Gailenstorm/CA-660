#!/usr/bin/bash
bibtex report
xelatex report.tex
xelatex -interaction=batchmode  -halt-on-error * report.tex
