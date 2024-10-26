create table todo (
    parent_id int,
    id int,
    done int
);

insert into todo(parent_id, id, done)
values (0, 1, 0)
,(1, 2, 0)
,(1, 3, 1)
,(2, 4, 1)
,(2, 5, 0)
,(2, 6, 1)
,(5, 7, 1)
,(5, 8, 0)
;

-- The number of incomplete child nodes of its parent node with id 8
with recursive p as (
    select id, parent_id from todo where id = 8
    union all
    select t.id, t.parent_id from todo as t join p on p.parent_id = t.id
) select p.id
      -- p.parent_id
       , count(d.done) - sum(d.done) as incomplete
       , group_concat(d.id) as children
       , group_concat(d.done) as done_of_children
from p
join todo as d on p.id = d.parent_id
group by p.id;


--- ??? How to update the nodes
--- All child nodes are complete, return 1, otherwise return 0
--- Because of the current node state change, it may cause the parent state change
--- so should be updated during iteration
with recursive p as (
    select id, parent_id from todo where id = 8
    union all
    select t.id, t.parent_id from todo as t join p on p.parent_id = t.id
    ???
) select * from p;


---
with p as \(
    select tag.id as id from category
    join tag on category.id = tag.category_id
    where category.name = '' and tag.name = 'trash'
\), x as \(
    select d.parent_id, d.id,
    case t.tag_id in \(p.id\) when true then 0 else 1 end as c
    from p, todo as d
    join todo_tag as t on d.id = t.todo_id
    where d.parent_id = ($p) and d.done = 0
    group by d.id, d.done
\) select sum\(c\) as c from x;
