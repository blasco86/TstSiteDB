create or replace function tstsite_exe.fn_login(p_usuario text, p_password text) returns jsonb
    security definer
    SET search_path = tstsite, tstsite_exe, public
    language plpgsql
as
$$
DECLARE
    v_rec RECORD;
    v_detalle JSONB := '{}'::jsonb;
    v_permisos JSONB := '[]'::jsonb;
BEGIN
    -- 🔍 Intentar obtener el usuario (manejo de excepciones dentro del bloque)
    BEGIN
        SELECT u.id, u.password_hash, e.nombre AS estado, u.id_perfil, p.nombre AS perfil, u.intentos_fallidos
          INTO STRICT v_rec
          FROM tstsite.hc_usuario u
          JOIN tstsite.dm_estado e ON e.id = u.id_estado
          JOIN tstsite.dm_perfil p ON p.id = u.id_perfil
         WHERE u.usuario = p_usuario
        LIMIT 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN jsonb_build_object('resultado','error','mensaje','Usuario no encontrado');
        WHEN TOO_MANY_ROWS THEN
            RETURN jsonb_build_object('resultado','error','mensaje','Usuario duplicado, contacte al administrador');
    END;

    -- 🚦 Validar estado
    IF v_rec.estado <> 'Activo' THEN
        RETURN jsonb_build_object('resultado','error','mensaje',format('Usuario en estado "%s"', v_rec.estado));
    END IF;

    -- 🔐 Validar contraseña
    IF crypt(p_password, v_rec.password_hash) <> v_rec.password_hash THEN
        UPDATE tstsite.hc_usuario
           SET intentos_fallidos = intentos_fallidos + 1,
               fecha_modificacion = CURRENT_TIMESTAMP
         WHERE id = v_rec.id;

        RETURN jsonb_build_object('resultado','error','mensaje','Contraseña incorrecta');
    END IF;

    -- ✅ Login correcto
    UPDATE tstsite.hc_usuario
       SET intentos_fallidos = 0,
           fecha_logado = CURRENT_TIMESTAMP,
           fecha_modificacion = CURRENT_TIMESTAMP
     WHERE id = v_rec.id;

    -- 👤 Detalles del usuario
    SELECT jsonb_build_object(
               'nombre', d.nombre,
               'apellidos', d.apellidos,
               'telefono', d.telefono
           )
      INTO v_detalle
      FROM tstsite.dm_detalle_usuario d
     WHERE d.id_usuario = v_rec.id
     LIMIT 1;

    -- 🧩 Permisos del perfil
    SELECT COALESCE(jsonb_agg(nombre ORDER BY nombre), '[]'::jsonb)
      INTO v_permisos
      FROM tstsite.dm_permiso
     WHERE id_perfil = v_rec.id_perfil;

    -- 🧾 Resultado final
    RETURN jsonb_build_object(
        'resultado', 'ok',
        'mensaje', 'Login correcto',
        'idUsuario', v_rec.id,
        'usuario', p_usuario,
        'perfil', v_rec.perfil,
        'estado', v_rec.estado,
        'permisos', v_permisos,
        'detalles', COALESCE(v_detalle, '{}'::jsonb)
    );
END;
$$;

comment on function tstsite_exe.fn_login(text, text) is 'Función de login';

alter function tstsite_exe.fn_login(text, text) owner to tstsite;

grant execute on function tstsite_exe.fn_login(text, text) to tstsite_exe;

