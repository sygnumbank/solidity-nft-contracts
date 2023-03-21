VARS=$(compgen -v)
compgen -v | while read line; do if [[ $line == CONTRACT* ]]; then printf "$line=${(P)line}\n" >> calldata.txt; fi; done