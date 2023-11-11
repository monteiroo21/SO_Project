#!/bin/bash

directory="Teste 3/aula2/ex"
dir="Teste 3"
if [[ "$directory" == "$dir/"* ]]; then
    echo "A string coincide com o padrão 'Teste 3/*'"
else
    echo "A string NÃO coincide com o padrão 'Teste 3/*'"
fi

