create or replace function tstsite_exe.fn_menu_catalogo_json() returns jsonb
    security definer
    SET search_path = tstsite, tstsite_exe, public
    language sql
as
$$
WITH RECURSIVE tipo_arbol AS (
    SELECT
        t.id AS tipo_id,
        t.nombre AS tipo_nombre,
        t.slug AS tipo_slug,
        t.orden AS tipo_orden,
        t.id_sub_tipo_2_id AS tipo_padre_id
    FROM hc_tipo_producto t
    WHERE t.id_sub_tipo_2_id IS NULL
      AND t.id_estado = (SELECT id FROM dm_estado WHERE nombre='Activo' LIMIT 1)

    UNION ALL

    SELECT
        h.id AS tipo_id,
        h.nombre AS tipo_nombre,
        h.slug AS tipo_slug,
        h.orden AS tipo_orden,
        h.id_sub_tipo_2_id AS tipo_padre_id
    FROM hc_tipo_producto h
    INNER JOIN tipo_arbol a ON h.id_sub_tipo_2_id = a.tipo_id
    WHERE h.id_estado = (SELECT id FROM dm_estado WHERE nombre='Activo' LIMIT 1)
),
productos_json AS (
    SELECT
        t.id AS tipo_id,
        jsonb_agg(
            jsonb_build_object(
                'id', p.id,
                'nombre', p.nombre,
                'slug', p.slug,
                'atributos', p.atributos
            ) ORDER BY p.nombre
        ) AS productos
    FROM hc_producto p
    JOIN hc_tipo_producto t ON p.id_tipo_producto = t.id
    WHERE p.id_estado = (SELECT id FROM dm_estado WHERE nombre='Activo' LIMIT 1)
    GROUP BY t.id
),
tipo_con_productos AS (
    SELECT
        a.tipo_id,
        a.tipo_nombre,
        a.tipo_slug,
        a.tipo_orden,
        a.tipo_padre_id,
        COALESCE(p.productos, '[]'::jsonb) AS productos
    FROM tipo_arbol a
    LEFT JOIN productos_json p ON a.tipo_id = p.tipo_id
)
SELECT jsonb_agg(
    jsonb_build_object(
        'id', t.tipo_id,
        'nombre', t.tipo_nombre,
        'slug', t.tipo_slug,
        'orden', t.tipo_orden,
        'productos', t.productos,
        'subtipos', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', c.tipo_id,
                    'nombre', c.tipo_nombre,
                    'slug', c.tipo_slug,
                    'orden', c.tipo_orden,
                    'productos', c.productos
                ) ORDER BY c.tipo_orden, c.tipo_nombre
            )
            FROM tipo_con_productos c
            WHERE c.tipo_padre_id = t.tipo_id
        )
    ) ORDER BY t.tipo_orden, t.tipo_nombre
)
FROM tipo_con_productos t
WHERE t.tipo_padre_id IS NULL;
$$;

comment on function tstsite_exe.fn_menu_catalogo_json() is 'Función para obtener el menú del catálogo en formato JSONB';

alter function tstsite_exe.fn_menu_catalogo_json() owner to tstsite;

grant execute on function tstsite_exe.fn_menu_catalogo_json() to tstsite_exe;

