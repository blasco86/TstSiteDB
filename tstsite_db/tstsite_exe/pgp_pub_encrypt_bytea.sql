create or replace function tstsite_exe.pgp_pub_encrypt_bytea(bytea, bytea) returns bytea
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

alter function tstsite_exe.pgp_pub_encrypt_bytea(bytea, bytea) owner to tstsite;

create or replace function tstsite_exe.pgp_pub_encrypt_bytea(bytea, bytea, text) returns bytea
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

alter function tstsite_exe.pgp_pub_encrypt_bytea(bytea, bytea, text) owner to tstsite;

