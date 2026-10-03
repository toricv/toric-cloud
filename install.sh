#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "======================================"
echo "    TORIC PRIVATE LAB - TORIC CLOUD   "
echo "              (Copyparty)             "
echo "======================================"
echo

echo "[1/6] Solicitando acesso aos arquivos..."
termux-setup-storage

echo
echo "Depois de permitir o acesso, pressione ENTER."
read -r

echo
echo "[2/6] Instalando Python, Pip e utilitários..."
pkg update -y
pkg install python python-pip procps wget -y

echo
echo "[3/6] Instalando Copyparty..."
pip install copyparty jinja2 --break-system-packages

if ! command -v copyparty >/dev/null 2>&1; then
    echo "Erro ao instalar o Copyparty."
    exit 1
fi

echo "✓ Copyparty instalado com sucesso."

echo
echo "======================================"
echo "       CRIAR LOGIN DO SERVIDOR"
echo "======================================"
echo

while true; do
    read -rp "Digite o nome de usuário: " USERNAME
    if [ -n "$USERNAME" ]; then break; fi
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
    if [ "$PASSWORD" = "$PASSWORD2" ]; then break; fi
    echo "As senhas não coincidem."
    echo
done

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
echo "[4/6] Configurando o arquivo copyparty.conf..."

CONF_DIR="$HOME/.copyparty"
mkdir -p "$CONF_DIR"

# Gera o arquivo de configuração oficial do Copyparty sem flags booleanas com parâmetro
cat << EOF > "$CONF_DIR/copyparty.conf"
[global]
  p: $PORT
  e2d

[accounts]
  $USERNAME: $PASSWORD

[/]
  /storage/emulated/0
  acc: A
  rwa: $USERNAME

EOF

# Adiciona volumes para cada armazenamento USB externo detectado em /storage
for dev in /storage/*; do
    if [ -d "$dev" ] && [ "$dev" != "/storage/emulated" ] && [ "$dev" != "/storage/self" ]; then
        DEV_NAME=$(basename "$dev")
        cat << EOF >> "$CONF_DIR/copyparty.conf"
[/USB_$DEV_NAME]
  $dev
  acc: A
  rwa: $USERNAME

EOF
    fi
done

echo
echo "[5/6] Criando o comando global 'toric-cloud'..."

cat << EOF > $PREFIX/bin/toric-cloud
#!/data/data/com.termux/files/usr/bin/bash

PORT="$PORT"
CONF_DIR="\$HOME/.copyparty"

case "\$1" in
    start)
        if pgrep -f "copyparty" > /dev/null; then
            echo "[Toric Cloud] O servidor já está rodando!"
        else
            echo "[Toric Cloud] Iniciando o Copyparty..."
            termux-wake-lock
            nohup copyparty -c "\$CONF_DIR/copyparty.conf" > "\$CONF_DIR/copyparty.log" 2>&1 &
            sleep 2
            if pgrep -f "copyparty" > /dev/null; then
                echo "[Toric Cloud] Servidor iniciado na porta \$PORT."
            else
                echo "[Toric Cloud] Erro ao iniciar. Verifique o log com: cat \$CONF_DIR/copyparty.log"
            fi
        fi
        ;;
    stop)
        echo "[Toric Cloud] Parando o Copyparty..."
        pkill -f "copyparty" || true
        termux-wake-unlock
        echo "[Toric Cloud] Servidor parado."
        ;;
    restart)
        \$0 stop
        sleep 2
        \$0 start
        ;;
    status)
        if pgrep -f "copyparty" > /dev/null; then
            echo "[Toric Cloud] Status: ONLINE (Copyparty Rodando)"
        else
            echo "[Toric Cloud] Status: OFFLINE"
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
echo "[6/6] Finalizando e iniciando o servidor..."

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

toric-cloud start

echo
echo "======================================"
echo "       INSTALAÇÃO CONCLUÍDA!"
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
echo "Comandos de controle:"
echo "  toric-cloud start   -> Inicia o servidor"
echo "  toric-cloud stop    -> Para o servidor"
echo "  toric-cloud restart -> Reinicia o servidor"
echo "  toric-cloud status  -> Mostra o status"
echo
