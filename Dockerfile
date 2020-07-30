FROM python:3.7-slim-stretch

# Install general dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    g++ \
    gcc \
    git \
    gnupg2 \
    libssl1.1 \
    unixodbc-dev
RUN pip install -U pip
RUN pip uninstall jinja2 && pip install jinja2

# Install Sql Server driver dependencies
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && \
    ACCEPT_EULA=Y apt-get install msodbcsql17=17.5.2.1-1 -y
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

WORKDIR /src
COPY setup.py /src
COPY dbt /src/dbt
RUN pip install -e .
