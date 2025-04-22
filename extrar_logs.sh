#!/bin/bash

# Uso: ./extraer_logs.sh archivo.log "fecha_inicio" "fecha_fin" salida.log
# Ejemplo: ./extraer_logs.sh odoo.log "2025-04-22 19:52:45" "2025-04-22 19:52:51" resultado.log

archivo_origen="$1"
fecha_inicio="$2"
fecha_fin="$3"
archivo_salida="$4"

# Convertir fechas a timestamp
ts_inicio=$(date -d "$fecha_inicio" +%s)
ts_fin=$(date -d "$fecha_fin" +%s)

# Procesamiento optimizado desde el final
tac "$archivo_origen" | awk -v ts_start="$ts_inicio" -v ts_end="$ts_fin" '
BEGIN {
    # Mapeo de meses
    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", meses)
    for (i=1; i<=12; i++) mes[meses[i]] = i
}

{
    ts = -1
    # Parsear formato estándar Odoo (2025-04-22 19:52:45,752)
    if (match($0, /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})/, m)) {
        ts = mktime(m[1] " " m[2] " " m[3] " " m[4] " " m[5] " " m[6])
    }
    # Parsear formato Werkzeug [22/Apr/2025 19:52:42]
    else if (match($0, /\[([0-9]{2})\/([A-Za-z]{3})\/([0-9]{4}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\]/, m)) {
        ts = mktime(m[3] " " mes[m[2]] " " m[1] " " m[4] " " m[5] " " m[6])
    }
    
    if (ts == -1) next  # Ignorar líneas sin fecha
    
    if (ts > ts_end) next  # Saltar registros posteriores al rango
    
    if (ts < ts_start) exit  # Salir al encontrar registro anterior al rango
    
    print  # Capturar línea dentro del rango
}' | tac > "$archivo_salida"

echo "Procesamiento completado. Registros guardados en: $archivo_salida"
