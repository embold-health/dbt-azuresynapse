from dbt.adapters.azuresynapse import AzureSynapseConnectionManager
from dbt.adapters.sql import SQLAdapter


class AzureSynapseAdapter(SQLAdapter):
    ConnectionManager = AzureSynapseConnectionManager

    @classmethod
    def date_function(cls):
        return "get_date()"

    @classmethod
    def convert_text_type(cls, agate_table, col_idx):
        return "varchar(8000)"
