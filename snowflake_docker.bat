@echo off
rem https://docs.snowflake.com/en/developer-guide/snowpark-container-services/working-with-registry-repository
echo get repository_url via `show image repositories in schema example.image;` and set SNOWFLAKE_ACCOUNT to the sub-domain before .registry.snowflakecomputing.com
set SNOWFLAKE_ACCOUNT=<orgname>-<account name>
set SNOWFLAKE_USER=image_publisher
set SNOWFLAKE_PASSWORD=<yourpat>

echo %SNOWFLAKE_PASSWORD% | docker login %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com --username %SNOWFLAKE_USER% --password-stdin

docker pull --platform linux/amd64 openanalytics/shinyproxy-integration-test-app:latest
docker tag openanalytics/shinyproxy-integration-test-app:latest %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/shinyproxy-integration-test-app:latest
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/shinyproxy-integration-test-app:latest

docker build --platform linux/amd64 -t %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/code-server:latest ./CodeServer
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/code-server:latest

docker pull --platform linux/amd64 mendhak/http-https-echo:latest
docker tag mendhak/http-https-echo:latest %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/http-https-echo:latest
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/http-https-echo:latest

docker build --platform linux/amd64 -t %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/snowshell:latest ./SnowShell
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/snowshell:latest

docker build --platform linux/amd64 -t %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/rstudio:latest ./RStudio
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/rstudio:latest

rem download shinyproxy jar from github releases of this repo
docker build --platform linux/amd64 -t %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/shinyproxy:latest ./ShinyProxy
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/image/repository/shinyproxy:latest

