#!/bin/bash
# Indica que o script deve ser interpretado usando o Bash.

# Cabeçalho
header="$*" # variável especial que representa como uma única string todos os argumentos passados para o script na linha de comando.

# Opções de Seleção
nome=""
dataMax=$(date)
tamanhoMin=""

# Opções de Visualização
r=0
a=0
l=0

# Criar o dicionário que vai ser usado para guardar o size associado a cada diretório.
declare -A space_dict

# Esta função é chamada quando nenhum diretório foi especificado. Explica ao utilizador como interagir com o script.
display_help() {
    echo "Usage: $0 [options] directory"
    echo "Options:"
    echo "  -n pattern   Specify a pattern for file names (e.g., '.*sh', '.*pdf', '.*png')"
    echo "  -d date      Specify a maximum date for file modification (format: 'YYYYMMDD')"
    echo "  -s size      Specify a minimum size for files (in bytes)"
    echo "  -r           Sort the output in reverse order"
    echo "  -a           Sort the output by name"
    echo "  -l lines     Limit the number of lines in the table"
    exit 1
}

# Dá print ao cabeçalho
printHeader(){
    current_date=$(date +'%Y%m%d')
    printf "%4s %4s %8s %s\n" "SIZE" "NAME" "$current_date" "$*"
}

directory_notFound(){
  echo "ERROR: $1 directory not found!"
  exit 1; # encerra o script
}

printHeader "$header"

# Processa as opções da linha de comando
while getopts ":n:d:s:ral:" opt; do
    case $opt in # trata cada opção fornecida na linha de comando
        n)
            nome="$OPTARG"
            if [[ ! "$nome" =~ ^\.\*[^/]+$ ]]; then # expressão regular para verificar se a variável nome está no formato desejado
                    echo "Invalid pattern for -n. It should be in the format '.*sh', '.*pdf', '.*png', etc."
                    exit 1
            fi
            ;;
        d)
            dataMax="$OPTARG"
            if date -d "$dataMax" "+%d %b %H:%M" > /dev/null 2>&1; then
                continue # Se for válida, o script continua para a próxima iteração do loop
            else
                echo "Input a valid date!"
                exit 1; # Encerra o script com código de erro 1
            fi
            ;;
        s)
            tamanhoMin="$OPTARG"
            if ! [[ "$tamanhoMin" =~ ^[0-9]+$ ]]; then
                echo "You have to give a size greater or equal than zero (an integer)!"
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
            if ! [[ "$l" =~ ^[1-9]+$ ]]; then
                echo "You have to give a number of lines greater than zero (an integer)!"
                exit 1;
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done


# Remove as opções processadas da linha de comando. Agora, os argumentos restantes em "$@" são os diretórios a serem processados
shift $((OPTIND-1))

# Verifica se pelo menos 1 diretório foi especificado
if [ $# -eq 0 ]; then # verifica se restaram argumentos na linha de comando
    echo "ERRO: Nenhum diretório especificado." >&2
    display_help
fi

# Armazena o diretório de destino
main_directories=("$@")

# Função para calcular o tamanho total de um diretório e exibi-lo
calculate_directory_size() {
    local dir="$1"
    local total_size="NA"  # Inicializa com "NA"

    # Diretoria nao existe
    [[ -d "$dir" ]] || directory_notFound "$dir"

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
}



# calculate_directory_size "$main_directory"

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


for directory in "${main_directories[@]}"; do
    # echo "Processando o diretório: $directory"

    calculate_directory_size "$directory"
done

display
