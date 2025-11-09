create table dm_permiso
(
    id             integer generated always as identity
        primary key,
    id_perfil      integer                                            not null
        constraint fk_dm_permiso_dm_perfil
            references dm_perfil
            on update cascade on delete cascade,
    nombre         text                                               not null,
    fecha_creacion timestamp with time zone default CURRENT_TIMESTAMP not null
);

comment on table dm_permiso is 'Permisos asignados a cada perfil';

alter table dm_permiso
    owner to tstsite;

