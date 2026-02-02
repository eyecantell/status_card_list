# Development Dockerfile for Flutter
# For use with VS Code Remote Development

FROM ubuntu:24.04 AS base

# Prevent apt from prompting for input
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages and Chrome dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    npm \
    sudo \
    tree \
    unzip \
    vim \
    wget \
    xz-utils \
    # Chrome dependencies
    fonts-liberation \
    libasound2t64 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome for web testing
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Create the developer user and set up permissions
RUN useradd -s /bin/bash -m developer && \
    usermod -aG sudo developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add claude code globally
RUN npm install -g @anthropic-ai/claude-code

# Install TypeScript/JavaScript LSP (useful for any JS/TS in project)
RUN npm install -g @vtsls/language-server typescript

# Install Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME} && \
    chown -R developer:developer ${FLUTTER_HOME}

# Switch to developer user for remaining operations
USER developer

# Pre-cache Flutter dependencies and enable web
RUN flutter precache && \
    flutter config --enable-web && \
    flutter doctor

# Create symlink for Dart language server so Claude Code LSP can find it
# The Dart SDK ships with Flutter and includes the language server
RUN sudo ln -s ${FLUTTER_HOME}/bin/cache/dart-sdk/bin/dart /usr/local/bin/dart

# Set Chrome executable path for Flutter
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome

WORKDIR /mounted/dev/status_card_list

RUN git config --global --add safe.directory /mounted/dev/status_card_list
RUN git config --global --add safe.directory /opt/flutter

RUN echo "alias upc='sudo npm i -g @anthropic-ai/claude-code'" >> /home/developer/.bash_aliases
