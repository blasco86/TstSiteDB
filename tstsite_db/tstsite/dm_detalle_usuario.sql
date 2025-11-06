create table dm_detalle_usuario
(
    id               integer generated always as identity
        primary key,
    id_usuario       integer not null
        constraint fk_dm_detalle_usuario_hc_usuario
            references hc_usuario
            on update cascade on delete cascade,
    nombre           text,
    apellidos        text,
    telefono         text,
    mail             text,
    direccion        text,
    fecha_nacimiento date
);

comment on table dm_detalle_usuario is 'Detalles adicionales de cada usuario';

alter table dm_detalle_usuario
    owner to tstsite;

