# 🗄️ Scripts SQL del Backend - Sistema de Solicitudes de Rutas

## 📋 Orden de Ejecución

Ejecuta los scripts en Supabase **en este orden exacto**:

### **1. Crear Tablas** ✅
```
01_crear_tablas.sql
```
Crea las 3 tablas nuevas:
- `solicitudes_rutas`
- `postulaciones_guias`
- `intentos_acceso_ruta`

### **2. Modificar Tablas Existentes** ✅
```
02_modificar_tablas.sql
```
Agrega campos a:
- `rutas` (privacidad y códigos)
- `perfiles` (estadísticas de guías)

### **3. Funciones de Negocio** ✅
```
03_funciones.sql
```
Crea 4 funciones principales:
- `generar_codigo_ruta()`
- `validar_codigo_ruta()`
- `aceptar_postulacion()`
- `cancelar_solicitud()`

### **4. Triggers** ✅
```
04_triggers.sql
```
Crea 4 triggers automáticos:
- Actualizar contadores
- Notificar nueva postulación
- Validar fecha deseada
- Prevenir modificaciones

### **5. Políticas RLS** ✅
```
05_rls_policies.sql
```
Configura seguridad para:
- `solicitudes_rutas` (5 políticas)
- `postulaciones_guias` (4 políticas)
- `intentos_acceso_ruta` (3 políticas)
- `rutas` (actualizada)

### **6. Vistas y Utilidades** ✅
```
06_vistas_utilidades.sql
```
Crea vistas optimizadas y funciones helper:
- `vista_solicitudes_completas`
- `vista_postulaciones_completas`
- `vista_estadisticas_guias`
- `obtener_solicitudes_disponibles()`
- `obtener_mis_solicitudes()`
- `obtener_mis_postulaciones()`

---

## 🚀 Cómo Ejecutar en Supabase

### **Opción 1: SQL Editor (Recomendado)**

1. Abre tu proyecto en Supabase
2. Ve a **SQL Editor**
3. Crea una nueva query
4. Copia y pega el contenido de `01_crear_tablas.sql`
5. Haz clic en **Run**
6. Repite para cada archivo en orden

### **Opción 2: Desde la Terminal**

Si tienes Supabase CLI instalado:

```bash
# Navegar a la carpeta
cd c:\Users\PC\develop\app_movil\backend_sql

# Ejecutar cada script
supabase db execute --file 01_crear_tablas.sql
supabase db execute --file 02_modificar_tablas.sql
supabase db execute --file 03_funciones.sql
supabase db execute --file 04_triggers.sql
supabase db execute --file 05_rls_policies.sql
supabase db execute --file 06_vistas_utilidades.sql
```

---

## ✅ Verificación

Después de ejecutar todos los scripts, verifica:

### **Tablas Creadas**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('solicitudes_rutas', 'postulaciones_guias', 'intentos_acceso_ruta');
```

### **Funciones Creadas**
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
  'generar_codigo_ruta',
  'validar_codigo_ruta',
  'aceptar_postulacion',
  'cancelar_solicitud'
);
```

### **Triggers Creados**
```sql
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name LIKE '%postulacion%' OR trigger_name LIKE '%solicitud%';
```

### **Políticas RLS**
```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('solicitudes_rutas', 'postulaciones_guias', 'intentos_acceso_ruta');
```

---

## 🧪 Testing Rápido

### **Test 1: Generar Código**
```sql
SELECT generar_codigo_ruta();
-- Debería retornar algo como: HAKU-2024-A7B3
```

### **Test 2: Crear Solicitud (desde tu app)**
```dart
// Esto lo harás desde Flutter, pero el SQL sería:
INSERT INTO solicitudes_rutas (
  turista_id, titulo, descripcion, lugares_ids, 
  fecha_deseada, numero_personas
) VALUES (
  'tu-uuid-aqui',
  'Test Tour',
  'Descripción de prueba',
  ARRAY[1, 2, 3],
  now() + interval '3 days',
  2
);
```

### **Test 3: Validar Código**
```sql
-- Primero crea una ruta privada manualmente o acepta una postulación
-- Luego prueba:
SELECT validar_codigo_ruta(1, 'HAKU-2024-XXXX', 'tu-uuid');
-- Debería retornar true o false
```

---

## 📊 Estructura Creada

```
Base de Datos
├── Tablas (3 nuevas)
│   ├── solicitudes_rutas
│   ├── postulaciones_guias
│   └── intentos_acceso_ruta
│
├── Modificaciones (2 tablas)
│   ├── rutas (+ campos privacidad)
│   └── perfiles (+ estadísticas)
│
├── Funciones (4)
│   ├── generar_codigo_ruta()
│   ├── validar_codigo_ruta()
│   ├── aceptar_postulacion()
│   └── cancelar_solicitud()
│
├── Triggers (4)
│   ├── actualizar_contador_postulaciones
│   ├── notificar_nueva_postulacion
│   ├── validar_fecha_deseada
│   └── prevenir_modificacion_solicitud_asignada
│
├── Políticas RLS (12)
│   ├── solicitudes_rutas (5)
│   ├── postulaciones_guias (4)
│   └── intentos_acceso_ruta (3)
│
└── Vistas (3) + Funciones Helper (3)
    ├── vista_solicitudes_completas
    ├── vista_postulaciones_completas
    ├── vista_estadisticas_guias
    ├── obtener_solicitudes_disponibles()
    ├── obtener_mis_solicitudes()
    └── obtener_mis_postulaciones()
```

---

## 🔒 Seguridad Implementada

✅ **RLS habilitado** en todas las tablas  
✅ **Validación de DNI** para crear solicitudes  
✅ **Solo guías certificados** pueden postular  
✅ **Turistas solo ven sus datos**  
✅ **Guías solo ven solicitudes activas**  
✅ **Registro de intentos** de acceso  
✅ **Validación de 24h** para cancelar  
✅ **Prevención de modificaciones** no autorizadas  

---

## 📝 Notas Importantes

1. **Orden de ejecución**: Es crítico ejecutar en el orden indicado
2. **Backups**: Haz backup antes de ejecutar en producción
3. **Testing**: Prueba primero en un proyecto de desarrollo
4. **Permisos**: Asegúrate de tener permisos de admin en Supabase
5. **Errores**: Si hay errores, revisa los mensajes y ajusta según tu schema

---

## 🆘 Solución de Problemas

### **Error: "relation already exists"**
```sql
-- Elimina la tabla y vuelve a crearla
DROP TABLE IF EXISTS nombre_tabla CASCADE;
-- Luego ejecuta el script nuevamente
```

### **Error: "function already exists"**
```sql
-- Reemplaza la función
CREATE OR REPLACE FUNCTION nombre_funcion...
```

### **Error: "policy already exists"**
```sql
-- Elimina la política primero
DROP POLICY IF EXISTS "nombre_politica" ON tabla;
-- Luego ejecuta el script nuevamente
```

---

## ✅ Checklist de Implementación

- [ ] Ejecutar `01_crear_tablas.sql`
- [ ] Ejecutar `02_modificar_tablas.sql`
- [ ] Ejecutar `03_funciones.sql`
- [ ] Ejecutar `04_triggers.sql`
- [ ] Ejecutar `05_rls_policies.sql`
- [ ] Ejecutar `06_vistas_utilidades.sql`
- [ ] Verificar tablas creadas
- [ ] Verificar funciones creadas
- [ ] Verificar triggers activos
- [ ] Verificar políticas RLS
- [ ] Probar generar código
- [ ] Probar crear solicitud de prueba
- [ ] Probar validar código

---

**¡Backend listo para usar!** 🎉

Ahora puedes continuar con el desarrollo del frontend en Flutter.
