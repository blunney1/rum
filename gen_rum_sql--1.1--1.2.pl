use strict;
use warnings;

my $func_distance_template=<<EOT;
CREATE FUNCTION rum_TYPEIDENT_key_distance(internal,smallint,TYPENAME,smallint,tsvector,int,internal,internal,internal,internal,internal,internal)
RETURNS float8
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

EOT

my $opclass_distance_template=<<EOT;

ALTER OPERATOR FAMILY rum_TYPEIDENT_ops USING rum ADD
	FUNCTION	8	(TYPENAME,TYPENAME) rum_TYPEIDENT_key_distance(internal,smallint,TYPENAME,smallint,tsvector,int,internal,internal,internal,internal,internal,internal);

EOT

my @opinfo = map {
		$_->{TYPEIDENT}   = $_->{TYPENAME} if !exists $_->{TYPEIDENT};
		$_
	} (
	{
		TYPENAME	=>	'int2',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
	{
		TYPENAME	=>	'int4',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
	{
		TYPENAME	=>	'int8',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
	{
		TYPENAME	=>	'float4',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
	{
		TYPENAME	=>	'float8',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
	{
		TYPENAME	=>	'money',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
	{
		TYPENAME	=>	'oid',
		func_tmpl	=>	\$func_distance_template,
		opclass_tmpl=>	\$opclass_distance_template,
	},
);

##############Generate!!!

print <<EOT;
/*
 * RUM version 1.2
 */

DROP OPERATOR CLASS rum_tsvector_ops USING rum;
DROP OPERATOR CLASS rum_tsvector_hash_ops USING rum;

CREATE OR REPLACE FUNCTION rum_tsquery_distance(internal,smallint,internal,smallint,tsvector,int,internal,internal,internal,internal,internal,internal)
RETURNS float8
AS 'MODULE_PATHNAME'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS rum_tsvector_ops
DEFAULT FOR TYPE tsvector USING rum
AS
        OPERATOR        1       @@ (tsvector, tsquery),
        OPERATOR        2       <=> (tsvector, tsquery) FOR ORDER BY pg_catalog.float_ops,
        FUNCTION        1       gin_cmp_tslexeme(text, text),
        FUNCTION        2       rum_extract_tsvector(tsvector,internal,internal,internal,internal),
        FUNCTION        3       rum_extract_tsquery(tsquery,internal,smallint,internal,internal,internal,internal),
        FUNCTION        4       rum_tsquery_consistent(internal,smallint,tsvector,int,internal,internal,internal,internal),
        FUNCTION        5       gin_cmp_prefix(text,text,smallint,internal),
        FUNCTION        6       rum_tsvector_config(internal),
        FUNCTION        7       rum_tsquery_pre_consistent(internal,smallint,tsvector,int,internal,internal,internal,internal),
        FUNCTION        8       rum_tsquery_distance(internal,smallint,internal,smallint,tsvector,int,internal,internal,internal,internal,internal,internal),
        FUNCTION        10      rum_ts_join_pos(internal, internal),
        STORAGE         text;

CREATE OPERATOR CLASS rum_tsvector_hash_ops
FOR TYPE tsvector USING rum
AS
        OPERATOR        1       @@ (tsvector, tsquery),
        OPERATOR        2       <=> (tsvector, tsquery) FOR ORDER BY pg_catalog.float_ops,
        FUNCTION        1       btint4cmp(integer, integer),
        FUNCTION        2       rum_extract_tsvector_hash(tsvector,internal,internal,internal,internal),
        FUNCTION        3       rum_extract_tsquery_hash(tsquery,internal,smallint,internal,internal,internal,internal),
        FUNCTION        4       rum_tsquery_consistent(internal,smallint,tsvector,int,internal,internal,internal,internal),
        FUNCTION        6       rum_tsvector_config(internal),
        FUNCTION        7       rum_tsquery_pre_consistent(internal,smallint,tsvector,int,internal,internal,internal,internal),
        FUNCTION        8       rum_tsquery_distance(internal,smallint,internal,smallint,tsvector,int,internal,internal,internal,internal,internal,internal),
        FUNCTION        10      rum_ts_join_pos(internal, internal),
        STORAGE         integer;

EOT

foreach my $t (@opinfo)
{
	print	"/*--------------------$t->{TYPENAME}-----------------------*/\n\n";

	for my $v (qw(func_tmpl opclass_tmpl))
	{
		next if !exists $t->{$v};

		my $x = ${$t->{$v}};

		for my $k (grep {uc($_) eq $_} keys %$t)
		{
			$x=~s/$k/$t->{$k}/g;
		}

		print $x;
	}
}
