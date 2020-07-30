from dbt.adapters.azuresynapse.connections import AzureSynapseConnectionManager  # noqa
from dbt.adapters.azuresynapse.connections import AzureSynapseCredentials
from dbt.adapters.azuresynapse.impl import AzureSynapseAdapter
from dbt.adapters.base import AdapterPlugin
from dbt.include import azuresynapse


Plugin = AdapterPlugin(
    adapter=AzureSynapseAdapter,
    credentials=AzureSynapseCredentials,
    include_path=azuresynapse.PACKAGE_PATH,
)
