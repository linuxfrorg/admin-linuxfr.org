#!/bin/sh
# Managed by Ansible, do not edit by hand

DATABASE="linuxfr_production"

ids="$(mktemp)"
ids_materialized_path="$(mktemp)"

# Check comments.materialized_path (concatened comments.id)
echo "SELECT id FROM comments ORDER BY id ASC;"|mysql -N $DATABASE  > "$ids"
echo "SELECT comments.materialized_path FROM comments;"|mysql -N $DATABASE|sed 's%.\{12\}%\
&%g'|sed '/^000/s/^0*//;/^ *$/d'|sort -un > "$ids_materialized_path"
diff "$ids" "$ids_materialized_path"
rm "$ids" "$ids_materialized_path"


cat <<EOF | mysql -N $DATABASE
# Check friendly_id_slugs.sluggable_id+sluggable_type
SELECT id, sluggable_id, sluggable_type, 'unknown friendly_id_slugs.sluggable_type' FROM friendly_id_slugs WHERE sluggable_type<>'News' AND sluggable_type<>'Diary' AND sluggable_type<>'Poll' AND sluggable_type<>'Post' AND sluggable_type<>'WikiPage' AND sluggable_type<>'Tracker' AND sluggable_type<>'Section' AND sluggable_type<>'User' AND sluggable_type<>'Forum';
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type News' FROM friendly_id_slugs LEFT JOIN news ON friendly_id_slugs.sluggable_id=news.id WHERE friendly_id_slugs.sluggable_type='News' AND news.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Diary' FROM friendly_id_slugs LEFT JOIN diaries ON friendly_id_slugs.sluggable_id=diaries.id WHERE friendly_id_slugs.sluggable_type='Diary' AND diaries.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Poll' FROM friendly_id_slugs LEFT JOIN polls ON friendly_id_slugs.sluggable_id=polls.id WHERE friendly_id_slugs.sluggable_type='Poll' AND polls.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Post' FROM friendly_id_slugs LEFT JOIN posts ON friendly_id_slugs.sluggable_id=posts.id WHERE friendly_id_slugs.sluggable_type='Post' AND posts.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Wikipage' FROM friendly_id_slugs LEFT JOIN wiki_pages ON friendly_id_slugs.sluggable_id=wiki_pages.id WHERE friendly_id_slugs.sluggable_type='WikiPage' AND wiki_pages.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Tracker' FROM friendly_id_slugs LEFT JOIN trackers ON friendly_id_slugs.sluggable_id=trackers.id WHERE friendly_id_slugs.sluggable_type='Tracker' AND trackers.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Section' FROM friendly_id_slugs LEFT JOIN sections ON friendly_id_slugs.sluggable_id=sections.id WHERE friendly_id_slugs.sluggable_type='Section' AND sections.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type User' FROM friendly_id_slugs LEFT JOIN users ON friendly_id_slugs.sluggable_id=users.id WHERE friendly_id_slugs.sluggable_type='User' AND users.id IS NULL;
SELECT DISTINCT(friendly_id_slugs.sluggable_id), 'unknown friendly_id_slugs type Forum' FROM friendly_id_slugs LEFT JOIN forums ON friendly_id_slugs.sluggable_id=forums.id WHERE friendly_id_slugs.sluggable_type='Forum' AND forums.id IS NULL;

# Check nodes.content_id+content_type
SELECT id, content_id, content_type FROM nodes WHERE content_type<>'News' AND content_type<>'Diary' AND content_type<>'Poll' AND content_type<>'Post' AND content_type<>'Tracker' AND content_type<>'WikiPage';
SELECT DISTINCT(nodes.content_id) FROM nodes LEFT JOIN news ON nodes.content_id=news.id WHERE nodes.content_type='News' AND news.id IS NULL;
SELECT DISTINCT(nodes.content_id) FROM nodes LEFT JOIN diaries ON nodes.content_id=diaries.id WHERE nodes.content_type='Diary' AND diaries.id IS NULL;
SELECT DISTINCT(nodes.content_id) FROM nodes LEFT JOIN polls ON nodes.content_id=polls.id WHERE nodes.content_type='Poll' AND polls.id IS NULL;
SELECT DISTINCT(nodes.content_id) FROM nodes LEFT JOIN posts ON nodes.content_id=posts.id WHERE nodes.content_type='Post' AND posts.id IS NULL;
SELECT DISTINCT(nodes.content_id) FROM nodes LEFT JOIN wiki_pages ON nodes.content_id=wiki_pages.id WHERE nodes.content_type='WikiPage' AND wiki_pages.id IS NULL;
SELECT DISTINCT(nodes.content_id) FROM nodes LEFT JOIN trackers ON nodes.content_id=trackers.id WHERE nodes.content_type='Tracker' AND trackers.id IS NULL;

# Check oauth_access_grants.scopes
SELECT id, resource_owner_id, scopes, 'unknown oauth_access_grants.scopes' FROM oauth_access_grants WHERE scopes<>'account' AND scopes<>'board' AND scopes<>'account board' AND scopes<>'board account';

# Check oauth_access_tokens.scopes
SELECT id, resource_owner_id, scopes, 'unknown oauth_access_grants.tokens' FROM oauth_access_tokens WHERE scopes<>'account' AND scopes<>'board' AND scopes<>'account board' AND scopes<>'board account';

# Check oauth_applications.owner_type
SELECT id, owner_id, owner_type, 'unknown oauth_applications.owner_type' FROM oauth_applications WHERE oauth_applications.owner_type<>'Account';
EOF
