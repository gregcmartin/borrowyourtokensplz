# Xtate LLM Scanner Docker Build
# Multi-stage build for smaller final image

# Build stage
FROM ubuntu:22.04 AS builder

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libpcap-dev \
    libssl-dev \
    libpcre2-dev \
    libxml2-dev \
    libbson-dev \
    libmongoc-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy source code
COPY . .

# Build the project
RUN ./build.sh

# Verify the build
RUN ./bin/xtate --version && \
    ./bin/xtate --list-probe | grep -q llm-inference

# Runtime stage
FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libpcap0.8 \
    libssl3 \
    libpcre2-8-0 \
    libxml2 \
    libbson-1.0-0 \
    libmongoc-1.0-0 \
    iptables \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /xtate/bin \
    /xtate/data \
    /xtate/results \
    /xtate/firewall \
    /xtate/scripts

# Copy binary and support files from builder
COPY --from=builder /build/bin/xtate /xtate/bin/
COPY --from=builder /build/data/*.conf /xtate/data/
COPY --from=builder /build/data/*.txt /xtate/data/
COPY --from=builder /build/firewall/*.sh /xtate/firewall/
COPY --from=builder /build/scripts/*.sh /xtate/scripts/

# Copy documentation
COPY --from=builder /build/*.md /xtate/

# Set working directory
WORKDIR /xtate

# Make scripts executable
RUN chmod +x /xtate/bin/xtate \
    /xtate/firewall/*.sh \
    /xtate/scripts/*.sh

# Set up firewall rules on container start (optional, may require privileged mode)
# RUN /xtate/firewall/add_rules.sh || true

# Create a non-root user (note: scanning still requires NET_ADMIN capability)
RUN useradd -m -s /bin/bash scanner

# Set proper permissions
RUN chown -R scanner:scanner /xtate

# Expose common ports for documentation (not really needed for scanning OUT)
# EXPOSE 8000 8001 8002 11434 1234 4891

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /xtate/bin/xtate --version || exit 1

# Environment variables
ENV PATH="/xtate/bin:/xtate/scripts:${PATH}"

# Default user (switch to root when running for scanning)
USER scanner

# Default command: show help
CMD ["/xtate/bin/xtate", "--help-probe", "llm-inference"]
