# LLM/AI Inference Service Scanning with Xtate

This document describes how to use Xtate to discover open LLM and AI inference services on networks.

## Overview

This project has been configured to detect and identify open LLM/AI inference services running popular software including:

- **Ollama** (default port 11434)
- **vLLM** (default port 8000)
- **Llama.cpp / llama-cpp-python** (default port 8000)
- **NVIDIA Triton Inference Server** (ports 8000/8001/8002)
- **LM Studio** (default port 1234)
- **GPT4All** (default port 4891)

## Quick Start

### 1. Build the Project

```bash
./build.sh
```

### 2. Configure Firewall Rules

To prevent your OS from interfering with the scan:

```bash
cd firewall
sudo ./add_rules.sh
```

### 3. Run a Scan

#### Scan Local Network
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

#### Scan Specific Subnet
```bash
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000
```

#### Scan Custom Ports
```bash
sudo ./scripts/scan-llm-services.sh -ip 172.16.0.0/12 -p 8000,11434
```

#### Aggressive Scan (Try All Detection Methods)
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24 --aggressive
```

## Manual Scanning

You can also run Xtate directly for more control:

### Basic Scan

```bash
sudo ./bin/xtate \
  -ip 192.168.1.0/24 \
  -p 8000,8001,8002,11434,1234,4891 \
  -scan zbanner \
  -probe llm-inference \
  -rate 10000
```

### Scan with Configuration File

```bash
sudo ./bin/xtate -c data/llm-scan.conf -ip 192.168.1.0/24
```

### Advanced Options

#### Aggressive Scanning
Enable all detection endpoints and version detection:
```bash
sudo ./bin/xtate \
  -ip 10.0.0.0/16 \
  -p 8000-8010,11434,1234,4891 \
  -scan zbanner \
  -probe llm-inference \
  -probe-arg "-aggressive -detect-version" \
  -rate 50000
```

#### Scan with Exclusions
Exclude private networks when scanning internet:
```bash
sudo ./bin/xtate \
  -ip 0.0.0.0/0 \
  -p 11434 \
  -scan zbanner \
  -probe llm-inference \
  -exclude-file data/exclude-private.conf \
  -rate 100000
```

#### Multiple Output Formats
```bash
sudo ./bin/xtate \
  -ip 192.168.1.0/24 \
  -p 8000,11434 \
  -scan zbanner \
  -probe llm-inference \
  -output text,csv,ndjson \
  -output-file results/scan.txt \
  -output-arg-csv "-file results/scan.csv" \
  -output-arg-ndjson "-file results/scan.ndjson"
```

## Probe Module Options

The `llm-inference` probe supports the following options:

### `--aggressive`
Enable aggressive scanning by trying all detection endpoints instead of just common ones.
```bash
-probe-arg "-aggressive"
```

### `--detect-version`
Attempt to detect specific software versions (enabled by default).
```bash
-probe-arg "-detect-version"
```

### `--metrics`
Include metrics endpoints in the scan.
```bash
-probe-arg "-metrics"
```

### `--user-agent`
Set a custom User-Agent string.
```bash
-probe-arg "-user-agent 'Custom Scanner/1.0'"
```

## Understanding Results

### Output Fields

The scanner outputs the following information for each detected service:

- **ip**: Target IP address
- **port**: Target port number
- **service**: Detected LLM service (Ollama, vLLM, Llama.cpp, etc.)
- **status**: HTTP status code from the service
- **details**: Additional information (version, model list, etc.)

### Example Output (Text Format)

```
[+] 192.168.1.100:11434 - Ollama (status: 200, details: version-detected)
[+] 192.168.1.105:8000 - vLLM (status: 200)
[+] 10.0.0.50:8000 - Llama.cpp (status: 200)
[+] 172.16.5.10:8000 - NVIDIA-Triton (status: 200, details: ready)
[+] 192.168.1.200:1234 - LM-Studio (status: 200)
```

### Example Output (JSON Format)

```json
{"timestamp":"2025-09-30T12:34:56","ip":"192.168.1.100","port":11434,"service":"Ollama","status":200,"details":"version-detected"}
{"timestamp":"2025-09-30T12:34:57","ip":"192.168.1.105","port":8000,"service":"vLLM","status":200}
```

### Example Output (CSV Format)

```csv
timestamp,ip,port,service,status,details
2025-09-30T12:34:56,192.168.1.100,11434,Ollama,200,version-detected
2025-09-30T12:34:57,192.168.1.105,8000,vLLM,200,
```

## Port Reference

| Software | Default Ports | Protocol | Description |
|----------|--------------|----------|-------------|
| Ollama | 11434 | HTTP | All-in-one LLM manager |
| vLLM | 8000 | HTTP | High-throughput inference engine |
| Llama.cpp | 8000 | HTTP | Optimized C++ inference (via Python server) |
| NVIDIA Triton | 8000, 8001, 8002 | HTTP, gRPC, Metrics | Enterprise inference server |
| LM Studio | 1234 | HTTP | Desktop LLM application |
| GPT4All | 4891 | HTTP | Consumer-grade LLM chatbot |

## Detection Methods

The scanner uses multiple detection strategies:

1. **Endpoint Probing**: Sends HTTP requests to common API endpoints:
   - `/api/tags` (Ollama)
   - `/api/version` (Ollama)
   - `/v1/models` (OpenAI-compatible APIs)
   - `/health` (Health checks)
   - `/v2/health/ready` (Triton)
   - `/v2/models` (Triton)

2. **Response Analysis**: Analyzes HTTP responses for:
   - Service-specific JSON structures
   - Software identifiers in response bodies
   - Version information
   - Model listings

3. **Signature Matching**: Pattern matching on:
   - "ollama" keyword
   - "vllm" keyword
   - "llama", "ggml", "gguf" keywords
   - "triton" keyword and ready status
   - "lm-studio" or "lmstudio" keywords
   - "gpt4all" keyword
   - OpenAI-compatible API structures

## Performance Considerations

### Scan Rate

Adjust the scan rate (`-rate`) based on your network capacity and target:

- **Local networks**: 10,000 - 50,000 pps
- **Small subnets**: 50,000 - 100,000 pps
- **Large-scale scanning**: 100,000+ pps (requires fast hardware and network)

### Threading

Optimize thread count for better performance:

```bash
-tx-threads 4 -rx-handlers 4
```

### Batching

For very high-speed scanning on Linux:

```bash
-sendmmsg -batch 128
```

## Safety and Ethics

### Important Considerations

1. **Authorization**: Only scan networks you own or have explicit permission to scan
2. **Rate Limiting**: Be respectful of target systems - don't overwhelm services
3. **Legal Compliance**: Ensure scanning complies with local laws and regulations
4. **Responsible Disclosure**: If you discover vulnerable services, practice responsible disclosure

### Defensive Use

This tool is designed for:
- **Security Auditing**: Finding exposed services in your infrastructure
- **Asset Discovery**: Identifying LLM deployments in your organization
- **Compliance Checking**: Ensuring services follow security policies
- **Research**: Academic study of LLM service deployment patterns

### DO NOT Use For

- Unauthorized access attempts
- Service disruption or denial-of-service
- Credential harvesting
- Malicious exploitation

## Troubleshooting

### Permission Denied

Xtate requires raw socket access. Run with sudo:
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

### No Results

1. Check firewall rules are applied
2. Verify network interface is correct: `--interface eth0`
3. Increase wait time: `-wait 30`
4. Try verbose output: `-show all`

### OS Interference

If your OS is sending RST packets, configure firewall rules:
```bash
cd firewall
sudo ./add_rules.sh
```

To remove rules later:
```bash
sudo ./rm_rules.sh
```

### Build Errors

Ensure dependencies are installed:
```bash
# Ubuntu/Debian
sudo apt install libpcap-dev libssl-dev libpcre2-dev

# macOS
brew install libpcap openssl pcre2
```

## Advanced Usage

### Distributed Scanning

Split scanning across multiple machines using shards:

Machine 1:
```bash
./bin/xtate -ip 10.0.0.0/8 -shard 1/3 -scan zbanner -probe llm-inference
```

Machine 2:
```bash
./bin/xtate -ip 10.0.0.0/8 -shard 2/3 -scan zbanner -probe llm-inference
```

Machine 3:
```bash
./bin/xtate -ip 10.0.0.0/8 -shard 3/3 -scan zbanner -probe llm-inference
```

### Resume Interrupted Scans

If a scan is interrupted, resume from where it left off:
```bash
./bin/xtate --resume results/llm-scan-resume.conf
```

### Target Generation from File

Create a target file with IP ranges:
```bash
# targets.txt
192.168.1.0/24
10.0.0.0/16
172.16.0.0/12
```

Then scan:
```bash
./bin/xtate -ip-file targets.txt -scan zbanner -probe llm-inference
```

## Configuration Files

### Main Configuration
[data/llm-scan.conf](data/llm-scan.conf) - Primary scanning configuration

### Exclusions
[data/exclude-private.conf](data/exclude-private.conf) - Private IP ranges to exclude

### Helper Script
[scripts/scan-llm-services.sh](scripts/scan-llm-services.sh) - Convenient wrapper script

## Further Information

- **Main README**: [README.md](README.md)
- **Xtate Documentation**: Run `./bin/xtate --help`
- **Probe Module Help**: Run `./bin/xtate --help-probe llm-inference`
- **GitHub Issues**: Report bugs and request features

## Contributing

To add detection for additional LLM services:

1. Edit [src/probe-modules/llm-inference-probe.c](src/probe-modules/llm-inference-probe.c)
2. Add endpoint patterns to `llm_probes[]`
3. Add detection logic to `llm_inference_parse()`
4. Rebuild: `./build.sh`
5. Test your changes

## License

This project is licensed under AGPL-3.0. See [LICENSE](LICENSE) for details.
