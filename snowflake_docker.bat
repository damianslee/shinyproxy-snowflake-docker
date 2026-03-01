@echo off
rem https://docs.snowflake.com/en/developer-guide/snowpark-container-services/working-with-registry-repository
echo get repository_url via `show image repositories in schema example.images;` and set SNOWFLAKE_ACCOUNT to the sub-domain before .registry.snowflakecomputing.com
set SNOWFLAKE_ACCOUNT=comuiwg-va94379
set SNOWFLAKE_USER=image_publisher
set SNOWFLAKE_PASSWORD=<yourpat>

echo %SNOWFLAKE_PASSWORD% | docker login %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com --username %SNOWFLAKE_USER% --password-stdin

docker pull --platform linux/amd64 openanalytics/shinyproxy-integration-test-app:latest
docker tag openanalytics/shinyproxy-integration-test-app:latest %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/shinyproxy-integration-test-app:latest
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/shinyproxy-integration-test-app:latest

docker pull --platform linux/amd64 linuxserver/code-server:latest
docker tag linuxserver/code-server:latest %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/code-server:latest
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/code-server:latest

docker pull --platform linux/amd64 mendhak/http-https-echo:latest
docker tag mendhak/http-https-echo:latest %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/http-https-echo:latest
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/http-https-echo:latest

docker pull --platform linux/amd64 tsl0922/ttyd:alpine
docker tag tsl0922/ttyd:alpine %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/ttyd:latest
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/ttyd:latest

docker build --platform linux/amd64 -t %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/rstudio:latest ./RStudio
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/rstudio:latest

docker build --platform linux/amd64 -t %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/shinyproxy:latest ./ShinyProxy
docker push %SNOWFLAKE_ACCOUNT%.registry.snowflakecomputing.com/example/images/repository/shinyproxy:latest

