create or replace function tstsite_exe.pgp_armor_headers(text, out key text, out value text) returns setof record
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

alter function tstsite_exe.pgp_armor_headers(text, out text, out text) owner to tstsite;

