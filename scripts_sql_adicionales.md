# Scripts SQL Adicionales para HAKU

## Funciones RPC para Gestión de Inscritos

Estas funciones son necesarias para el repositorio de Rutas. Ejecuta estos scripts en el **SQL Editor** de Supabase:

### 1. Función para Incrementar Inscritos

```sql
-- Función para incrementar el contador de inscritos
CREATE OR REPLACE FUNCTION incrementar_inscritos_ruta(ruta_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE rutas
  SET inscritos_count = inscritos_count + 1
  WHERE id = ruta_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2. Función para Decrementar Inscritos

```sql
-- Función para decrementar el contador de inscritos
CREATE OR REPLACE FUNCTION decrementar_inscritos_ruta(ruta_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE rutas
  SET inscritos_count = GREATEST(inscritos_count - 1, 0)
  WHERE id = ruta_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Tabla de Favoritos de Rutas (si no existe)

```sql
-- Crear tabla para favoritos de rutas
CREATE TABLE IF NOT EXISTS favoritos_rutas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
  ruta_id UUID REFERENCES rutas(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(usuario_id, ruta_id)
);

-- Habilitar RLS
ALTER TABLE favoritos_rutas ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Usuarios pueden ver sus favoritos"
  ON favoritos_rutas FOR SELECT
  USING (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden agregar favoritos"
  ON favoritos_rutas FOR INSERT
  WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden eliminar favoritos"
  ON favoritos_rutas FOR DELETE
  USING (auth.uid() = usuario_id);
```

### 4. Actualizar Tabla de Rutas (Agregar campo WhatsApp si no existe)

```sql
-- Agregar campo enlace_grupo_whatsapp si no existe
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rutas' AND column_name = 'enlace_grupo_whatsapp'
  ) THEN
    ALTER TABLE rutas ADD COLUMN enlace_grupo_whatsapp TEXT;
  END IF;
END $$;
```

### 5. Trigger para Actualizar updated_at Automáticamente

```sql
-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a tablas principales
DROP TRIGGER IF EXISTS update_rutas_updated_at ON rutas;
CREATE TRIGGER update_rutas_updated_at
  BEFORE UPDATE ON rutas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_perfiles_updated_at ON perfiles;
CREATE TRIGGER update_perfiles_updated_at
  BEFORE UPDATE ON perfiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_lugares_updated_at ON lugares;
CREATE TRIGGER update_lugares_updated_at
  BEFORE UPDATE ON lugares
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Verificación

Después de ejecutar estos scripts, verifica que:

1. Las funciones RPC aparezcan en **Database > Functions**
2. La tabla `favoritos_rutas` aparezca en **Database > Tables**
3. Los triggers estén activos en cada tabla

## Notas Importantes

- Las funciones RPC usan `SECURITY DEFINER` para ejecutarse con privilegios del creador
- Los triggers actualizan automáticamente `updated_at` en cada modificación
- Las políticas RLS aseguran que cada usuario solo vea/modifique sus propios datos
