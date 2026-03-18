# 🗃️ TstSiteDB

> **Base de datos PostgreSQL** de la plataforma TstSite — diseñada con separación de schemas por responsabilidad, lógica de negocio encapsulada en PL/pgSQL y un proceso de mantenimiento automático integrado en el pipeline CI/CD.

---

## 📌 Descripción

**TstSiteDB** contiene la definición completa del modelo de datos de TstSite: scripts DDL de tablas, índices, funciones y procedimientos almacenados. Todo el acceso a datos desde la API se realiza exclusivamente a través de funciones PL/pgSQL con `SECURITY DEFINER`, lo que garantiza que la capa de aplicación nunca opera directamente sobre las tablas.

---

## 🛠️ Stack Tecnológico

| Componente | Detalle |
|-----------|---------|
| **Motor** | PostgreSQL (Alwaysdata cloud managed) |
| **Lenguaje procedural** | PL/pgSQL |
| **Hash de contraseñas** | `pgcrypto` — Blowfish (`bf`) con coste 8 vía `crypt()` + `gen_salt()` |
| **Búsqueda de texto** | `tsvector` + índices GIN (`to_tsvector('simple', ...)`) |
| **Atributos dinámicos** | `JSONB` + índices GIN |
| **Timestamps** | `timestamp with time zone` (zona horaria `Europe/Madrid` por defecto) |
| **Identidad de PK** | `GENERATED ALWAYS AS IDENTITY` |
| **Hosting** | `postgresql-tstsite.alwaysdata.net` |

---

## 🏗️ Arquitectura de schemas

La base de datos utiliza **dos schemas separados** con responsabilidades distintas:

```
tstsite_db
├── schema: tstsite          ← Datos (tablas, restricciones, índices)
│   ├── dm_estado            — Maestro de estados del sistema
│   ├── dm_perfil            — Perfiles / roles de usuario
│   ├── dm_permiso           — Permisos asignados a cada perfil
│   ├── dm_detalle_usuario   — Datos personales del usuario (1:1 con hc_usuario)
│   ├── hc_usuario           — Usuarios del sistema (credenciales + estado)
│   ├── hc_tipo_producto     — Tipos de producto (jerarquía padre-hijo auto-referencial)
│   └── hc_producto          — Productos con atributos dinámicos JSONB
│
└── schema: tstsite_exe      ← Lógica de negocio (funciones y procedimientos)
    ├── fn_login             — Autenticación con Blowfish + control de intentos
    ├── fn_gestion_usuario   — CRUD completo de usuarios (insert/select/update/delete/list/search)
    ├── fn_menu_catalogo_json — Catálogo jerárquico recursivo en JSONB
    └── pr_optimizador       — Mantenimiento automático (ANALYZE + REINDEX + CLUSTER)
```

### Principio de acceso mínimo
El usuario de ejecución `tstsite_exe` solo tiene permisos `EXECUTE` sobre las funciones del schema `tstsite_exe`. **Nunca accede directamente a las tablas.** Las funciones se definen con `SECURITY DEFINER + SET search_path` explícito para evitar ataques de escalada de privilegios por manipulación del `search_path`.

---

## 📋 Modelo de datos

### Usuarios y seguridad

```
dm_estado ──┐
            ├──► hc_usuario ──► dm_detalle_usuario
dm_perfil ──┘         │
                       │
dm_permiso ◄───────────┘ (via id_perfil)
```

| Tabla | Descripción | Destacado |
|-------|-------------|-----------|
| `hc_usuario` | Credenciales y estado del usuario | `password_hash` con check `char_length > 30`; campos `intentos_fallidos`, `fecha_logado`, `fecha_bloqueado` |
| `dm_detalle_usuario` | Datos personales (nombre, apellidos, teléfono, mail, dirección, nacimiento) | Cascade delete con `hc_usuario` |
| `dm_perfil` | Roles del sistema (Admin, Usuario, etc.) | Nombre único |
| `dm_permiso` | Permisos granulares asociados a cada perfil | Cascade delete con `dm_perfil` |
| `dm_estado` | Maestro de estados (Activo, Inactivo, Bloqueado…) | Nombre único |

### Catálogo de productos

```
hc_tipo_producto ─────────────────────────► hc_tipo_producto
(padre: id_sub_tipo_2_id auto-referencial)

hc_tipo_producto ──► hc_producto
```

| Tabla | Descripción | Destacado |
|-------|-------------|-----------|
| `hc_tipo_producto` | Categorías con jerarquía árbol (auto-referencial) | Campo `slug` único, `orden` para presentación, `id_sub_tipo_2_id` padre |
| `hc_producto` | Productos del catálogo | `atributos JSONB` para propiedades dinámicas sin alterar el esquema; campo `slug` único |

---

## ⚙️ Funciones y procedimientos PL/pgSQL

### `fn_login(p_usuario, p_password)` → `JSONB`
Gestiona el flujo completo de autenticación:
1. Busca el usuario con `STRICT` (detecta duplicados)
2. Valida el estado (`Activo` requerido)
3. Verifica la contraseña con `crypt(p_password, password_hash)` — Blowfish
4. En fallo: incrementa `intentos_fallidos` + actualiza `fecha_modificacion`
5. En éxito: resetea intentos, actualiza `fecha_logado`, devuelve perfil + permisos + detalles en JSONB

```json
{
  "resultado": "ok",
  "idUsuario": 1,
  "usuario": "admin",
  "perfil": "Admin",
  "permisos": ["usuarios.ver", "catalogo.editar"],
  "detalles": { "nombre": "...", "apellidos": "...", "telefono": "..." }
}
```

### `fn_gestion_usuario(p_accion, p_datos)` → `JSONB`
CRUD completo de usuarios en una sola función polimórfica vía parámetro `p_accion`:

| Acción | Operación |
|--------|-----------|
| `insert` | Crea usuario con hash Blowfish + inserta detalles opcionales |
| `select` | Obtiene un usuario por nombre con JOIN a estado, perfil y detalles |
| `update` | Actualiza campos del usuario y/o detalles; rehashea contraseña si se proporciona |
| `delete` | Elimina usuario + detalles (cascade) |
| `list` | Devuelve `jsonb_agg` de todos los usuarios ordenados por ID |
| `search` | Búsqueda parametrizada por campos clave |

### `fn_menu_catalogo_json()` → `JSONB`
Genera el árbol completo del catálogo en una sola consulta usando **CTE recursivo**:

```sql
WITH RECURSIVE tipo_arbol AS (
    -- Nodos raíz (sin padre)
    SELECT ... FROM hc_tipo_producto WHERE id_sub_tipo_2_id IS NULL AND estado = 'Activo'
    UNION ALL
    -- Nodos hijos (recursivo)
    SELECT ... FROM hc_tipo_producto INNER JOIN tipo_arbol ON ...
)
```

Devuelve la jerarquía completa de categorías → subcategorías → productos en un único objeto JSONB, lista para ser consumida directamente por la API sin procesamiento adicional.

### `pr_optimizador(analyze, reindex, cluster, terminate_conns)` → `void`
Procedimiento de mantenimiento automático que recorre todas las tablas de los schemas `tstsite` y `tstsite_exe`:

| Paso | Operación | Efecto |
|------|-----------|--------|
| 1 | `pg_terminate_backend` (idle) | Libera conexiones inactivas |
| 2 | `ANALYZE` | Actualiza estadísticas del planificador de consultas |
| 3 | `REINDEX TABLE` | Reconstruye índices para eliminar bloat |
| 4 | `CLUSTER ... USING <pk_index>` | Reordena físicamente los datos según la PK |

---

## 🔐 Seguridad de la base de datos

### Modelo de usuarios PostgreSQL

| Usuario | Rol | Acceso |
|---------|-----|--------|
| `tstsite` | Administrador de la BD | Owner de tablas y funciones |
| `tstsite_exe` | Usuario de ejecución (API) | Solo `EXECUTE` en `tstsite_exe.*` |

### Contraseñas con Blowfish
Las contraseñas nunca se almacenan en texto plano. Se usa `pgcrypto`:

```sql
-- Almacenamiento
password_hash = crypt(p_password, gen_salt('bf', 8))

-- Verificación (timing-safe por diseño de Blowfish)
crypt(p_password, v_rec.password_hash) = v_rec.password_hash
```

El coste `8` de Blowfish introduce una latencia computacional deliberada que dificulta los ataques de fuerza bruta offline.

### SECURITY DEFINER + search_path fijo
Todas las funciones declaran explícitamente:
```sql
SECURITY DEFINER
SET search_path = tstsite, tstsite_exe, public
```
Esto evita que un atacante con acceso al usuario `tstsite_exe` pueda manipular el `search_path` para ejecutar código malicioso en lugar de las funciones legítimas.

### Integridad referencial
Todas las claves foráneas usan `ON UPDATE CASCADE` y `ON DELETE RESTRICT` (salvo `dm_detalle_usuario`, que usa `CASCADE` al ser una extensión directa de `hc_usuario`).

---

## 📊 Índices destacados

| Tabla | Índice | Tipo | Propósito |
|-------|--------|------|-----------|
| `hc_producto` | `idx_hc_producto_nombre` | GIN + tsvector | Búsqueda full-text sobre nombre |
| `hc_producto` | `idx_hc_producto_atributos_gin` | GIN | Consultas sobre atributos JSONB |
| `hc_producto` | `idx_hc_producto_estado` | B-tree | Filtrado por estado |
| `hc_producto` | `idx_hc_producto_tipo` | B-tree | JOIN con tipo de producto |
| `hc_tipo_producto` | `idx_hc_tipo_producto_estado` | B-tree | Filtrado por estado |
| `hc_tipo_producto` | `idx_hc_tipo_producto_padre` | B-tree | Recorrido recursivo del árbol |

---

## 📁 Estructura del repositorio

```
TstSiteDB/
└── tstsite_db/
    ├── tstsite/                    ← DDL de tablas (schema de datos)
    │   ├── dm_estado.sql
    │   ├── dm_perfil.sql
    │   ├── dm_permiso.sql
    │   ├── dm_detalle_usuario.sql
    │   ├── hc_usuario.sql
    │   ├── hc_tipo_producto.sql
    │   └── hc_producto.sql
    └── tstsite_exe/                ← Lógica de negocio (schema de ejecución)
        ├── fn_login.sql
        ├── fn_gestion_usuario.sql
        ├── fn_menu_catalogo_json.sql
        └── pr_optimizador.sql
```

---

## 🔄 Despliegue — CI/CD

Los scripts SQL se despliegan automáticamente mediante **GitHub Actions** como parte del pipeline centralizado de TstSite. La secuencia de operaciones sobre la BD en cada ejecución es:

1. **Reinicio de conexiones activas** — `pg_terminate_backend` sobre todas las sesiones
2. **Ejecución de scripts SQL** — todos los `.sql` del directorio `tstsite_exe/` con `psql -v ON_ERROR_STOP=1`
3. **VACUUM FULL + ANALYZE** — sobre todas las tablas de ambos schemas
4. **`pr_optimizador(true, true, true, true)`** — ANALYZE + REINDEX + CLUSTER + terminación de idle

> Las migraciones son idempotentes gracias al uso de `CREATE OR REPLACE` en funciones y procedimientos.

---

## ⚙️ Entornos

| Entorno | Host | Notas |
|---------|------|-------|
| **DEV** | `localhost:5432` | Usuario `postgres` (superuser) disponible |
| **TST** | `postgresql-tstsite.alwaysdata.net:5432` | Solo `tstsite` y `tstsite_exe` |

Zona horaria de sesión: `Europe/Madrid`. DateStyle: `ISO, DMY`.

---

## 🔗 Repositorios relacionados

| Repositorio | Descripción |
|-------------|-------------|
| `TstSiteApi` | Backend REST API — consume las funciones de `tstsite_exe` |
| `TstSiteApp` | Frontend Kotlin Multiplatform |
| `TstSiteDB` | **Este repositorio** — Modelo de datos y lógica PL/pgSQL |

---

## 📄 Licencia

MIT
