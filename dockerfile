# Step 1: Use a verified Maven image with JDK 17 to bundle the application
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the build configuration first so Maven can cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and compile the project
COPY src ./src
RUN mvn test-compile -B

# Step 2: Use a verified runtime image containing Chrome for headless execution
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# Install stable browser dependencies and Google Chrome (stable)
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    unzip \
    libglib2.0-0 \
    libnss3 \
    libgconf-2-4 \
    libfontconfig1 \
    ca-certificates \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://google.com | gpg --dearmor -o /usr/share/keyrings/google-linux-signing-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://google.com stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Copy only the built application assets from the build stage
COPY --from=build /app/target /app/target

# Set the environment variable to target the newly installed Google Chrome binary
ENV CHROME_BIN=/usr/bin/google-chrome-stable

# Default command to run the TestNG tests inside the container environment
CMD ["mvn", "test"]