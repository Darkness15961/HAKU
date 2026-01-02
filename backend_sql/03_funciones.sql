-- ============================================
-- HAKU - Sistema de Solicitudes de Rutas
-- Archivo 3: Funciones de Negocio
-- ============================================

-- ============================================
-- 1. FUNCIÓN: Generar Código Único para Rutas
-- ============================================

CREATE OR REPLACE FUNCTION generar_codigo_ruta()
RETURNS text AS $$
DECLARE
  v_codigo text;
  v_existe boolean;
  v_intentos integer := 0;
  v_max_intentos integer := 100;
BEGIN
  LOOP
    -- Generar código formato: HAKU-YYYY-XXXX
    v_codigo := 'HAKU-' || 
                EXTRACT(YEAR FROM now())::text || '-' ||
                upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 4));
    
    -- Verificar que no existe
    SELECT EXISTS(
      SELECT 1 FROM public.rutas WHERE codigo_acceso = v_codigo
    ) INTO v_existe;
    
    EXIT WHEN NOT v_existe;
    
    -- Prevenir loop infinito
    v_intentos := v_intentos + 1;
    IF v_intentos >= v_max_intentos THEN
      RAISE EXCEPTION 'No se pudo generar código único después de % intentos', v_max_intentos;
    END IF;
  END LOOP;
  
  RETURN v_codigo;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generar_codigo_ruta IS 'Genera código único para rutas privadas (ej: HAKU-2024-A7B3)';

-- ============================================
-- 2. FUNCIÓN: Validar Código de Acceso
-- ============================================

CREATE OR REPLACE FUNCTION validar_codigo_ruta(
  p_ruta_id bigint,
  p_codigo text,
  p_usuario_id uuid DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
  v_codigo_correcto text;
  v_es_privada boolean;
  v_resultado boolean;
BEGIN
  -- Obtener datos de la ruta
  SELECT es_privada, codigo_acceso 
  INTO v_es_privada, v_codigo_correcto
  FROM public.rutas
  WHERE id = p_ruta_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ruta no encontrada';
  END IF;
  
  -- Si no es privada, siempre es válido
  IF NOT v_es_privada THEN
    RETURN true;
  END IF;
  
  -- Validar código (case insensitive, sin espacios)
  v_resultado := (upper(trim(p_codigo)) = upper(trim(v_codigo_correcto)));
  
  -- Registrar intento (si se proporciona usuario_id)
  IF p_usuario_id IS NOT NULL THEN
    INSERT INTO public.intentos_acceso_ruta (
      ruta_id, usuario_id, codigo_ingresado, exitoso
    ) VALUES (
      p_ruta_id, p_usuario_id, p_codigo, v_resultado
    );
  END IF;
  
  RETURN v_resultado;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error en validar_codigo_ruta: %', SQLERRM;
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION validar_codigo_ruta IS 'Valida código de acceso para rutas privadas y registra el intento';

-- ============================================
-- 3. FUNCIÓN: Aceptar Postulación
-- ============================================

CREATE OR REPLACE FUNCTION aceptar_postulacion(
  p_postulacion_id bigint,
  p_turista_id uuid
)
RETURNS bigint AS $$
DECLARE
  v_solicitud_id bigint;
  v_guia_id uuid;
  v_solicitud record;
  v_postulacion record;
  v_ruta_id bigint;
  v_codigo_acceso text;
  v_es_privada boolean;
BEGIN
  -- 1. Obtener datos de la postulación
  SELECT * INTO v_postulacion
  FROM public.postulaciones_guias
  WHERE id = p_postulacion_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Postulación no encontrada';
  END IF;
  
  v_solicitud_id := v_postulacion.solicitud_id;
  v_guia_id := v_postulacion.guia_id;
  
  -- 2. Verificar que la solicitud pertenece al turista
  SELECT * INTO v_solicitud
  FROM public.solicitudes_rutas
  WHERE id = v_solicitud_id AND turista_id = p_turista_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No autorizado: la solicitud no pertenece al turista';
  END IF;
  
  -- Verificar que la solicitud está en estado correcto
  IF v_solicitud.estado != 'buscando_guia' THEN
    RAISE EXCEPTION 'La solicitud ya no está buscando guía (estado: %)', v_solicitud.estado;
  END IF;
  
  -- 3. Determinar si la ruta será privada
  v_es_privada := (v_solicitud.preferencia_privacidad = 'privada');
  
  -- Generar código si es privada
  IF v_es_privada THEN
    v_codigo_acceso := generar_codigo_ruta();
  END IF;
  
  -- 4. Crear la ruta en la tabla rutas
  INSERT INTO public.rutas (
    titulo,
    descripcion,
    precio,
    dias,
    categoria,
    guia_id,
    fecha_evento,
    punto_encuentro,
    cupos_totales,
    estado,
    visible,
    es_privada,
    codigo_acceso,
    fecha_generacion_codigo,
    origen_solicitud_id
  ) VALUES (
    v_solicitud.titulo,
    v_solicitud.descripcion,
    v_postulacion.precio_ofertado,
    1, -- Por defecto 1 día
    'Personalizada',
    v_guia_id,
    v_solicitud.fecha_deseada,
    'Por confirmar', -- Se puede mejorar
    v_solicitud.numero_personas,
    'abierto',
    true,
    v_es_privada,
    v_codigo_acceso,
    CASE WHEN v_es_privada THEN now() ELSE NULL END,
    v_solicitud_id
  ) RETURNING id INTO v_ruta_id;
  
  -- 5. Agregar lugares a ruta_detalles
  INSERT INTO public.ruta_detalles (ruta_id, lugar_id, orden_visita)
  SELECT 
    v_ruta_id, 
    unnest(v_solicitud.lugares_ids), 
    generate_series(1, array_length(v_solicitud.lugares_ids, 1));
  
  -- 6. Inscribir automáticamente al turista
  INSERT INTO public.inscripciones (usuario_id, ruta_id, estado_pago)
  VALUES (p_turista_id, v_ruta_id, 'confirmado');
  
  -- 7. Actualizar postulación aceptada
  UPDATE public.postulaciones_guias
  SET estado = 'aceptada', fecha_respuesta = now()
  WHERE id = p_postulacion_id;
  
  -- 8. Rechazar otras postulaciones
  UPDATE public.postulaciones_guias
  SET estado = 'rechazada', fecha_respuesta = now()
  WHERE solicitud_id = v_solicitud_id AND id != p_postulacion_id AND estado = 'pendiente';
  
  -- 9. Actualizar solicitud
  UPDATE public.solicitudes_rutas
  SET 
    estado = 'guia_asignado',
    guia_asignado_id = v_guia_id,
    postulacion_aceptada_id = p_postulacion_id,
    ruta_creada_id = v_ruta_id
  WHERE id = v_solicitud_id;
  
  -- 10. Actualizar estadísticas del guía
  UPDATE public.perfiles
  SET numero_postulaciones_aceptadas = numero_postulaciones_aceptadas + 1
  WHERE id = v_guia_id;
  
  -- 11. Crear notificación para guía aceptado
  INSERT INTO public.notificaciones (usuario_id, titulo, cuerpo, tipo, referencia_id, referencia_tipo)
  VALUES (
    v_guia_id,
    '¡Tu propuesta fue aceptada!',
    CASE 
      WHEN v_es_privada THEN 
        'Tu propuesta para "' || v_solicitud.titulo || '" ha sido aceptada. Código de acceso: ' || v_codigo_acceso
      ELSE
        'Tu propuesta para "' || v_solicitud.titulo || '" ha sido aceptada. Revisa los detalles.'
    END,
    'confirmacion',
    v_ruta_id::text::uuid,
    'ruta'
  );
  
  -- 12. Crear notificaciones para guías rechazados
  INSERT INTO public.notificaciones (usuario_id, titulo, cuerpo, tipo)
  SELECT 
    guia_id,
    'Propuesta no seleccionada',
    'Tu propuesta para "' || v_solicitud.titulo || '" no fue seleccionada esta vez. ¡Sigue postulando!',
    'aviso'
  FROM public.postulaciones_guias
  WHERE solicitud_id = v_solicitud_id AND id != p_postulacion_id;
  
  -- 13. Actualizar estadísticas de guías rechazados
  UPDATE public.perfiles
  SET numero_postulaciones_rechazadas = numero_postulaciones_rechazadas + 1
  WHERE id IN (
    SELECT guia_id FROM public.postulaciones_guias
    WHERE solicitud_id = v_solicitud_id AND id != p_postulacion_id
  );
  
  RETURN v_ruta_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error al aceptar postulación: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION aceptar_postulacion IS 'Acepta una postulación, crea la ruta, inscribe al turista y notifica a todos';

-- ============================================
-- 4. FUNCIÓN: Cancelar Solicitud (24h antes)
-- ============================================

CREATE OR REPLACE FUNCTION cancelar_solicitud(
  p_solicitud_id bigint,
  p_turista_id uuid,
  p_motivo text
)
RETURNS void AS $$
DECLARE
  v_solicitud record;
  v_horas_restantes numeric;
BEGIN
  -- 1. Obtener solicitud
  SELECT * INTO v_solicitud
  FROM public.solicitudes_rutas
  WHERE id = p_solicitud_id AND turista_id = p_turista_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Solicitud no encontrada o no autorizado';
  END IF;
  
  -- 2. Verificar que no esté ya cancelada o completada
  IF v_solicitud.estado IN ('cancelada', 'completada') THEN
    RAISE EXCEPTION 'La solicitud ya está %', v_solicitud.estado;
  END IF;
  
  -- 3. Calcular horas restantes
  v_horas_restantes := EXTRACT(EPOCH FROM (v_solicitud.fecha_deseada - now())) / 3600;
  
  -- 4. Verificar que faltan más de 24 horas
  IF v_horas_restantes < 24 THEN
    RAISE EXCEPTION 'No se puede cancelar con menos de 24 horas de anticipación (faltan % horas)', 
      ROUND(v_horas_restantes, 1);
  END IF;
  
  -- 5. Cancelar solicitud
  UPDATE public.solicitudes_rutas
  SET 
    estado = 'cancelada',
    fecha_cancelacion = now(),
    motivo_cancelacion = p_motivo
  WHERE id = p_solicitud_id;
  
  -- 6. Rechazar todas las postulaciones pendientes
  UPDATE public.postulaciones_guias
  SET estado = 'rechazada', fecha_respuesta = now()
  WHERE solicitud_id = p_solicitud_id AND estado = 'pendiente';
  
  -- 7. Notificar a guías que postularon
  INSERT INTO public.notificaciones (usuario_id, titulo, cuerpo, tipo)
  SELECT 
    guia_id,
    'Solicitud cancelada',
    'La solicitud "' || v_solicitud.titulo || '" ha sido cancelada por el turista.',
    'cancelacion'
  FROM public.postulaciones_guias
  WHERE solicitud_id = p_solicitud_id;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error al cancelar solicitud: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cancelar_solicitud IS 'Cancela una solicitud si faltan más de 24 horas y notifica a los guías';

-- ============================================
-- CONFIRMACIÓN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Funciones creadas exitosamente:';
  RAISE NOTICE '   - generar_codigo_ruta()';
  RAISE NOTICE '   - validar_codigo_ruta()';
  RAISE NOTICE '   - aceptar_postulacion()';
  RAISE NOTICE '   - cancelar_solicitud()';
END $$;
