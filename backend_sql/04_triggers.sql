-- ============================================
-- HAKU - Sistema de Solicitudes de Rutas
-- Archivo 4: Triggers
-- ============================================

-- ============================================
-- 1. TRIGGER: Actualizar Contador de Postulaciones
-- ============================================

CREATE OR REPLACE FUNCTION actualizar_contador_postulaciones()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Incrementar contador en solicitud
    UPDATE public.solicitudes_rutas
    SET numero_postulaciones = numero_postulaciones + 1
    WHERE id = NEW.solicitud_id;
    
    -- Incrementar contador total en perfil del guía
    UPDATE public.perfiles
    SET numero_postulaciones_totales = numero_postulaciones_totales + 1
    WHERE id = NEW.guia_id;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrementar contador en solicitud
    UPDATE public.solicitudes_rutas
    SET numero_postulaciones = GREATEST(numero_postulaciones - 1, 0)
    WHERE id = OLD.solicitud_id;
    
    -- Decrementar contador total en perfil del guía
    UPDATE public.perfiles
    SET numero_postulaciones_totales = GREATEST(numero_postulaciones_totales - 1, 0)
    WHERE id = OLD.guia_id;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger
DROP TRIGGER IF EXISTS trigger_actualizar_contador_postulaciones ON public.postulaciones_guias;

CREATE TRIGGER trigger_actualizar_contador_postulaciones
AFTER INSERT OR DELETE ON public.postulaciones_guias
FOR EACH ROW
EXECUTE FUNCTION actualizar_contador_postulaciones();

COMMENT ON FUNCTION actualizar_contador_postulaciones IS 'Actualiza contadores cuando se crea o elimina una postulación';

-- ============================================
-- 2. TRIGGER: Notificar Nueva Postulación
-- ============================================

CREATE OR REPLACE FUNCTION notificar_nueva_postulacion()
RETURNS TRIGGER AS $$
DECLARE
  v_solicitud record;
  v_guia record;
BEGIN
  -- Obtener datos de la solicitud
  SELECT * INTO v_solicitud
  FROM public.solicitudes_rutas
  WHERE id = NEW.solicitud_id;
  
  -- Obtener datos del guía
  SELECT * INTO v_guia
  FROM public.perfiles
  WHERE id = NEW.guia_id;
  
  -- Crear notificación para el turista
  INSERT INTO public.notificaciones (
    usuario_id, 
    titulo, 
    cuerpo, 
    tipo,
    referencia_id,
    referencia_tipo
  ) VALUES (
    v_solicitud.turista_id,
    '¡Nueva propuesta recibida!',
    v_guia.seudonimo || ' ha enviado una propuesta para "' || v_solicitud.titulo || '"',
    'aviso',
    NEW.id::text::uuid,
    'postulacion'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger
DROP TRIGGER IF EXISTS trigger_notificar_nueva_postulacion ON public.postulaciones_guias;

CREATE TRIGGER trigger_notificar_nueva_postulacion
AFTER INSERT ON public.postulaciones_guias
FOR EACH ROW
EXECUTE FUNCTION notificar_nueva_postulacion();

COMMENT ON FUNCTION notificar_nueva_postulacion IS 'Notifica al turista cuando un guía envía una propuesta';

-- ============================================
-- 3. TRIGGER: Validar Fecha Deseada
-- ============================================

CREATE OR REPLACE FUNCTION validar_fecha_deseada()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar que la fecha deseada sea al menos 48 horas en el futuro
  IF NEW.fecha_deseada < (now() + INTERVAL '48 hours') THEN
    RAISE EXCEPTION 'La fecha deseada debe ser al menos 48 horas en el futuro';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger
DROP TRIGGER IF EXISTS trigger_validar_fecha_deseada ON public.solicitudes_rutas;

CREATE TRIGGER trigger_validar_fecha_deseada
BEFORE INSERT OR UPDATE OF fecha_deseada ON public.solicitudes_rutas
FOR EACH ROW
EXECUTE FUNCTION validar_fecha_deseada();

COMMENT ON FUNCTION validar_fecha_deseada IS 'Valida que la fecha deseada sea al menos 48 horas en el futuro';

-- ============================================
-- 4. TRIGGER: Prevenir Modificación de Solicitud Asignada
-- ============================================

CREATE OR REPLACE FUNCTION prevenir_modificacion_solicitud_asignada()
RETURNS TRIGGER AS $$
BEGIN
  -- Si la solicitud ya tiene guía asignado, no se puede modificar
  IF OLD.estado = 'guia_asignado' AND NEW.estado = 'guia_asignado' THEN
    IF OLD.titulo != NEW.titulo OR 
       OLD.descripcion != NEW.descripcion OR 
       OLD.lugares_ids != NEW.lugares_ids OR
       OLD.fecha_deseada != NEW.fecha_deseada OR
       OLD.numero_personas != NEW.numero_personas THEN
      RAISE EXCEPTION 'No se puede modificar una solicitud con guía asignado';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger
DROP TRIGGER IF EXISTS trigger_prevenir_modificacion_solicitud_asignada ON public.solicitudes_rutas;

CREATE TRIGGER trigger_prevenir_modificacion_solicitud_asignada
BEFORE UPDATE ON public.solicitudes_rutas
FOR EACH ROW
EXECUTE FUNCTION prevenir_modificacion_solicitud_asignada();

COMMENT ON FUNCTION prevenir_modificacion_solicitud_asignada IS 'Previene modificaciones a solicitudes con guía ya asignado';

-- ============================================
-- CONFIRMACIÓN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Triggers creados exitosamente:';
  RAISE NOTICE '   - trigger_actualizar_contador_postulaciones';
  RAISE NOTICE '   - trigger_notificar_nueva_postulacion';
  RAISE NOTICE '   - trigger_validar_fecha_deseada';
  RAISE NOTICE '   - trigger_prevenir_modificacion_solicitud_asignada';
END $$;
