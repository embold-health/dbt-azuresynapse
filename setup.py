#!/usr/bin/env python
from distutils.core import setup

from setuptools import find_packages

try:
    import setuptools_scm

    version = setuptools_scm.get_version()
except Exception:
    import warnings

    warnings.warn(f"could not determine {__name__} package version")
    version = "0.0.0"

package_name = "dbt-azuresynapse"
python_min_version = "3.6.3"
description = """The azuresynapse adapter plugin for dbt (data build tool)"""

setup(
    name=package_name,
    description=description,
    long_description=description,
    version=version,
    author="Embold Health",
    author_email="techteam@emboldhealth.com",
    url="https://github.com/embold-health/dbt-azuresynapse",
    packages=find_packages(exclude=["dbt-integration-tests"]),
    package_data={
        "dbt": [
            "include/azuresynapse/dbt_project.yml",
            "include/azuresynapse/macros/*.sql",
        ]
    },
    install_requires=["dbt-core==0.17.1", "pyodbc==4.0.30"],
    python_requires=">{}".format(python_min_version),
)
