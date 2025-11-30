create or replace procedure tstsite_exe.pr_optimizador(IN p_analyze boolean DEFAULT true, IN p_reindex boolean DEFAULT true, IN p_cluster boolean DEFAULT true, IN p_terminate_conns boolean DEFAULT true)
    security definer
    SET search_path = tstsite, tstsite_exe, public
    language plpgsql
as
$$
DECLARE
    v_rec RECORD;
    v_index_name text;
    v_pid int;
BEGIN
    RAISE NOTICE '--- 🧠 INICIO DE OPTIMIZACIÓN ---';
    RAISE NOTICE 'Opciones: ANALYZE=%, REINDEX=%, CLUSTER=%, TERMINATE_CONNS=%',
                 p_analyze, p_reindex, p_cluster, p_terminate_conns;

    -- Terminar conexiones inactivas
    IF p_terminate_conns THEN
        FOR v_pid IN
            SELECT pid
            FROM pg_stat_activity
            WHERE datname = current_database()
              AND state = 'idle'
              AND pid <> pg_backend_pid()
        LOOP
            PERFORM pg_terminate_backend(v_pid);
        END LOOP;
        RAISE NOTICE '🔸 Conexiones inactivas finalizadas.';
    END IF;

    -- Recorre tablas de tstsite y tstsite_exe
    FOR v_rec IN
        SELECT c.oid, n.nspname, c.relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname IN ('tstsite', 'tstsite_exe')
          AND c.relkind = 'r'
        ORDER BY n.nspname, c.relname
    LOOP
        -- ANALYZE
        IF p_analyze THEN
            BEGIN
                EXECUTE format('ANALYZE %I.%I;', v_rec.nspname, v_rec.relname);
                RAISE NOTICE '✅ ANALYZE ejecutado correctamente.';
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '⚠️ Error en ANALYZE: %', SQLERRM;
            END;
        END IF;

        -- REINDEX
        IF p_reindex THEN
            BEGIN
                EXECUTE format('REINDEX TABLE %I.%I;', v_rec.nspname, v_rec.relname);
                RAISE NOTICE '🔁 REINDEX ejecutado correctamente.';
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '⚠️ Error en REINDEX: %', SQLERRM;
            END;
        END IF;

        -- CLUSTER
        IF p_cluster THEN
            SELECT i.relname
            INTO v_index_name
            FROM pg_index x
            JOIN pg_class i ON i.oid = x.indexrelid
            WHERE x.indrelid = v_rec.oid
              AND x.indisprimary = true;

            IF v_index_name IS NOT NULL THEN
                BEGIN
                    EXECUTE format('CLUSTER %I.%I USING %I;', v_rec.nspname, v_rec.relname, v_index_name);
                    RAISE NOTICE '🧩 CLUSTER ejecutado correctamente.';
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE '⚠️ Error en CLUSTER: %', SQLERRM;
                END;
            END IF;
        END IF;
    END LOOP;

    RAISE NOTICE '--- ✅ OPTIMIZACIÓN COMPLETADA ---';
END;
$$;

comment on procedure tstsite_exe.pr_optimizador(boolean, boolean, boolean, boolean) is 'Procedimiento de optimización de DB';

alter procedure tstsite_exe.pr_optimizador(boolean, boolean, boolean, boolean) owner to tstsite;

grant execute on procedure tstsite_exe.pr_optimizador(boolean, boolean, boolean, boolean) to tstsite_exe;

