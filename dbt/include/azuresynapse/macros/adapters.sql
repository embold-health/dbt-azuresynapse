{% macro azuresynapse__list_schemas(database) %}
    {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}
        select distinct schema_name
        from {{ database }}.information_schema.schemata
    {%- endcall %}

    {{ return(load_result('list_schemas').table) }}
{% endmacro %}

{% macro azuresynapse__create_schema(relation) %}
    {% call statement('create_schema') -%}
        create schema {{ relation.schema }}
    {%- endcall %}
{% endmacro %}

{% macro azuresynapse__drop_relation(relation) -%}
    {% call statement('drop_relation', auto_begin=False) -%}
        if object_id('{{ relation.schema }}.{{ relation.identifier }}') is not null
	        drop {{ relation.type }} {{ relation.schema }}.{{ relation.identifier }}
    {%- endcall %}
{% endmacro %}

{% macro azuresynapse__truncate_relation(relation) -%}
    {% call statement('truncate_relation') -%}
        truncate table {{ relation }}
    {%- endcall %}
{% endmacro %}

{% macro azuresynapse__check_schema_exists(information_schema, schema) -%}
  {% call statement('check_schema_exists', fetch_result=True, auto_begin=False) -%}
    --use {{ database_name }}
    select count(*) as schema_exist from sys.schemas where name = '{{ schema }}'
  {%- endcall %}
  {{ return(load_result('check_schema_exists').table) }}
{% endmacro %}

{% macro azuresynapse__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      table_catalog as [database],
      table_name as [name],
      table_schema as [schema],
      case when table_type = 'BASE TABLE' then 'table'
           when table_type = 'VIEW' then 'view'
           else table_type
      end as table_type
    from information_schema.tables
    where table_schema = '{{ schema_relation.schema }}'
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro azuresynapse__make_temp_relation(base_relation, suffix) %}
    {% set tmp_identifier = '#' ~ base_relation.identifier ~ suffix ~ py_current_timestring() %}
    {% do return(base_relation.incorporate(
                                path={
                                    "identifier": tmp_identifier,
                                    "schema": none,
                                    "database": none
                                })) -%}
{% endmacro %}

{% macro azuresynapse__create_table_as(temporary, relation, sql) -%}
{%- set distribution = config.get('distribution') -%}
  create table
    {{ relation.include(database=(not temporary), schema=(not temporary)) }}
  with(
    clustered columnstore index,
    {%- if temporary: -%}
    distribution =  round_robin
    {%- else -%}
    distribution = {% if distribution: -%}{{ distribution }}{%- else %} round_robin {%- endif %}
    {%- endif %}
  )
  as
    {{ sql }}

{% endmacro %}

{% macro azuresynapse__create_view_as(relation, sql, auto_begin=False) -%}
  create view {{ relation.schema }}.{{ relation.identifier }} as (
    {{ sql }}
  );
{% endmacro %}

{% macro azuresynapse__rename_relation(from_relation, to_relation) -%}
  {% call statement('rename_relation') -%}
    rename object {{ from_relation.schema }}.{{ from_relation.identifier }} to {{ to_relation.identifier }}
  {%- endcall %}
{% endmacro %}

{% macro azuresynapse__get_columns_in_relation(relation) -%}
    {% call statement('get_columns_in_relation', fetch_result=True) %}
        select
            column_name
            , data_type
            , character_maximum_length
            , numeric_precision
            , numeric_scale
        from
            information_schema.columns
        where
            table_catalog    = '{{ relation.database }}'
            and table_schema = '{{ relation.schema }}'
            and table_name   = '{{ relation.identifier }}'
    {% endcall %}

    {% set table = load_result('get_columns_in_relation').table %}
    {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro azuresynapse__load_csv_rows(model, agate_table) %}
    {% set cols_sql = ", ".join(agate_table.column_names) %}
    {% set bindings = [] %}

    {% set statements = [] %}

    {% for chunk in agate_table.rows | batch(batch_size) %}
        {% set bindings = [] %}

        {% for row in chunk %}
            {% set _ = bindings.extend(row) %}
        {% endfor %}

        {% set sql %}
            insert into {{ this.render() }} ({{ cols_sql }})
            {% for row in chunk %}
                SELECT
                {% for column in agate_table.column_names %}
                    ?
                    {%- if not loop.last%},{%- endif %}
                {% endfor %}
                {%- if not loop.last%} UNION ALL {%- endif %}
            {% endfor %}
        {% endset %}

        {% set _ = adapter.add_query(sql, bindings=bindings, abridge_sql_log=True) %}

        {% if loop.index0 == 0 %}
            {% set _ = statements.append(sql) %}
        {% endif %}
    {% endfor %}

    {# Return SQL so we can render it out into the compiled files #}
    {{ return(statements[0]) }}
{% endmacro %}

{% macro azuresynapse__current_timestamp() -%}
  GETDATE()
{%- endmacro %}

{% macro azuresynapse__snapshot_string_as_time(timestamp) -%}
    {%- set result = "CAST('" ~ timestamp ~ "' AS DATETIME)" -%}
    {{ return(result) }}
{%- endmacro %}

{% macro azuresynapse__snapshot_hash_arguments(args) -%}
  HASHBYTES ('md5', concat({%- for arg in args -%}
    coalesce(cast({{ arg }} as VARCHAR), ''){% if not loop.last %}, '|',{% endif -%}
  {%- endfor -%}
  ))
{%- endmacro %}
