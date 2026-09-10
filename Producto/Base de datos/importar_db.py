import json
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import sys

# 1. Configura tu archivo de credenciales de Firebase
# Descárgalo desde: Configuración del proyecto > Cuentas de servicio > Generar nueva clave privada
CREDENTIAL_FILE = 'serviceAccountKey.json'
JSON_FILE = 'EXPORTACION_BASE_DE_DATOS.json'

def main():
    print("Iniciando importación a Firestore...")
    
    try:
        cred = credentials.Certificate(CREDENTIAL_FILE)
        firebase_admin.initialize_app(cred)
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo '{CREDENTIAL_FILE}'.")
        print("Debes descargarlo desde Firebase Console y colocarlo en esta misma carpeta.")
        sys.exit(1)
        
    db = firestore.client()
    
    try:
        with open(JSON_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo '{JSON_FILE}'.")
        sys.exit(1)

    # Importar los pórticos
    porticos = data.get('porticos', {})
    if not porticos:
        print("No se encontraron pórticos en el archivo JSON.")
        sys.exit(1)
        
    print(f"Se encontraron {len(porticos)} pórticos para importar. Procesando...")
    
    batch = db.batch()
    count = 0
    
    for portico_id, portico_data in porticos.items():
        datos = portico_data.get('datos', {})
        
        # Mapeamos los datos al formato que espera tu app en Flutter
        # Según el modelo portico_model.dart, necesita 'nombre', 'ubicacion' (GeoPoint), y 'nombre_autopista'
        
        doc_ref = db.collection('porticos').document(portico_id)
        
        # Obtenemos latitud y longitud, y lo convertimos a GeoPoint para Firestore
        lat = datos.get('latitud', 0.0)
        lng = datos.get('longitud', 0.0)
        
        # Preparamos el documento a guardar
        doc_data = {
            'nombre': datos.get('nombre', ''),
            'nombre_autopista': datos.get('autopista', ''),
            'ubicacion': firestore.GeoPoint(lat, lng),
            # Guardamos los demás campos por si se usan en el futuro o para compatibilidad con la documentación
            'tarifa_base': datos.get('tarifa_base', 0.0),
            'tarifa_punta': datos.get('tarifa_punta', 0.0),
            'tarifa_saturacion': datos.get('tarifa_saturacion', 0.0),
            'sentido': datos.get('sentido', ''),
            'grupo': datos.get('grupo', ''),
            'secuencia': datos.get('secuencia', 0)
        }
        
        batch.set(doc_ref, doc_data)
        count += 1
        
        # Firestore permite un máximo de 500 operaciones por batch
        if count % 400 == 0:
            batch.commit()
            print(f"Importados {count} pórticos...")
            # Reiniciar batch
            batch = db.batch()
            
    # Hacer commit de los que quedaron pendientes
    if count % 400 != 0:
        batch.commit()
        
    print(f"¡Éxito! Se importaron {count} pórticos correctamente a Firebase.")

if __name__ == '__main__':
    main()
