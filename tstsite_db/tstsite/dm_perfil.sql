create table dm_perfil
(
    id             integer generated always as identity
        primary key,
    nombre         text                                               not null
        unique,
    fecha_creacion timestamp with time zone default CURRENT_TIMESTAMP not null
);

comment on table dm_perfil is 'Perfiles de usuario (rol en el sistema)';

alter table dm_perfil
    owner to tstsite;

