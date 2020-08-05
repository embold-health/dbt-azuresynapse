{% macro azuresynapse__get_catalog(information_schema, schemas) -%}
    {%- call statement('catalog', fetch_result=True) -%}
        {% set database = information_schema.database %}
            with tables as (
                select
                    table_catalog as "table_database",
                    table_schema as "table_schema",
                    table_name as "table_name",
                    case when table_type = 'BASE TABLE' then 'table'
                        when table_type = 'VIEW' then 'view'
                        else table_type
                    end as table_type
                from {{ database }}.information_schema.tables
                where (
                    {%- for schema in schemas -%}
                    upper(table_schema) = upper('{{ schema }}'){%- if not loop.last %} or {% endif -%}
                    {%- endfor -%}
                )
            ),
            columns as (
                select
                    table_catalog as "table_database",
                    table_schema as "table_schema",
                    table_name as "table_name",
                    column_name as "column_name",
                    ordinal_position as "column_index",
                    data_type as "column_type",
                    null as "column_comment"
                from {{ database }}.information_schema.columns
            )
            select DISTINCT t.table_database, t.table_schema, t.table_name, t.table_type, '' as table_comment, c.column_name, c.column_index, c.column_type, '' as column_comment
            from tables t
            join columns c on t.table_database = c.table_database and t.table_schema = c.table_schema and t.table_name = c.table_name
            order by "column_index"
  {%- endcall -%}
  {{ return(load_result('catalog').table) }}
{%- endmacro %}