#!/bin/bash

# Opções de Visualização
r=0
a=0
l=0

# Dá print ao cabeçalho (função incompleta já vou trabalhar nisso)
printHeader(){
    printf "%4s %4s\n" "SIZE" "NAME"
}

# Processa as opções da linha de comando
while getopts ":ral:" opt; do
    case $opt in
        r)
            r=1
            ;;
        a)
            a=1
            ;;
        l)
            l="$OPTARG"
            ;;
        \?)
            echo "Opção inválida: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "A opção -$OPTARG requer um argumento." >&2
            exit 1
            ;;
    esac
done

# Remove as opções processadas da linha de comando
shift $((OPTIND-1))

# Agora, os argumentos remanescentes em "$@" são os diretórios a serem processados

# Cria ou substitui o arquivo "dados.txt"
> spacerate.txt

if [ $# -eq 2 ]; then # verifica se restaram argumentos na linha de comando
    echo "ERRO: Especifique dois ficheiros." >&2
    display_help
fi

fileA="$1"
fileB="$2"

# Função que calcula a evolução do espaço ocupado
calculate_size_evolution(){
    while IFS= read -r lineB; do
        if grep -q 'SIZE NAME' $fileB; then
            continue
        else
            folder=$(echo "$lineB" | awk '{print $2}')
            sizeB=$(echo "$lineB" | awk '{print $1}')
            while IFS= read -r lineA; do
                if grep -q 'SIZE NAME' $fileA; then
                    continue
                else    
                    if grep -q "$folder" $lineA; then
                        sizeA=$(echo "$lineBA" | awk '{print $1}')
                        sizeEvolution=$((sizeA - sizeB))
                    fi
                fi
            done < $fileA
        fi;
    done < $fileB
}

# Função para visualizar a ocupação do espaço como pretendido
display(){
    if [ "$a" -eq 0 ] && [ "$r" -eq 0 ] && [ "$l" -eq 0 ]; then
        sort -n -r spacerate.txt > spaceratedefault.txt
        while read line; do
            echo $line
        done < spaceratedefault.txt
    elif [ "$a" -eq 1 ]; then
        if [ "$r" -eq 1 ]; then
            echo "You can only choose one option between -a and -r. Try again"
        elif [ "$l" -gt 0 ]; then
            sort -k2 spacerate.txt > spaceratebyname.txt
            head -n "$l" spaceratebyname.txt
        else
            sort -k2 spacerate.txt > spaceratebyname.txt
            while read line; do
                echo $line
            done < spaceratebyname.txt
        fi
    elif [ "$r" -eq 1 ]; then
        if [ "$l" -gt 0 ]; then
            sort -n spacerate.txt > reversespacerate.txt
            head -n "$l" reversespacerate.txt
        else
            sort -n -r spacerate.txt > reversespacerate.txt
            while read line; do
                echo $line
            done < reversespacerate.txt
        fi
    elif [ "$l" -gt 0 ]; then
        head -n "$l" spaceratedefault.txt
    fi
}