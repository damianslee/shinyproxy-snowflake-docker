# ShinyProxy Docker files

This repository contains the Dockerfiles of the Docker images of the
ShinyProxy with support for Snowflake SnowPark Container Services backend.
This allows you to inspect how our images are build and to
build your own image.

## ShinyProxy for SPCS

The Dockerfile for ShinyProxy on SPCS can be found in the
[ShinyProxy directory](ShinyProxy/Dockerfile). The same Dockerfile is used for building
development, snapshot and production images.


### Locally building a development release

This section describes how to build a Dockerfile of ShinyProxy using a local JAR
file of ShinyProxy.

1. build ContainerProxy + ShinyProxy

    ```bash
    git clone -b develop https://github.com/damianslee/containerproxy/ ContainerProxy
    git clone -b develop https://github.com/openanalytics/shinyproxy/ ShinyProxy
    pushd ContainerProxy
    mvn package install  -DskipTests
    popd
    pushd ShinyProxy
    mvn -U clean package install  -DskipTests
    popd
    ```

2. copy the JAR to the location of this repository

    ```bash
    git clone https://github.com/openanalytics/shinyproxy-docker/ docker
    cd docker/ShinyProxy
    cp ../../ShinyProxy/target/shinyproxy*.jar .
    ```

3. build the docker image

    ```bash
    docker build  --platform linux/amd64 -t shinyproxy-dev --build-arg JAR_LOCATION=shinyproxy-*.jar .
    ```

### Building latest snapshot version (once SPCS backend is merged)

You can also build a Docker image of ShinyProxy using the official snapshot
builds of ShinyProxy. In that case Docker downloads the required JAR file from
our Nexus server. The version information contained in the JAR file always ends
with `-SNAPSHOT`. Official builds of this image are available at 
[Docker Hub](https://hub.docker.com/r/openanalytics/shinyproxy-snapshot).

```bash
git clone https://github.com/openanalytics/shinyproxy-docker/ docker
cd docker/ShinyProxy
docker build --build-arg NEXUS_REPOSITORY=snapshots -t shinyproxy-snapshot .
```

### Building latest release version (once SPCS backend is merged)

Finally, you can build a Docker image of ShinyProxy using the official release
versions of ShinyProxy. Similar to the snapshot version, Docker downloads the
required JAR file from our Nexus server. The version information contained in
the JAR file does not have a suffix, indicating a release build. Official builds
of this image are available at 
[Docker Hub](https://hub.docker.com/r/openanalytics/shinyproxy).

```bash
git clone https://github.com/openanalytics/shinyproxy-docker/ docker
cd docker/ShinyProxy
docker build --build-arg NEXUS_REPOSITORY=releases -t shinyproxy .
```

The JAR file will be downloaded from our Nexus server.
