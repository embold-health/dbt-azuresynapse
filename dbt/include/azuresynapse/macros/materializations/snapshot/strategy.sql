{% macro azuresynapse__snapshot_check_strategy(node, snapshotted_rel, current_rel, config, target_exists) %}
    {% set check_cols_config = config['check_cols'] %}
    {% set primary_key = config['unique_key'] %}
    {% set select_current_time -%}
        select {{ snapshot_get_time() }} as snapshot_start
    {%- endset %}

    {#-- don't access the column by name, to avoid dealing with casing issues on snowflake #}
    {%- set now = run_query(select_current_time)[0][0] -%}
    {% if now is none or now is undefined -%}
        {%- do exceptions.raise_compiler_error('Could not get a snapshot start time from the database') -%}
    {%- endif %}
    {% set updated_at = snapshot_string_as_time(now) %}

    {% set column_added = false %}

    {% if check_cols_config == 'all' %}
        {% set column_added, check_cols = snapshot_check_all_get_existing_columns(node, target_exists) %}
    {% elif check_cols_config is iterable and (check_cols_config | length) > 0 %}
        {% set check_cols = check_cols_config %}
    {% else %}
        {% do exceptions.raise_compiler_error("Invalid value for 'check_cols': " ~ check_cols_config) %}
    {% endif %}

    {%- set row_changed_expr -%}
    (
    {%- if column_added -%}
        TRUE
    {%- else -%}
    {% for col in check_cols %}
        {{ snapshotted_rel }}.{{ col }} != {{ current_rel }}.{{ col }}
        or
        ({{ snapshotted_rel }}.{{ col }} is null) and not ({{ current_rel }}.{{ col }} is null)
        {%- if not loop.last %} or {% endif %}
    {% endfor %}
    {%- endif -%}
    )
    {%- endset %}

    {% set scd_id_expr = snapshot_hash_arguments([primary_key, updated_at]) %}

    {% do return({
        "unique_key": primary_key,
        "updated_at": updated_at,
        "row_changed": row_changed_expr,
        "scd_id": scd_id_expr
    }) %}
{% endmacro %}