#!/bin/bash
for file in `ls -1 t/*.t`; do
	prove -l -v $file
done
