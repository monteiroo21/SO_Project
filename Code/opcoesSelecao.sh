#!/bin/bash

nome=""
dataMax=""
tamanhoMin=""

# Processa as opções da linha de comando
while getopts ":n:d:s:" opt; do
    case $opt in
        n)
            nome="$OPTARG"
            ;;
        d)
            dataMax="$OPTARG"
            ;;
        s)
            tamanhoMin="$OPTARG"
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

# Exiba as variáveis para verificar se elas foram atualizadas corretamente
echo "nome: $nome"
echo "dataMax: $dataMax"
echo "tamanhoMin: $tamanhoMin"

# Processamento dos diretórios em baixo

# Cria ou substitui o arquivo "dados.txt"
> dados.txt

# Verifica se um diretório foi especificado
if [ $# -eq 0 ]; then # verifica se restaram argumentos na linha de comando
    echo "ERRO: Nenhum diretório especificado." >&2
    display_help
fi

# Armazena o diretório de destino
main_directory="$1"




# Seleção dos ficheiros a contabilizar depende da opção
if [ ! -z "$nome" ] && [ ! -z "$dataMax" ] && [ ! -z "$tamanhoMin" ]; then
    echo 'ola'
    find "$main_directory" -type d | while read -r directory; do
    if  [ -n "$(find "$directory" -type f -regex "$nome" -newermt "$dataMax" -size +794000c)" ]; then
            size=$(du -b "$directory")
            echo $directory
	    echo "$size"
        fi
    done
fi
