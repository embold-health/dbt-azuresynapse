# dbt-azuresynapse

[dbt](https://www.getdbt.com/) with some [Azure Synapse](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/) goodness

## Install
```
pip install dbt-azuresynapse
```

## Requirements
* \>= Python 3.6.3
* dbt 0.17.1

## Sample profiles.yml
```yaml
default:
  target: dev
  outputs:
    dev:
      type: azuresynapse
      server: myazuresynapseserver.database.windows.net
      schema: <schema>
      username: <username>
      password: <password>
      driver: ODBC Driver 17 for SQL Server
      authentication: SqlPassword
      database: <database-name>

```

## Important Notes
This adapter runs in autocommit mode (every query is committed when executed), so transactions are not supported.  
This is due to the fact that most DDL operations (CREATE TABLE, etc) in Azure Synapse do not work inside transactions.  
It is theoretically possible to wrap every DDL operation and temporarily enable autocommit mode and then disable when done, but this would be a huge effort.


## Development
The included Dockerfile and docker-compose.yml should provide a quick development environment. `dbt-integration-tests` are included as a submodule

* Clone the repo `git clone --recurse-submodules git@github.com:embold-health/dbt-azuresynapse.git`
    * If you've already cloned without the submodule, run `git submodule init && git submodule update`
* Run `pre-commit install`. This will install git hooks that handle formatting on commit.
* Setup profiles.yml in the top-level of the directory
* Run `docker-compose build`
* `docker-compose run dbt /bin/bash` will get you a shell into the container
    * `profiles.yml` is mounted to `/root/.dbt/profiles.yml`
    * `dbt-integration-tests` is mounted to `/tests`
    * `dbt` is mounted to `/src/dbt`
    * The adapter is installed in develop mode, so any changes should immediately take effect
* To run the tests inside the container shell
    * `cd /tests`
    * `behave -f progress3 --stop -D 'profile_name='"default"`
