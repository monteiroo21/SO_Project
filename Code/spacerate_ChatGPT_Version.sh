#!/bin/bash

# Opções de Visualização
r=0
a=0
l=0


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
            if [ "$l" -lt 0 ]; then
                echo "Insert a number of lines that is bigger than zero!"
                exit 1;
            fi
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

#if [ $# -eq 2 ]; then # verifica se restaram argumentos na linha de comando
  #  echo "ERRO: Especifique dois ficheiros." >&2
 #   display_help
#fi

#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Erro: Especifique dois arquivos para comparar." >&2
    exit 1
fi

fileA="$1"
fileB="$2"

# Função que calcula a evolução do espaço ocupado
calculate_size_evolution() {
    declare -A fileA_dict
    declare -A fileB_dict
    declare -A rate_dict

    while IFS= read -r line; do
        if [[ "$line" == "SIZE NAME" ]]; then
            continue
        fi

        sizeA=$(echo "$line" | awk '{print $1}')
        folderA=$(echo "$line" | awk '{print $2}')
        if [[ "$folderA" == "NAME" ]]; then
            continue
        fi
        fileA_dict["$folderA"]="$sizeA"
    done < "$fileA"

    while IFS= read -r line; do
        if [[ "$line" == "SIZE NAME" ]]; then
            continue
        fi

        sizeB=$(echo "$line" | awk '{print $1}')
        folderB=$(echo "$line" | awk '{print $2}')
        if [[ "$folderB" == "NAME" ]]; then
            continue
        fi
        fileB_dict["$folderB"]="$sizeB"
    done < "$fileB"

    for folderA in "${!fileA_dict[@]}"; do
        sizeA="${fileA_dict[$folderA]}"
        if [[ -n ${fileB_dict[$folderA]+x} ]]; then
            sizeB="${fileB_dict[$folderA]}"
            size_rate=$((sizeB - sizeA))
            rate_dict["$folderA"]=$size_rate
        else
            size_rate=-$sizeA
            rate_dict["$folderA REMOVED"]=$size_rate
        fi
    done

    for folderB in "${!fileB_dict[@]}"; do
        if [[ -z ${fileA_dict[$folderB]+x} ]]; then
            sizeB="${fileB_dict[$folderB]}"
            rate_dict["$folderB NEW"]=$sizeB
        fi
    done

    for key in "${!rate_dict[@]}"; do
        if [[ $key == *" REMOVED" ]] && [[ ${rate_dict[$key]} -eq 0 ]]; then
            unset rate_dict["$key"]
        fi
    done

    for key in "${!rate_dict[@]}"; do
        echo "${rate_dict[$key]} $key"
    done
}

printHeader() {
    printf "%5s %s\n" "SIZE" "NAME"
}

printHeader
calculate_size_evolution "$fileA" "$fileB"
