create table hc_producto
(
    id                 integer generated always as identity
        primary key,
    nombre             text                                               not null,
    slug               text
        unique,
    atributos          jsonb                    default '{}'::jsonb       not null,
    id_tipo_producto   integer                                            not null
        references hc_tipo_producto
            on update cascade on delete restrict,
    id_estado          integer                                            not null
        references dm_estado
            on update cascade on delete restrict,
    fecha_creacion     timestamp with time zone default CURRENT_TIMESTAMP not null,
    fecha_modificacion timestamp with time zone default CURRENT_TIMESTAMP not null
);

comment on table hc_producto is 'Producto';

comment on column hc_producto.atributos is 'Atributos dinámicos en formato JSONB';

alter table hc_producto
    owner to tstsite;

create index idx_hc_producto_nombre
    on hc_producto using gin (to_tsvector('simple'::regconfig, nombre));

create index idx_hc_producto_atributos_gin
    on hc_producto using gin (atributos);

create index idx_hc_producto_estado
    on hc_producto (id_estado);

create index idx_hc_producto_tipo
    on hc_producto (id_tipo_producto);

