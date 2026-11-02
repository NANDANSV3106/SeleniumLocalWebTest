FROM selenium/standalone-chrome:4.8.3-20230328 AS base

USER root

# Install Maven dependency components cleanly
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the build configuration file and test suite XML file
COPY pom.xml .
COPY testng.xml .

# Copy your source code and the correct local HTML web page directory
COPY src/ ./src/
COPY webpage/ ./webpage/

# Default execution entrypoint command
CMD ["mvn", "clean", "test", "-DsuiteXmlFile=testng.xml"]
