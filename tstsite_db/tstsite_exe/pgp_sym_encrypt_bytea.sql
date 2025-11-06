create or replace function tstsite_exe.pgp_sym_encrypt_bytea(bytea, text) returns bytea
    strict
    security definer
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function tstsite_exe.pgp_sym_encrypt_bytea(bytea, text) owner to tstsite;

create or replace function tstsite_exe.pgp_sym_encrypt_bytea(bytea, text, text) returns bytea
    strict
    security definer
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function tstsite_exe.pgp_sym_encrypt_bytea(bytea, text, text) owner to tstsite;

