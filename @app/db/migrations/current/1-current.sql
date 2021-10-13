-- Enter migration here
drop FUNCTION app_public.users_check_in_statistics(u app_public.users);

CREATE or replace FUNCTION app_public.users_check_in_statistics(u app_public.users) RETURNS TABLE (
        total_check_ins int,
        unique_check_ins int
)  AS $$
  SELECT count(*) as total_check_ins, count(distinct item_id) as unique_check_ins from app_public.check_ins where author_id = u.id;
$$ LANGUAGE sql STABLE;
