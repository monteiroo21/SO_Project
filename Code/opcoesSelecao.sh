#!/bin/bash

# Cabeçalho
header="$*"

# Opções de Seleção
nome=""
dataMax=$(date)
tamanhoMin=""

# Opções de Visualização
r=0
a=0
l=0

# Dictionary creation
declare -A space_dict

# Dá print ao cabeçalho (função incompleta já vou trabalhar nisso)
printHeader(){
    current_date=$(date +'%Y%m%d')
    printf "%4s %4s %8s %s\n" "SIZE" "NAME" "$current_date" "$*"
}

directory_notFound(){
  echo "ERROR: $1 directory not found!"
  exit 1;
}

printHeader "$header"

# Processa as opções da linha de comando
while getopts ":n:d:s:ral:" opt; do
    case $opt in
        n)
            nome="$OPTARG"
            ;;
        d)
            dataMax="$OPTARG"
            if date -d "$dataMax" "+%d %b %H:%M" > /dev/null 2>&1; then
                continue
            else
                echo "Input a valid date!"
                exit 1;
            fi
            ;;
        s)
            tamanhoMin="$OPTARG"
            if [ "$tamanhoMin" -le 0 ]; then
                echo "You have to give a size greater then zero!"
                exit 1;
            fi
            ;;
        r)
            r=1
            ;;
        a)
            a=1
            ;;
        l)
            l="$OPTARG"
            if [ "$l" -le 0 ]; then
                echo "You have to give a number of lines greater then zero!"
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

# Processamento dos diretórios em baixo

# Verifica se um diretório foi especificado
if [ $# -eq 0 ]; then # verifica se restaram argumentos na linha de comando
    echo "ERRO: Nenhum diretório especificado." >&2
    display_help
fi

# Armazena o diretório de destino
main_directory="$1"

# Função para calcular o tamanho total de um diretório e exibi-lo
calculate_directory_size() {
    local dir="$1"
    local total_size="NA"  # Inicializa com "NA"

    # Diretoria nao existe
    [[ -d "$dir" ]] || directory_notFound "$dir"

    # Verifica se o script tem permissão de leitura para o diretório.
    if [ ! -r "$dir" ]; then
        space_dict["$dir"]="$total_size";
        return
    fi

    local total_size=0 # tem permissão, portanto começa com SIZE 0

    folders=$(find "$dir" -type d 2>/dev/null)  # alterei
    while IFS= read -r df; do
      total_size=0
      if [[ ! -r "$df" ]] || [[ ! -x "$df" ]] ; then
          space_dict["$df"]="NA"
          continue  # Saltar para o próximo diretório se não for acessível
      fi

      files=$(find "$df" -type f 2>/dev/null)  # Redireciona erros para /dev/null
      while IFS= read -r file; do
          if [[ -f "$file" ]] && [[ "$file" =~ $nome ]] && [[ $(date -r "$file" +%s) -le $(date -d "$dataMax" +%s) ]] && [[ $(stat -c %s "$file") -ge "$tamanhoMin" ]]; then
      	    total_size=$((total_size + $(stat -c %s "$file")))
          fi
      done <<< "$files"
      space_dict["$df"]="$total_size";
    done <<< "$folders"

    # a verificação if [ "$dir" != "$main_directory" ] garante que o echo "$total_size" só seja executado quando o diretório atual não for o diretório principal. Dessa forma, o echo não aparecerá na saída final quando o diretório atual for o diretório principal.
    if [ "$dir" != "$main_directory" ]; then
      echo "$total_size"
    fi

}

calculate_directory_size "$main_directory"

# Função para visualizar a ocupação do espaço como pretendido
display(){
    if [ "$a" -eq 0 ] && [ "$r" -eq 0 ] && [ "$l" -eq 0 ]; then
        for key in "${!space_dict[@]}"; do
            echo "${space_dict[$key]} $key"
        done | sort -r -n -k1
    elif [ "$a" -eq 1 ]; then
        if [ "$r" -eq 1 ]; then
            echo "You can only choose one option between -a and -r. Try again!"
        elif [ "$l" -gt 0 ]; then
            for key in "${!space_dict[@]}"; do
                echo "${space_dict[$key]} $key"
            done | sort -k2 | head -n $l
        else
            for key in "${!space_dict[@]}"; do
                echo "${space_dict[$key]} $key"
            done | sort -k2
        fi
    elif [ "$r" -eq 1 ]; then
        if [ "$l" -gt 0 ]; then
            for key in "${!space_dict[@]}"; do
                echo "${space_dict[$key]} $key"
            done | sort -n -k1 | head -n $l
        else
            for key in "${!space_dict[@]}"; do
                echo "${space_dict[$key]} $key"
            done | sort -n -k1
        fi
    elif [ "$l" -gt 0 ]; then
        for key in "${!space_dict[@]}"; do
            echo "${space_dict[$key]} $key"
        done | sort -r -n -k1 | head -n $l
    fi
}

display