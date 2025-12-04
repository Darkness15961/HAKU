# Funcionalidad de Persistencia de Cámara del Mapa - HAKU

## Implementación Completada

Se implementó la funcionalidad para guardar y restaurar la posición de la cámara del mapa usando `shared_preferences`.

### Cambios Realizados

#### 1. ViewModel del Mapa (`mapa_vm.dart`)

✅ **Completado** - Se agregaron los siguientes métodos:

```dart
// Importación agregada
import 'package:shared_preferences/shared_preferences.dart';

// Variable para almacenar última posición
CameraPosition? _lastCameraPosition;

// Guardar posición de cámara
Future<void> _guardarPosicionCamara(CameraPosition position) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('map_camera_lat', position.target.latitude);
    await prefs.setDouble('map_camera_lng', position.target.longitude);
    await prefs.setDouble('map_camera_zoom', position.zoom);
    _lastCameraPosition = position;
  } catch (e) {
    print('Error al guardar posición de cámara: $e');
  }
}

// Restaurar posición de cámara
Future<void> _restaurarPosicionCamara() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('map_camera_lat');
    final lng = prefs.getDouble('map_camera_lng');
    final zoom = prefs.getDouble('map_camera_zoom');
    
    if (lat != null && lng != null && zoom != null) {
      final position = CameraPosition(
        target: LatLng(lat, lng),
        zoom: zoom,
      );
      
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(position));
      }
    }
  } catch (e) {
    print('Error al restaurar posición de cámara: $e');
  }
}

// Método público para ser llamado cuando el usuario mueve el mapa
Future<void> onCameraMove(CameraPosition position) async {
  await _guardarPosicionCamara(position);
}
```

**Modificaciones en métodos existentes:**

```dart
// En setNewMapController - Restaurar posición al crear el mapa
void setNewMapController(GoogleMapController controller) {
  if (_mapController.isCompleted) {
    _mapController = Completer();
  }
  _mapController.complete(controller);
  _restaurarPosicionCamara(); // ← AGREGADO
}

// En enfocarMiUbicacion - Guardar posición al centrar en ubicación actual
Future<void> enfocarMiUbicacion() async {
  // ... código existente ...
  final newPosition = CameraPosition(
    target: _currentLocation!,
    zoom: 16,
  );
  await controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  await _guardarPosicionCamara(newPosition); // ← AGREGADO
}
```

#### 2. Vista del Mapa (`mapa_pagina.dart`)

⚠️ **PENDIENTE** - Necesita agregar el callback `onCameraMove`:

```dart
GoogleMap(
  initialCameraPosition: _posicionInicial,
  markers: allMarkers,
  polylines: vmMapa.polylines,
  mapType: vmMapa.currentMapType,
  myLocationEnabled: true,
  myLocationButtonEnabled: false,
  zoomControlsEnabled: false,
  compassEnabled: false,
  
  onMapCreated: (GoogleMapController controller) {
    if (mounted) {
      vmMapa.setNewMapController(controller);
    }
  },
  
  // ← AGREGAR ESTO
  onCameraMove: (CameraPosition position) {
    vmMapa.onCameraMove(position);
  },
),
```

## Cómo Funciona

1. **Al abrir el mapa**: Se restaura automáticamente la última posición guardada
2. **Al mover el mapa**: Se guarda la posición actual en `SharedPreferences`
3. **Al centrar en ubicación**: Se guarda la nueva posición centrada

## Próximos Pasos

1. Agregar manualmente el callback `onCameraMove` en `mapa_pagina.dart` (línea ~148)
2. Probar la funcionalidad:
   - Mover el mapa a una posición
   - Cerrar y volver a abrir la app
   - Verificar que el mapa se centre en la última posición

## Beneficios

- ✅ Mejor experiencia de usuario
- ✅ El mapa "recuerda" dónde estaba el usuario
- ✅ Al activar GPS, se centra automáticamente en la ubicación actual
- ✅ Persistencia entre sesiones de la app
