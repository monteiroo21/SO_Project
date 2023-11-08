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


fileA="$1"
fileB="$2"
declare -A fileA_dict
declare -A fileB_dict
declare -A rate_dict

function realSize {
    local directory="$1"
    local size=0

    if [[ "$2" == "A" ]]; then
      for key in "${!fileA_dict[@]}"; do
          if [[ "$key" == "$directory" || "$key" == "$directory/"* ]]; then
              if [[ "$key" == "$directory" ]]; then # Se for o próprio diretório
                size=${fileA_dict["$key"]}
              else
                  size=$((size - fileA_dict["$key"]))
              fi
          fi
      done
    else
      for key in "${!fileB_dict[@]}"; do
          if [[ "$key" == "$directory" || "$key" == "$directory/"* ]]; then
              if [[ "$key" == "$directory" ]]; then # Se for o próprio diretório
                size=${fileB_dict["$key"]}
              else
                  size=$((size - fileB_dict["$key"]))
              fi
          fi
      done
    fi

    echo "$size"
}



# Função que calcula a evolução do espaço ocupado
calculate_size_evolution(){
    while IFS= read -r lineB; do
        if [[ "$lineB" == "SIZE NAME"* ]]; then
            continue
        else
            folderB=$(echo "$lineB" | awk '{print $2}')
            sizeB=$(echo "$lineB" | awk '{print $1}')
            fileB_dict["$folderB"]="$sizeB"
        fi
    done < "$fileB"


    while IFS= read -r lineA; do
        if [[ "$lineA" == "SIZE NAME"* ]]; then
            continue
        else
            folderA=$(echo "$lineA" | awk '{print $2}')
            sizeA=$(echo "$lineA" | awk '{print $1}')
            fileA_dict["$folderA"]="$sizeA";
        fi
    done < "$fileA"


    # Loop para calcular as diferenças
    for key in "${!fileA_dict[@]}"; do
        if [[ -n ${fileB_dict[$key]+x} ]]; then
            sizeB=$(realSize "$key")
            sizeA=$(realSize "$key" "A")
            size_rate=$((sizeA-sizeB))
            rate_dict["$key"]=$size_rate
        else
            sizeA=$(realSize "$key" "A")
            key_new="$key NEW"
            rate_dict["$key_new"]=$sizeA
        fi
    done

    for key in "${!fileB_dict[@]}"; do
        if [[ ! -n ${fileA_dict[$key]+x} ]]; then
            echo "ola"
            sizeB=$(realSize "$key")
            key_removed="$key REMOVED"
            rate_dict["$key_removed"]=$sizeB
        fi
    done

}

calculate_size_evolution
printHeader

for key in "${!rate_dict[@]}"; do
    echo "${rate_dict[$key]} $key"
done