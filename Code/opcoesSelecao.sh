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


# Verifica se a data é válida
dateIsValid(){
    local input_date="$1";
    if date -d "$input_date" "+%d %b %H:%M" > /dev/null 2>&1; then
        return 0;
    else
        return 1;
    fi
}

# Verifica se o tamanho é superior a zero
sizeIsValid(){
    local tamanhoMin="$1";
    if [ "$tamanhoMin" -gt 0 ]; then
        return 0;
    else 
        return 1;
    fi
}

# Dá print ao cabeçalho (função incompleta já vou trabalhar nisso)
printHeader(){
    current_date=$(date +'%Y%m%d')
    printf "%4s %4s %8s %s\n" "SIZE" "NAME" "$current_date" "$*"
}

directory_notFound(){
  echo "ERROR: $1 directory not found!"
  exit 1;
}

sort -n -r dados.txt > dadosbydefault.txt
printHeader "$header"

# Processa as opções da linha de comando
while getopts ":n:d:s:ral:" opt; do
    case $opt in
        n)
            nome="$OPTARG"
            ;;
        d)
            dataMax="$OPTARG"
            if [[ $(dateIsValid $dataMax) -eq 1 ]]; then
                echo "Insert a valid date"
                exit 1;
            fi
            ;;
        s)
            tamanhoMin="$OPTARG"
            if [[ $(sizeIsValid $tamanhoMin) -eq 1 ]]; then
                echo "Insert a valid size"
                exit 1;
            fi
            ;;
        r)
            r=1
            if [ "$l" -gt 0 ]; then
                sort -n dados.txt > reversedados.txt
                head -n "$l" reversedados.txt
            else
                sort -n dados.txt > reversedados.txt
                while read line; do
                    echo $line
                done < reversedados.txt
            fi
            ;;
        a)
            a=1
            if [ "$r" -eq 1 ]; then
                echo "You can only choose one option between -a and -r. Try again"
            elif [ "$l" -gt 0 ]; then
                sort -k2 dados.txt > dadosbyname.txt
                head -n "$l" dadosbyname.txt
            else
                sort -k2 dados.txt > dadosbyname.txt
                while read line; do
                    echo $line
                done < dadosbyname.txt
            fi
            ;;
        l)
            l="$OPTARG"
            if [[ $(sizeIsValid $l) -eq 1 ]]; then
                echo "Insert a valid number of lines"
                exit 1;
            fi
            head -n "$l" dadosbydefault.txt
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

if [ "$a" -eq 0 ] && [ "$r" -eq 0 ] && [ "$l" -eq 0 ]; then
    while read line; do
        echo $line
    done < dadosbydefault.txt
fi

# Remove as opções processadas da linha de comando
shift $((OPTIND-1))

# Agora, os argumentos remanescentes em "$@" são os diretórios a serem processados

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

# Função para calcular o tamanho total de um diretório e exibi-lo
calculate_directory_size() {
    local dir="$1"
    local total_size="NA"  # Inicializa com "NA"

    # Diretoria nao existe
    [[ -d "$dir" ]] || directory_notFound "$dir"

    # Verifica se o script tem permissão de leitura para o diretório.
    if [ ! -r "$dir" ]; then
        echo "$total_size $dir" >> dados.txt # exibir "NA" em vez de "0" pois defini em cima >> local total_size="NA"
        return
    fi

    local total_size=0 # tem permissão, portanto começa com SIZE 0


    folders=$(find "$dir" -type d)

    while IFS= read -r df; do
      total_size=0
      files=$(find "$df" -type f)
      while IFS= read -r file; do
          if [[ -f "$file" ]] && [[ "$file" =~ $nome ]] && [[ $(date -r "$file" +%s) -le $(date -d "$dataMax" +%s) ]] && [[ $(stat -c %s "$file") -ge "$tamanhoMin" ]]; then
      	    total_size=$((total_size + $(stat -c %s "$file")))
          fi
      done <<< "$files"
      echo "$total_size $df" >> dados.txt
    done <<< "$folders"



    # a verificação if [ "$dir" != "$main_directory" ] garante que o echo "$total_size" só seja executado quando o diretório atual não for o diretório principal. Dessa forma, o echo não aparecerá na saída final quando o diretório atual for o diretório principal.
    if [ "$dir" != "$main_directory" ]; then
      echo "$total_size"
    fi

}

calculate_directory_size "$main_directory"