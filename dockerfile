# =========================================================================
# Step 1: Use a verified Maven image with Temurin JDK 17 to compile the app
# =========================================================================
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the build configuration first to maximize layer caching efficiency
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy the complete application source code and compile the tests
COPY src ./src
RUN mvn test-compile -B

# =========================================================================
# Step 2: Use an official Temurin JRE runtime layer to set up Chrome
# =========================================================================
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# Install baseline Linux browser dependencies and the official stable Google Chrome
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

# Extract the fully built target folder containing compiled classes from Step 1
COPY --from=build /app /app

# Point the binary configuration explicitly to the newly added Google Chrome binary
ENV CHROME_BIN=/usr/bin/google-chrome-stable

# Default execution trigger to fire up the automated test lifecycle inside the container
CMD ["mvn", "test"]
