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
            if ! [[ "$l" =~ ^[1-9]+$ ]]; then
                echo "You have to give a number of lines greater then zero (an integer)!"
                exit 1;
            fi
            ;;

        \?)
            echo "Opção inválida: -$OPTARG" >&2
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

realSize(){
    local directory="$1"
    local size=0

    if [[ "$2" == "A" ]]; then
      for key in "${!fileA_dict[@]}"; do
          if [[ "$key" == "$directory" || ("$key" == "$directory"/* && "$key" != "$directory"/*/*) ]]; then
              if [[ "$key" == "$directory" ]]; then # Se for o próprio diretório
                size=$((size + fileA_dict["$key"]))
              else
                  size=$((size - fileA_dict["$key"])) # A chave é um subdiretório direto do diretório pai. Caso contrário estaria a descontar mais do que uma vez (se considerasse apenas "$directory"/*).
              fi
          fi
      done
    else
      for key in "${!fileB_dict[@]}"; do
          if [[ "$key" == "$directory" || ("$key" == "$directory"/* && "$key" != "$directory"/*/*) ]]; then
              if [[ "$key" == "$directory" ]]; then # Se for o próprio diretório
                size=$((size + fileB_dict["$key"]))
              else
                  size=$((size - fileB_dict["$key"])) # A chave é um subdiretório direto do diretório pai. Caso contrário estaria a descontar mais do que uma vez (se considerasse apenas "$directory"/*).
              fi
          fi
      done
    fi

    echo "$size"
}


# Função que calcula a evolução do espaço ocupado
calculate_size_evolution(){
    while read -r size path; do
        if [[ "$size" == "SIZE" ]]; then
            continue
        else
            fileA_dict["$path"]="$size"

        fi
    done <<< "$(cat "$fileA" | awk '{ printf $1; for (i=2; i<=NF; i++) printf " %s", $i; print "" }')"

    while read -r size path; do
            if [[ "$size" == "SIZE" ]]; then
                continue
            else
                fileB_dict["$path"]="$size"

            fi
    done <<< "$(cat "$fileB" | awk '{ printf $1; for (i=2; i<=NF; i++) printf " %s", $i; print "" }')"

    # Loop para calcular as diferenças
    for key in "${!fileA_dict[@]}"; do
        if [[ -n ${fileB_dict[$key]+x} ]]; then
            # echo "$key"
            sizeB=$(realSize "$key")
            sizeA=$(realSize "$key" "A")
            # echo "$sizeA" - "$sizeB"
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
            sizeB=$(realSize "$key")
            key_removed="$key REMOVED"
            rate_dict["$key_removed"]=$sizeB
        fi
    done

}

calculate_size_evolution
printHeader
#
#for key in "${!rate_dict[@]}"; do
#    echo "${rate_dict[$key]} $key"
#done

#for key in "${!fileA_dict[@]}"; do
#    echo "${fileA_dict[$key]} $key"
#done

##directory="Teste 2/aula2"
##directory="Teste 2/abc"
#directory="Teste 2"
#
#echo "Nome do diretorio cujo tamanho real quero calcular: $directory"
#echo " "
#size=0;
#for key in "${!fileA_dict[@]}"; do
#
#          echo "${fileA_dict[$key]} $key"
#          if [[ "$key" == "$directory" || ("$key" == "$directory"/* && "$key" != "$directory"/*/*) ]]; then # A chave é um subdiretório direto do diretório pai
#              if [[ "$key" == "$directory" ]]; then # Se for o próprio diretório
#                echo "Eu (key) sou igual ao diretório passado como argumento"
#                echo " "
#                size=$((size + fileA_dict["$key"]))
#              else
#                echo "Eu (key) sou um subdiretorio direto do diretorio passado como argumento."
#                echo ""
#                size=$((size - fileA_dict["$key"]))
#              fi
#          else
#                echo "Não sou o diretorio passado como argumento nem um subdiretorio direto dele."
#                echo ""
#          fi
#
#done
#
#echo "Size real de $directory: $size"

# Função para visualizar a ocupação do espaço como pretendido
display(){
    if [ "$a" -eq 0 ] && [ "$r" -eq 0 ] && [ "$l" -eq 0 ]; then
        for key in "${!rate_dict[@]}"; do
            echo "${rate_dict[$key]} $key"
        done | sort -r -n -k1
    elif [ "$a" -eq 1 ]; then
        if [ "$r" -eq 1 ]; then
            echo "You can only choose one option between -a and -r. Try again!"
        elif [ "$l" -gt 0 ]; then
            for key in "${!rate_dict[@]}"; do
                echo "${rate_dict[$key]} $key"
            done | sort -k2 | head -n $l
        else
            for key in "${!rate_dict[@]}"; do
                echo "${rate_dict[$key]} $key"
            done | sort -k2
        fi
    elif [ "$r" -eq 1 ]; then
        if [ "$l" -gt 0 ]; then
            for key in "${!rate_dict[@]}"; do
                echo "${rate_dict[$key]} $key"
            done | sort -n -k1 | head -n $l
        else
            for key in "${!rate_dict[@]}"; do
                echo "${rate_dict[$key]} $key"
            done | sort -n -k1
        fi
    elif [ "$l" -gt 0 ]; then
        for key in "${!rate_dict[@]}"; do
            echo "${rate_dict[$key]} $key"
        done | sort -r -n -k1 | head -n $l
    fi
}

display