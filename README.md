# 🪐 Toric Cloud — Toric Private Lab

O **Toric Cloud** é o módulo de armazenamento e private cloud do projeto **Toric Private Lab**. Ele transforma o Samsung Galaxy Z Flip 7 (ou qualquer smartphone Android via Termux) em uma nuvem privada robusta, acessível localmente e preparada para acesso remoto.

## 🚀 Funcionalidades

- **Gerenciamento de Arquivos Completo:** Interface moderna, rápida, responsiva e sem anúncios (FileBrowser).
- **Suporte a Armazenamento Externo:** Acesso total a pendrives, SSDs SATA e NVMe conectados ao Hub USB-C.
- **Controle por Terminal:** Comandos dedicados (`toric-cloud start|stop|restart|status`).
- **Autostart:** Integração com Termux:Boot para iniciar automaticamente ao ligar o aparelho.
- **Segurança:** Autenticação por usuário e senha com permissões granulares.

---

## 🛠️ Passo a Passo de Instalação

### 1. Preparação
1. Instale o **Termux** a partir do [F-Droid](https://f-droid.org/packages/com.termux/).
2. (Opcional) Instale o aplicativo **Termux:Boot** para autostart ao ligar o celular.

### 2. Executar o Instalador

Abra o Termux e digite os comandos abaixo:

```bash
pkg update && pkg upgrade -y
pkg install git -y
git clone https://github.com/toricv/toric-cloud.git
cd toric-cloud
bash install.sh
```

---

## 🎮 Gerenciamento do Servidor

Você pode controlar o serviço a qualquer momento pelo terminal do Termux:

- **Iniciar:** `toric-cloud start`
- **Parar:** `toric-cloud stop`
- **Reiniciar:** `toric-cloud restart`
- **Ver Status:** `toric-cloud status`

---

## 📱 Acesso aos Arquivos do Hub USB-C

Após fazer login na interface web (`http://IP-DO-CELULAR:8080`), navegue até o diretório:
- `storage/` ou `/storage/XXXX-XXXX`

Ali estarão listados todos os volumes e SSDs conectados ao Hub ES-TA08.

---

## 🔄 Configurar Inicialização Automática (Boot)

Para que o servidor inicie automaticamente quando o celular for ligado:

```bash
mkdir -p ~/.termux/boot/
cp boot.sh ~/.termux/boot/start-toric.sh
chmod +x ~/.termux/boot/start-toric.sh
```

> **Nota para Samsung One UI:** Vá em *Configurações -> Assistência do Aparelho -> Bateria -> Limites de uso em segundo plano* e adicione o Termux em **"Aplicativos que nunca entram em suspensão"**.
