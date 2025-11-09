create table hc_usuario
(
    id                 integer generated always as identity
        primary key,
    usuario            text                                               not null
        unique,
    password_hash      text                                               not null
        constraint hc_usuario_password_hash_check
            check (char_length(password_hash) > 30),
    id_estado          integer                                            not null
        constraint fk_hc_usuario_2_dm_estado
            references dm_estado
            on update cascade on delete restrict,
    intentos_fallidos  smallint                 default 0                 not null,
    fecha_logado       timestamp with time zone,
    fecha_bloqueado    timestamp with time zone,
    fecha_creacion     timestamp with time zone default CURRENT_TIMESTAMP not null,
    fecha_modificacion timestamp with time zone default CURRENT_TIMESTAMP not null,
    id_perfil          integer                                            not null
        constraint fk_hc_usuario_dm_perfil
            references dm_perfil
            on update cascade on delete restrict
);

comment on table hc_usuario is 'Usuarios del sistema';

comment on column hc_usuario.usuario is 'Nombre único de usuario (case-insensitive)';

comment on column hc_usuario.password_hash is 'Contraseña almacenada con hash seguro';

alter table hc_usuario
    owner to tstsite;

