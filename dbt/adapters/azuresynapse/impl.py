import agate
from dbt.adapters.azuresynapse import AzureSynapseConnectionManager
from dbt.adapters.sql import SQLAdapter


class AzureSynapseAdapter(SQLAdapter):
    ConnectionManager = AzureSynapseConnectionManager

    @classmethod
    def date_function(cls) -> str:
        return "get_date()"

    @classmethod
    def convert_text_type(cls, agate_table: agate.Table, col_idx: int) -> str:
        return "varchar(8000)"

    @classmethod
    def convert_number_type(cls, agate_table: agate.Table, col_idx: int) -> str:
        decimals = agate_table.aggregate(agate.MaxPrecision(col_idx))
        return "float" if decimals else "integer"