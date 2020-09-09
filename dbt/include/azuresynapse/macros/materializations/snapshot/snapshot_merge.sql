{% macro azuresynapse__snapshot_merge_sql(target, source, insert_cols) -%}
    {# insert_cols is an empty list because tempdb is inaccessible in Synapse #}
    {%- if insert_cols | length == 0 -%}
      {% set insert_columns = adapter.get_columns_in_relation(target)
                                | rejectattr('name', 'equalto', 'dbt_change_type')
                                | rejectattr('name', 'equalto', 'DBT_CHANGE_TYPE')
                                | rejectattr('name', 'equalto', 'dbt_unique_key')
                                | rejectattr('name', 'equalto', 'DBT_UNIQUE_KEY')
                                | list %}

      {% for column in insert_columns %}
        {% do insert_cols.append(adapter.quote(column.name)) %}
      {% endfor %}
    {%- endif -%}

   {{ log("Running Azure Snapshot merge  Macro"~insert_cols) }}
   {%- set insert_cols_csv = insert_cols | join(', ') -%}

    update {{ target }}
    set dbt_valid_to = DBT_INTERNAL_SOURCE.dbt_valid_to
    from {{ source }} as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_scd_id = {{ target }}.dbt_scd_id
      and DBT_INTERNAL_SOURCE.dbt_change_type = 'update'
      and {{ target }}.dbt_valid_to is null;

    insert into {{ target }} ({{ insert_cols_csv }})
    select {% for column in insert_cols -%}
        DBT_INTERNAL_SOURCE.{{ column }} {%- if not loop.last %}, {%- endif %}
    {%- endfor %}
    from {{ source }} as DBT_INTERNAL_SOURCE
    where DBT_INTERNAL_SOURCE.dbt_change_type = 'insert';
{% endmacro %}
