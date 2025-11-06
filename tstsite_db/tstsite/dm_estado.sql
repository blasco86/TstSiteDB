create table dm_estado
(
    id             integer generated always as identity
        primary key,
    nombre         text                                               not null
        unique,
    fecha_creacion timestamp with time zone default CURRENT_TIMESTAMP not null
);

comment on table dm_estado is 'Estados del sistema';

comment on column dm_estado.nombre is 'Nombre único del estado';

alter table dm_estado
    owner to tstsite;

