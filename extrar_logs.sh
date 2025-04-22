#!/bin/bash

# Uso: ./extraer_logs.sh archivo_origen.log fecha_inicio fecha_fin archivo_salida.log
# Ejemplo: ./extraer_logs.sh odoo.log "2025-04-22 19:52:45" "2025-04-22 19:52:51" salida.log

archivo_origen=$1
fecha_inicio=$2
fecha_fin=$3
archivo_salida=$4

# Convertir fechas a formato timestamp para comparación
ts_inicio=$(date -d "$fecha_inicio" +%s)
ts_fin=$(date -d "$fecha_fin" +%s)

# Procesar el archivo de log
awk -v ts_start="$ts_inicio" -v ts_end="$ts_fin" '
{
    # Extraer fecha y hora del log (formato: YYYY-MM-DD HH:MM:SS)
    if (match($0, /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
        fecha_hora = substr($0, RSTART, RLENGTH);
        # Convertir a timestamp
        cmd = "date -d \"" fecha_hora "\" +%s 2>/dev/null";
        cmd | getline ts_linea;
        close(cmd);
        
        # Si el timestamp está en el rango, imprimir la línea
        if (ts_linea >= ts_start && ts_linea <= ts_end) {
            print $0;
        }
    } else if (match($0, /\[[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}\]/)) {
        # Para líneas que solo tienen fecha en formato [DD/Mon/YYYY HH:MM:SS]
        fecha_formato_we = substr($0, RSTART+1, RLENGTH-2);
        # Convertir formato [22/Apr/2025 19:52:42] a 2025-04-22 19:52:42
        cmd = "date -d \"" fecha_formato_we "\" \"+%Y-%m-%d %H:%M:%S\" 2>/dev/null";
        cmd | getline fecha_normalizada;
        close(cmd);
        
        # Convertir a timestamp
        cmd = "date -d \"" fecha_normalizada "\" +%s 2>/dev/null";
        cmd | getline ts_linea;
        close(cmd);
        
        # Si el timestamp está en el rango, imprimir la línea
        if (ts_linea >= ts_start && ts_linea <= ts_end) {
            print $0;
        }
    }
}' "$archivo_origen" > "$archivo_salida"

echo "Extracción completada. Resultados guardados en $archivo_salida"
