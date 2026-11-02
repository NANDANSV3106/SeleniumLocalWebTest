# Step 1: Use an official Maven image with JDK 17 to build and bundle the app
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the build configuration and source code
COPY pom.xml .
COPY src ./src

# Pre-fetch dependencies to speed up subsequent image builds
RUN mvn dependency:go-offline -B

# Package the application tests without executing them during image compilation
RUN mvn test-compile -B

# Step 2: Use a verified runtime image containing Chrome for headless execution
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# Install stable browser dependencies and download/install official Google Chrome directly
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    libglib2.0-0 \
    libnss3 \
    libgconf-2-4 \
    libfontconfig1 \
    ca-certificates \
    fonts-liberation \
    xdg-utils \
    && wget -q https://google.com \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled classes and target folder from the build stage
COPY --from=build /app/target /app/target

# Set environment variable to target the internal Chrome binary
ENV CHROME_BIN=/usr/bin/google-chrome-stable

# Default command to run the TestNG tests inside the container
CMD ["mvn", "test"]
