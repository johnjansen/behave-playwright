FROM python:3.12-slim

# Install system dependencies for Playwright
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install Allure
RUN wget -O - https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline/2.24.0/allure-commandline-2.24.0.tgz | tar -xzC /opt/ && \
    ln -s /opt/allure-2.24.0/bin/allure /usr/local/bin/allure

# Set working directory
WORKDIR /framework

# Copy and install Python dependencies
COPY docker-build/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN playwright install --with-deps

# Copy framework infrastructure only
COPY docker-build/runner.py .
COPY docker-build/behave.ini .
COPY docker-build/entrypoint.sh /entrypoint.sh

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Create mount points for host test files
VOLUME ["/tests", "/reports"]

# Expose Allure report server port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
