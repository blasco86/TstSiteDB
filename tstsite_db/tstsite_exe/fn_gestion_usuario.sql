create or replace function tstsite_exe.fn_gestion_usuario(p_accion text, p_datos jsonb) returns jsonb
    security definer
    SET search_path = tstsite, tstsite_exe, public
    language plpgsql
as
$$
DECLARE
    v_id_usuario INTEGER;
    v_resultado  JSONB;
    v_hash       TEXT;
BEGIN
    -- 🧱 INSERTAR USUARIO
    IF p_accion = 'insert' THEN
        IF p_datos ->> 'usuario' IS NULL OR p_datos ->> 'password' IS NULL OR p_datos ->> 'id_perfil' IS NULL THEN
            RETURN jsonb_build_object('resultado', 'error', 'mensaje', 'Faltan campos obligatorios');
        END IF;

        v_hash := crypt(p_datos ->> 'password', gen_salt('bf', 8));

        INSERT INTO tstsite.hc_usuario (usuario, password_hash, id_estado, id_perfil)
        VALUES (p_datos ->> 'usuario',
                v_hash,
                COALESCE((SELECT id FROM tstsite.dm_estado WHERE nombre ILIKE 'Activo' LIMIT 1), 1),
                (p_datos ->> 'id_perfil')::int)
        RETURNING id INTO v_id_usuario;

        IF p_datos ? 'detalles' THEN
            INSERT INTO tstsite.dm_detalle_usuario (id_usuario, nombre, apellidos, telefono, mail, direccion,
                                                    fecha_nacimiento)
            VALUES (v_id_usuario,
                    p_datos #>> '{detalles,nombre}',
                    p_datos #>> '{detalles,apellidos}',
                    p_datos #>> '{detalles,telefono}',
                    p_datos #>> '{detalles,mail}',
                    p_datos #>> '{detalles,direccion}',
                    NULLIF(p_datos #>> '{detalles,fecha_nacimiento}', '')::date);
        END IF;

        RETURN jsonb_build_object('resultado', 'ok', 'mensaje', 'Usuario creado', 'id_usuario', v_id_usuario);
    END IF;


    -- 🔍 SELECT USUARIO POR NOMBRE
    IF p_accion = 'select' THEN
        IF p_datos ->> 'usuario' IS NULL THEN
            RETURN jsonb_build_object('resultado', 'error', 'mensaje', 'Debe especificar el usuario');
        END IF;

        SELECT jsonb_build_object(
                       'id', u.id,
                       'usuario', u.usuario,
                       'estado', e.nombre,
                       'perfil', p.nombre,
                       'intentos_fallidos', u.intentos_fallidos,
                       'detalles', jsonb_build_object(
                               'nombre', d.nombre,
                               'apellidos', d.apellidos,
                               'telefono', d.telefono,
                               'mail', d.mail
                                   )
               )
        INTO v_resultado
        FROM tstsite.hc_usuario u
                 JOIN tstsite.dm_estado e ON e.id = u.id_estado
                 JOIN tstsite.dm_perfil p ON p.id = u.id_perfil
                 LEFT JOIN tstsite.dm_detalle_usuario d ON d.id_usuario = u.id
        WHERE u.usuario = p_datos ->> 'usuario'
        LIMIT 1;

        IF v_resultado IS NULL THEN
            RETURN jsonb_build_object('resultado', 'error', 'mensaje', 'Usuario no encontrado');
        END IF;

        RETURN jsonb_build_object('resultado', 'ok', 'usuario', v_resultado);
    END IF;


    -- 📜 LISTAR TODOS LOS USUARIOS
    IF p_accion = 'list' THEN
        SELECT COALESCE(jsonb_agg(
                                jsonb_build_object(
                                        'id', u.id,
                                        'usuario', u.usuario,
                                        'estado', e.nombre,
                                        'perfil', p.nombre,
                                        'fecha_creacion', u.fecha_creacion
                                ) ORDER BY u.id), '[]'::jsonb)
        INTO v_resultado
        FROM tstsite.hc_usuario u
                 JOIN tstsite.dm_estado e ON e.id = u.id_estado
                 JOIN tstsite.dm_perfil p ON p.id = u.id_perfil;

        RETURN jsonb_build_object('resultado', 'ok', 'usuarios', v_resultado);
    END IF;


    -- 🔎 BUSCAR USUARIOS POR CAMPOS CLAVE
    IF p_accion = 'search' THEN
        SELECT COALESCE(jsonb_agg(
                                jsonb_build_object(
                                        'id', u.id,
                                        'usuario', u.usuario,
                                        'estado', e.nombre,
                                        'perfil', p.nombre
                                ) ORDER BY u.usuario), '[]'::jsonb)
        INTO v_resultado
        FROM tstsite.hc_usuario u
                 JOIN tstsite.dm_estado e ON e.id = u.id_estado
                 JOIN tstsite.dm_perfil p ON p.id = u.id_perfil
        WHERE (p_datos ->> 'usuario' IS NULL OR u.usuario ILIKE '%' || (p_datos ->> 'usuario') || '%')
          AND (p_datos ->> 'estado' IS NULL OR e.nombre ILIKE '%' || (p_datos ->> 'estado') || '%')
          AND (p_datos ->> 'perfil' IS NULL OR p.nombre ILIKE '%' || (p_datos ->> 'perfil') || '%');

        RETURN jsonb_build_object('resultado', 'ok', 'usuarios', v_resultado);
    END IF;


    -- ✏️ ACTUALIZAR USUARIO
    IF p_accion = 'update' THEN
        SELECT id INTO v_id_usuario FROM tstsite.hc_usuario WHERE usuario = p_datos ->> 'usuario';
        IF v_id_usuario IS NULL THEN
            RETURN jsonb_build_object('resultado', 'error', 'mensaje', 'Usuario no encontrado');
        END IF;

        UPDATE tstsite.hc_usuario
        SET id_perfil          = COALESCE((p_datos ->> 'id_perfil')::int, id_perfil),
            id_estado          = COALESCE((p_datos ->> 'id_estado')::int, id_estado),
            fecha_modificacion = CURRENT_TIMESTAMP
        WHERE id = v_id_usuario;

        IF p_datos ? 'password' THEN
            UPDATE tstsite.hc_usuario
            SET password_hash = crypt(p_datos ->> 'password', gen_salt('bf', 8))
            WHERE id = v_id_usuario;
        END IF;

        UPDATE tstsite.dm_detalle_usuario
        SET nombre           = COALESCE(p_datos #>> '{detalles,nombre}', nombre),
            apellidos        = COALESCE(p_datos #>> '{detalles,apellidos}', apellidos),
            telefono         = COALESCE(p_datos #>> '{detalles,telefono}', telefono),
            mail             = COALESCE(p_datos #>> '{detalles,mail}', mail),
            direccion        = COALESCE(p_datos #>> '{detalles,direccion}', direccion),
            fecha_nacimiento = COALESCE(NULLIF(p_datos #>> '{detalles,fecha_nacimiento}', '')::date, fecha_nacimiento)
        WHERE id_usuario = v_id_usuario;

        RETURN jsonb_build_object('resultado', 'ok', 'mensaje', 'Usuario actualizado');
    END IF;


    -- ❌ ELIMINAR USUARIO + DETALLES
    IF p_accion = 'delete' THEN
        SELECT id INTO v_id_usuario FROM tstsite.hc_usuario WHERE usuario = p_datos ->> 'usuario' LIMIT 1;
        IF v_id_usuario IS NULL THEN
            RETURN jsonb_build_object('resultado', 'error', 'mensaje', 'Usuario no encontrado');
        END IF;

        DELETE FROM tstsite.dm_detalle_usuario WHERE id_usuario = v_id_usuario;
        DELETE FROM tstsite.hc_usuario WHERE id = v_id_usuario;

        RETURN jsonb_build_object('resultado', 'ok', 'mensaje', 'Usuario eliminado');
    END IF;


    -- 🚫 ACCIÓN INVÁLIDA
    RETURN jsonb_build_object('resultado', 'error', 'mensaje',
                              'Acción no válida. Use: insert, select, update, delete, list o search');

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('resultado', 'error', 'mensaje', 'Error interno', 'detalle', SQLERRM);
END;
$$;

comment on function tstsite_exe.fn_gestion_usuario(text, jsonb) is 'Gestión de usuarios';

alter function tstsite_exe.fn_gestion_usuario(text, jsonb) owner to tstsite;

grant execute on function tstsite_exe.fn_gestion_usuario(text, jsonb) to tstsite_exe;

