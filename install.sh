#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "======================================"
echo "    TORIC PRIVATE LAB - TORIC CLOUD   "
echo "======================================"
echo

echo "[1/7] Solicitando acesso aos arquivos..."
termux-setup-storage

echo
echo "Depois de permitir o acesso, pressione ENTER."
read -r

echo
echo "[2/7] Instalando dependências..."
echo
echo "Esta etapa pode demorar um pouco."
echo "O Python será instalado para detectar"
echo "automaticamente o IP do celular."
echo
echo "[  0%] Preparando instalação..."
sleep 1

echo
echo "[ 25%] Instalando wget, tar, procps e Python..."
echo "Aguarde até a conclusão..."
echo

pkg install wget tar procps python -y

echo
echo "[ 75%] Verificando instalação..."

if ! command -v python >/dev/null 2>&1; then
    echo
    echo "Não foi possível instalar o Python."
    exit 1
fi

echo "Python instalado com sucesso."

echo
echo "[100%] Dependências instaladas!"
echo

echo "[3/7] Detectando arquitetura..."

ARCH=$(uname -m)

case "$ARCH" in
    aarch64)
        FILE="linux-arm64-filebrowser.tar.gz"
        echo "✓ ARM64 detectado (aarch64)"
        ;;
    x86_64)
        FILE="linux-amd64-filebrowser.tar.gz"
        echo "✓ AMD64 detectado (x86_64)"
        ;;
    i686|x86)
        FILE="linux-386-filebrowser.tar.gz"
        echo "✓ x86 32-bit detectado"
        ;;
    armv7l|arm)
        FILE="linux-armv5-filebrowser.tar.gz"
        echo "✓ ARM 32-bit detectado"
        echo "Usando a build ARMv5."
        ;;
    *)
        echo
        echo "Arquitetura não suportada: $ARCH"
        exit 1
        ;;
esac

echo
echo "[4/7] Baixando File Browser..."

cd "$HOME"
rm -f "$FILE"

wget -q --show-progress \
"https://github.com/filebrowser/filebrowser/releases/latest/download/$FILE"

echo
echo "Extraindo File Browser..."
tar -xzf "$FILE"

echo "Instalando File Browser..."
mv -f filebrowser "$PREFIX/bin/filebrowser"
chmod +x "$PREFIX/bin/filebrowser"
rm -f "$FILE"

echo
echo "✓ File Browser instalado!"

if ! command -v filebrowser >/dev/null 2>&1; then
    echo "Não foi possível encontrar o File Browser."
    exit 1
fi

echo
filebrowser version

echo
echo "[5/7] Configurando o banco de dados..."

mkdir -p "$HOME/.filebrowser"
DB="$HOME/.filebrowser/filebrowser.db"

if [ ! -f "$DB" ]; then
    filebrowser -d "$DB" config init
fi

echo
echo "======================================"
echo "       CRIAR LOGIN DO SERVIDOR"
echo "======================================"
echo

while true; do
    read -rp "Digite o nome de usuário: " USERNAME

    if [ -n "$USERNAME" ]; then
        break
    fi

    echo "O usuário não pode ficar vazio."
done

while true; do
    read -rsp "Digite sua senha: " PASSWORD
    echo

    if [ -z "$PASSWORD" ]; then
        echo "A senha não pode ficar vazia."
        echo
        continue
    fi

    if [[ ${#PASSWORD} -lt 12 ]]; then
        echo "A senha precisa ter no mínimo 12 caracteres."
        echo
        continue
    fi

    read -rsp "Digite a senha novamente: " PASSWORD2
    echo

    if [ "$PASSWORD" = "$PASSWORD2" ]; then
        break
    fi

    echo "As senhas não coincidem."
    echo
done

# Adiciona usuário administrador
filebrowser -d "$DB" users add "$USERNAME" "$PASSWORD" --perm.admin

echo
echo "======================================"
echo "       CONFIGURAÇÃO DA PORTA"
echo "======================================"
echo

echo "A porta padrão é 8080."
echo "Pressione ENTER para usar 8080."
echo

while true; do
    read -rp "Digite a porta [8080]: " PORT

    PORT=${PORT:-8080}

    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "Digite apenas números."
        continue
    fi

    if [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
        echo "Escolha uma porta entre 1024 e 65535."
        continue
    fi

    break
done

echo
echo "✓ Porta escolhida: $PORT"

echo
echo "[6/7] Configurando a raiz do sistema (Hub USB-C)..."
# Define a raiz em / para permitir navegar até os drives USB externos em /storage
filebrowser -d "$DB" config set -a 0.0.0.0 -p "$PORT" -r "/" >/dev/null 2>&1

echo
echo "[7/7] Criando o comando global 'toric-cloud'..."

cat << EOF > $PREFIX/bin/toric-cloud
#!/data/data/com.termux/files/usr/bin/bash

PORT="$PORT"
ROOT_DIR="/"
DB_PATH="\$HOME/.filebrowser/filebrowser.db"
LOG_PATH="\$HOME/.filebrowser/filebrowser.log"

case "\$1" in
    start)
        if pgrep -x "filebrowser" > /dev/null; then
            echo "[Toric Cloud] O servidor já está rodando!"
        else
            echo "[Toric Cloud] Iniciando o servidor..."
            termux-wake-lock
            nohup filebrowser -a 0.0.0.0 -p \$PORT -r \$ROOT_DIR -d \$DB_PATH > \$LOG_PATH 2>&1 &
            sleep 2
            if pgrep -x "filebrowser" > /dev/null; then
                echo "[Toric Cloud] Servidor iniciado na porta \$PORT."
            else
                echo "[Toric Cloud] Erro ao iniciar o servidor. Verifique o log em \$LOG_PATH"
            fi
        fi
        ;;
    stop)
        echo "[Toric Cloud] Parando o servidor..."
        pkill -x filebrowser || true
        termux-wake-unlock
        echo "[Toric Cloud] Servidor parado."
        ;;
    restart)
        \$0 stop
        sleep 2
        \$0 start
        ;;
    status)
        if pgrep -x "filebrowser" > /dev/null; then
            echo "[Toric Cloud] Status: ONLINE (Rodando)"
        else
            echo "[Toric Cloud] Status: OFFLINE (Parado)"
        fi
        ;;
    *)
        echo "Uso: toric-cloud {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

chmod +x $PREFIX/bin/toric-cloud

echo
echo "======================================"
echo "       INSTALAÇÃO CONCLUÍDA!"
echo "======================================"
echo

IP=$(python -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.connect(('8.8.8.8', 80))
    print(s.getsockname()[0])
except Exception:
    print('')
finally:
    s.close()
" 2>/dev/null)

echo "Iniciando Toric Cloud..."
toric-cloud start

echo
echo "======================================"
echo "       SERVIDOR INICIADO!"
echo "======================================"
echo "Acesse pelo navegador:"
if [ -n "$IP" ]; then
    echo "   http://$IP:$PORT"
else
    echo "   http://<IP-DO-CELULAR>:$PORT"
fi
echo
echo "Usuário: $USERNAME"
echo
echo "Comandos disponíveis no terminal:"
echo "  toric-cloud start   -> Inicia o servidor"
echo "  toric-cloud stop    -> Para o servidor"
echo "  toric-cloud restart -> Reinicia o servidor"
echo "  toric-cloud status  -> Mostra o status"
echo