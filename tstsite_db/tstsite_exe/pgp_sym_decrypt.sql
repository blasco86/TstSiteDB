create or replace function tstsite_exe.pgp_sym_decrypt(bytea, text) returns text
    immutable
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

alter function tstsite_exe.pgp_sym_decrypt(bytea, text) owner to tstsite;

create or replace function tstsite_exe.pgp_sym_decrypt(bytea, text, text) returns text
    immutable
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

alter function tstsite_exe.pgp_sym_decrypt(bytea, text, text) owner to tstsite;

