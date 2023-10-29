#!/bin/bash

nome=""
dataMax=""
tamanhoMin=""
processed_directories=()

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

# Função para calcular o tamanho total de um diretório e exibi-lo
calculate_directory_size() {
    local dir="$1"
    local total_size=0

    # Verifica se o diretório já foi processado
    if [[ " ${processed_directories[@]} " =~ " $dir " ]]; then
        return
    fi

    # Registra o diretório como processado
    processed_directories+=("$dir")

    for file in "$dir"/*; do
        if [[ -f "$file" && "$file" =~ $nome && $(date -r "$file" +%s) -le $(date -d "$dataMax" +%s) && $(stat -c %s "$file") -ge "$tamanhoMin" ]]; then
            total_size=$((total_size + $(stat -c %s "$file")))
        fi
    done

    echo "$total_size $dir"

    # Verifica se o diretório tem subdiretórios. Se tiver chamar recursivamente esta funçao 
    for sub_directory in "$dir"/*; do
        if [[ -d "$sub_directory" ]]; then
            calculate_directory_size "$sub_directory"
        fi
    done
}

calculate_directory_size "$main_directory"


