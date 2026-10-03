#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "======================================"
echo "    TORIC PRIVATE LAB - TORIC CLOUD   "
echo "        (Nginx + TinyFileManager)     "
echo "======================================"
echo

echo "[1/7] Solicitando acesso aos arquivos..."
termux-setup-storage

echo
echo "Depois de permitir o acesso, pressione ENTER."
read -r

echo
echo "[2/7] Instalando Nginx, PHP, PHP-FPM e utilitários..."
pkg update -y
pkg install nginx php-fpm wget tar procps python -y

echo
echo "[3/7] Baixando e instalando o TinyFileManager..."
WEB_DIR="$HOME/toric-cloud-web"
rm -rf "$WEB_DIR"
mkdir -p "$WEB_DIR"

wget -q -O "$WEB_DIR/index.php" "https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php"

if [ ! -f "$WEB_DIR/index.php" ]; then
    echo "Erro ao baixar o TinyFileManager."
    exit 1
fi

echo "✓ TinyFileManager instalado com sucesso."

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

# Gera o hash da senha via PHP
HASH_PASS=$(php -r "echo password_hash('$PASSWORD', PASSWORD_DEFAULT);")

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
echo "[4/7] Configurando o TinyFileManager (Usuário e Raiz)..."

# Cria o arquivo de configuração personalizada do TinyFileManager
cat << EOF > "$WEB_DIR/config.php"
<?php
// Configurações do Toric Cloud
\$use_auth = true;
\$auth_users = array(
    '$USERNAME' => '$HASH_PASS'
);
// Define a raiz para a pasta de armazenamento mapeada pelo Termux
\$root_path = '/storage';
\$root_url = '';
\$http_host = '\$_SERVER[HTTP_HOST]';
EOF

echo
echo "[5/7] Configurando PHP-FPM e Nginx..."

# Configurar PHP-FPM para rodar via socket ou porta 9000
PHP_FPM_CONF="$PREFIX/etc/php-fpm.d/www.conf"
if [ -f "$PHP_FPM_CONF" ]; then
    sed -i 's|listen = .*|listen = 127.0.0.1:9000|g' "$PHP_FPM_CONF"
fi

# Configurar o Nginx
NGINX_CONF="$PREFIX/etc/nginx/nginx.conf"

cat << EOF > "$NGINX_CONF"
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen $PORT;
        server_name localhost;
        root $WEB_DIR;
        index index.php index.html;

        client_max_body_size 10G;

        location / {
            try_files \$uri \$uri/ /index.php?\$args;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF

echo
echo "[6/7] Criando o comando global 'toric-cloud'..."

cat << EOF > $PREFIX/bin/toric-cloud
#!/data/data/com.termux/files/usr/bin/bash

PORT="$PORT"

case "\$1" in
    start)
        echo "[Toric Cloud] Iniciando serviços (Nginx + PHP-FPM)..."
        termux-wake-lock
        php-fpm >/dev/null 2>&1 || true
        nginx >/dev/null 2>&1 || true
        echo "[Toric Cloud] Servidor iniciado na porta \$PORT."
        ;;
    stop)
        echo "[Toric Cloud] Parando serviços..."
        pkill -f nginx || true
        pkill -f php-fpm || true
        termux-wake-unlock
        echo "[Toric Cloud] Servidor parado."
        ;;
    restart)
        \$0 stop
        sleep 2
        \$0 start
        ;;
    status)
        if pgrep -f "nginx" > /dev/null && pgrep -f "php-fpm" > /dev/null; then
            echo "[Toric Cloud] Status: ONLINE (Nginx + PHP-FPM Rodando)"
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
echo "[7/7] Finalizando e iniciando o servidor..."

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
echo "  toric-cloud start   -> Inicia Nginx + PHP-FPM"
echo "  toric-cloud stop    -> Para Nginx + PHP-FPM"
echo "  toric-cloud restart -> Reinicia os serviços"
echo "  toric-cloud status  -> Mostra o status"
echo
