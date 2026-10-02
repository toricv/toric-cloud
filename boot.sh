#!/data/data/com.termux/files/usr/bin/bash

# Previne suspensão da CPU pelo Android
termux-wake-lock

# Aguarda serviços de rede
sleep 10

# Inicia o Toric Cloud
$PREFIX/bin/toric-cloud start