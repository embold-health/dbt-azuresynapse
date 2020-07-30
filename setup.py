#!/usr/bin/env python
from distutils.core import setup

from setuptools import find_packages

package_name = "dbt-azuresynapse"
package_version = "0.0.1"
description = """The azuresynapse adapter plugin for dbt (data build tool)"""
python_min_version = "3.6.3"

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    author="Embold Health",
    author_email="techteam@emboldhealth.com",
    url="https://www.emboldhealth.com",
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
