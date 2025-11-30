create table hc_tipo_producto
(
    id                 integer generated always as identity
        primary key,
    nombre             text                                               not null
        unique,
    id_sub_tipo_2_id   integer
        constraint fk_hc_tipo_producto_2_hc_tipo_producto
            references hc_tipo_producto
            on update cascade on delete restrict,
    slug               text
        unique,
    orden              integer                  default 0,
    id_estado          integer                                            not null
        constraint fk_hc_producto_2_dm_estado
            references dm_estado
            on update cascade on delete restrict,
    fecha_creacion     timestamp with time zone default CURRENT_TIMESTAMP not null,
    fecha_modificacion timestamp with time zone default CURRENT_TIMESTAMP not null
);

comment on table hc_tipo_producto is 'Tipos de producto (jerarquía padre-hijo id_sub_tipo_2_id)';

comment on column hc_tipo_producto.nombre is 'Nombre único de tipo de producto';

alter table hc_tipo_producto
    owner to tstsite;

create index idx_hc_tipo_producto_estado
    on hc_tipo_producto (id_estado);

create index idx_hc_tipo_producto_padre
    on hc_tipo_producto (id_sub_tipo_2_id);

