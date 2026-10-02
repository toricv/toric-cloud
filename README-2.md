# 🪐 Toric Cloud — Toric Private Lab

O **Toric Cloud** é o módulo de armazenamento e nuvem privada do ecossistema **Toric Private Lab**, rodando sobre o Samsung Galaxy Z Flip 7 via Termux.

---

## 🚀 Funcionalidades

- **Suporte ao Hub USB-C:** Mapeamento na raiz (`/`), permitindo gerenciar pendrives, SSDs SATA e M.2 NVMe montados em `/storage/`.
- **Instalação Interativa:** Permite escolher usuário, validar senha (mínimo de 12 caracteres) e definir a porta HTTP (padrão `8080` ou personalizada).
- **Comando Global `toric-cloud`:** Utilitário para controle do serviço via terminal (`start`, `stop`, `restart`, `status`).
- **Autostart:** Suporte a inicialização automática no boot via aplicativo Termux:Boot.

---

## 🛠️ Passo a Passo de Instalação no Android

### 1. Preparar o Termux

Baixe o **Termux** via [F-Droid](https://f-droid.org/packages/com.termux/). Abra o aplicativo e execute:

```bash
pkg update && pkg upgrade -y
pkg install git -y