# Docker Usage Guide

This document describes how to build and run the Xtate LLM Scanner using Docker.

## Quick Start

### Build the Image

```bash
docker-compose build
```

Or using docker directly:
```bash
docker build -t xtate-llm-scanner .
```

### Run a Scan

Using docker-compose:
```bash
docker-compose run --rm xtate-scan 192.168.1.0/24
```

Using docker directly:
```bash
docker run --rm --net=host --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -v $(pwd)/results:/xtate/results \
  xtate-llm-scanner \
  /xtate/scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

## Usage Modes

### Interactive Shell

Start a container with a shell for manual commands:

```bash
docker-compose run --rm xtate-scanner
```

Inside the container:
```bash
# List probe modules
xtate --list-probe | grep llm

# Run a scan
./scripts/scan-llm-services.sh -ip 10.0.0.0/24

# Or use xtate directly
xtate -ip 192.168.1.0/24 -p 11434 -scan zbanner -probe llm-inference
```

### One-Shot Scans

Run a scan and exit:

```bash
# Scan local network
docker-compose run --rm xtate-scan 192.168.1.0/24

# Scan with custom ports
docker-compose run --rm xtate-scanner \
  xtate -ip 10.0.0.0/16 -p 8000,11434 -scan zbanner -probe llm-inference

# Aggressive scan
docker-compose run --rm xtate-scanner \
  /xtate/scripts/scan-llm-services.sh -ip 172.16.0.0/12 --aggressive
```

### Persistent Container

Keep a container running for multiple scans:

```bash
# Start container
docker-compose up -d xtate-scanner

# Execute scans
docker exec -it xtate-scanner ./scripts/scan-llm-services.sh -ip 192.168.1.0/24

# Access shell
docker exec -it xtate-scanner bash

# Stop container
docker-compose down
```

## Requirements

### Network Mode

The scanner requires `host` network mode for raw packet access:

```yaml
network_mode: host
```

This means the container shares the host's network stack.

### Capabilities

The following Linux capabilities are required:

- `NET_ADMIN` - For network configuration
- `NET_RAW` - For raw socket access

```yaml
cap_add:
  - NET_ADMIN
  - NET_RAW
```

### Root Access

Scanning requires root privileges. The container runs as root by default:

```yaml
user: root
```

## Volume Mounts

### Results Directory

Mount the results directory to persist scan output:

```bash
-v $(pwd)/results:/xtate/results
```

Results will be saved to `./results/` on your host.

### Configuration Files

Mount custom configuration files:

```bash
-v $(pwd)/my-config.conf:/xtate/data/llm-scan.conf:ro
```

### Custom Targets

Mount a targets file:

```bash
-v $(pwd)/targets.txt:/xtate/targets.txt:ro
```

Then scan:
```bash
xtate -ip-file /xtate/targets.txt -scan zbanner -probe llm-inference
```

## Docker Compose Examples

### Basic Configuration

```yaml
services:
  xtate-scanner:
    image: xtate-llm-scanner:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./results:/xtate/results
    user: root
```

### With Custom Config

```yaml
services:
  xtate-custom:
    image: xtate-llm-scanner:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./results:/xtate/results
      - ./my-scan.conf:/xtate/data/llm-scan.conf:ro
    user: root
    command: xtate -c /xtate/data/llm-scan.conf -ip 10.0.0.0/16
```

### Environment Variables

```yaml
services:
  xtate-scanner:
    image: xtate-llm-scanner:latest
    environment:
      - SCAN_RATE=50000
      - RESULTS_DIR=/xtate/results
    # ... rest of config
```

## Building Custom Images

### With Additional Tools

Create a custom Dockerfile:

```dockerfile
FROM xtate-llm-scanner:latest

USER root

# Install additional tools
RUN apt-get update && apt-get install -y \
    jq \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

USER scanner
```

Build:
```bash
docker build -f Dockerfile.custom -t xtate-llm-scanner:custom .
```

### Development Build

For development with debug symbols:

```dockerfile
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential cmake git \
    libpcap-dev libssl-dev libpcre2-dev libxml2-dev

WORKDIR /build
COPY . .

# Debug build
RUN ./build.sh debug

# Copy debug binary
RUN cp ./bin/xtate_debug /xtate/bin/xtate_debug
```

## Troubleshooting

### Permission Denied

Ensure the container runs as root and has the required capabilities:

```bash
docker run --rm --net=host --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --user root \
  xtate-llm-scanner xtate --version
```

### Network Issues

If host network mode doesn't work:

1. Try privileged mode (less secure):
   ```yaml
   privileged: true
   ```

2. Check host firewall settings

3. Verify Docker has network access

### No Results

1. Check results directory is writable:
   ```bash
   ls -la ./results
   ```

2. Increase wait time:
   ```bash
   docker-compose run --rm xtate-scanner \
     xtate -ip 192.168.1.0/24 -p 11434 -scan zbanner -probe llm-inference -wait 30
   ```

3. Try verbose output:
   ```bash
   docker-compose run --rm xtate-scanner \
     xtate -ip 192.168.1.100 -p 11434 -scan zbanner -probe llm-inference -show all
```

### Build Failures

1. Ensure Docker has enough resources:
   - Memory: At least 2GB
   - Disk: At least 5GB free

2. Clean build cache:
   ```bash
   docker-compose build --no-cache
   ```

3. Check dependencies are available:
   ```bash
   docker build --target builder -t xtate-builder .
   docker run --rm xtate-builder xtate --version
   ```

## Security Considerations

### Scanning from Docker

1. **Host Network Access**: Container has full access to host network
2. **Root Privileges**: Container runs as root for packet capture
3. **Capabilities**: NET_ADMIN and NET_RAW are powerful capabilities

### Best Practices

1. **Limit Scope**: Only mount necessary directories
2. **Read-Only Mounts**: Use `:ro` for config files
3. **Remove Containers**: Use `--rm` for temporary scans
4. **Audit Logs**: Monitor container activity
5. **Dedicated Host**: Run on isolated scanning host when possible

### Production Use

For production scanning:

1. Use specific image tags (not `latest`)
2. Scan container images for vulnerabilities
3. Implement resource limits:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 2G
   ```
4. Monitor container metrics
5. Rotate logs regularly

## Integration Examples

### CI/CD Pipeline

```yaml
# .github/workflows/scan.yml
name: LLM Service Scan

on:
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Build Scanner
        run: docker-compose build

      - name: Run Scan
        run: |
          docker-compose run --rm xtate-scan \
            ${{ secrets.AUTHORIZED_NETWORK }}

      - name: Upload Results
        uses: actions/upload-artifact@v2
        with:
          name: scan-results
          path: results/
```

### Kubernetes

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: llm-scan
spec:
  template:
    spec:
      hostNetwork: true
      containers:
      - name: scanner
        image: xtate-llm-scanner:latest
        command: ["/xtate/scripts/scan-llm-services.sh"]
        args: ["-ip", "10.0.0.0/16"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: results
          mountPath: /xtate/results
      volumes:
      - name: results
        persistentVolumeClaim:
          claimName: scan-results
      restartPolicy: Never
```

### Docker Swarm

```yaml
version: '3.8'

services:
  xtate-scanner:
    image: xtate-llm-scanner:latest
    deploy:
      mode: replicated
      replicas: 3
      placement:
        constraints:
          - node.role == worker
    configs:
      - source: scan-config
        target: /xtate/data/llm-scan.conf
    secrets:
      - scan-targets
    command: xtate -c /xtate/data/llm-scan.conf -ip-file /run/secrets/scan-targets

configs:
  scan-config:
    file: ./data/llm-scan.conf

secrets:
  scan-targets:
    file: ./data/targets.txt
```

## Performance Tuning

### Resource Limits

Set appropriate resource limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      cpus: '2'
      memory: 2G
```

### High-Speed Scanning

For maximum performance:

```bash
docker run --rm --net=host \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  --cpus="4" --memory="4g" \
  -v $(pwd)/results:/xtate/results \
  xtate-llm-scanner \
  xtate -ip 10.0.0.0/8 -p 8000,11434 \
  -scan zbanner -probe llm-inference \
  -rate 100000 -tx-threads 4 -rx-handlers 4
```

### Multi-Host Scanning

Distribute scanning across multiple Docker hosts:

```bash
# Host 1
docker run ... xtate -ip 10.0.0.0/8 -shard 1/3 ...

# Host 2
docker run ... xtate -ip 10.0.0.0/8 -shard 2/3 ...

# Host 3
docker run ... xtate -ip 10.0.0.0/8 -shard 3/3 ...
```

## Cleanup

### Remove Containers

```bash
docker-compose down
docker-compose down -v  # Also remove volumes
```

### Remove Images

```bash
docker rmi xtate-llm-scanner:latest
docker image prune -a  # Remove all unused images
```

### Clean Build Cache

```bash
docker builder prune
```

## Additional Resources

- **Dockerfile**: [Dockerfile](Dockerfile)
- **Docker Compose**: [docker-compose.yml](docker-compose.yml)
- **Main Documentation**: [README-LLM-SCANNER.md](README-LLM-SCANNER.md)
- **Setup Guide**: [SETUP.md](SETUP.md)

---

**Note**: Docker scanning works best on Linux hosts. macOS and Windows have limitations with host networking and raw packet access.
