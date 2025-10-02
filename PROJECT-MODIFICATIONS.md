# Project Modifications for LLM Service Scanning

This document summarizes all modifications made to configure Xtate for LLM/AI inference service discovery.

## Overview

The project has been specialized to focus **exclusively** on finding open LLM and AI inference services running popular software like Ollama, vLLM, Llama.cpp, NVIDIA Triton, LM Studio, and GPT4All.

## Files Created

### 1. Probe Module (Core Detection Logic)
**File**: `src/probe-modules/llm-inference-probe.c`
- Custom probe module for LLM service detection
- Implements HTTP endpoint probing for common LLM APIs
- Pattern matching for service identification
- Supports aggressive scanning mode
- Detects 6+ different LLM platforms

**Key Features**:
- Probes endpoints: `/api/tags`, `/api/version`, `/v1/models`, `/health`, `/v2/health/ready`, etc.
- Identifies services by response patterns and signatures
- Configurable User-Agent, aggressive mode, version detection
- Outputs: service name, HTTP status, version details

### 2. Module Registration
**File**: `src/probe-modules/probe-modules.c` (modified)
- Added external declaration for `LlmInferenceProbe`
- Registered probe in `probe_modules_list[]`

### 3. Configuration Files

#### `data/llm-scan.conf`
Pre-configured scanning setup including:
- Scan module: `zbanner` (stateless TCP)
- Probe module: `llm-inference`
- Default ports: 8000, 8001, 8002, 11434, 1234, 4891
- Output formats: text, CSV, NDJSON
- Rate limiting and threading defaults

#### `data/exclude-private.conf`
Exclusion list for private IP ranges:
- RFC 1918 private networks (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- Loopback, link-local, multicast, reserved ranges
- Used for internet-scale scanning to avoid private addresses

#### `data/example-targets.txt`
Example target specification file showing:
- CIDR notation examples
- Range notation examples
- Single host examples
- Comments and documentation

### 4. Scanning Scripts

#### `scripts/scan-llm-services.sh`
Main scanning wrapper script providing:
- User-friendly command-line interface
- Preset configurations for common scenarios
- Color-coded output messages
- Input validation and error handling
- Modes: local network, internet, aggressive
- Automatic result summarization

**Usage Examples**:
```bash
./scripts/scan-llm-services.sh -ip 192.168.1.0/24
./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000
./scripts/scan-llm-services.sh -ip 172.16.0.0/12 --aggressive
```

### 5. Documentation

#### `QUICK-START-LLM.md`
Fast-track guide covering:
- 3-step quick start
- Common commands
- One-liner examples
- Safety reminders

#### `LLM-SCANNING.md`
Comprehensive documentation including:
- Detailed usage instructions
- All probe options and parameters
- Output format examples
- Performance tuning guide
- Troubleshooting section
- Advanced features (distributed scanning, resumption, etc.)
- Port reference table
- Detection methodology explanation

#### `README-LLM-SCANNER.md`
Project overview document with:
- Feature highlights
- Quick start guide
- Use case examples
- Example outputs
- Advanced features
- Legal and ethical guidelines
- Troubleshooting tips

#### `PROJECT-MODIFICATIONS.md` (this file)
Complete summary of all project changes

## Target Services

The scanner is configured to detect the following LLM inference platforms:

| Software | Default Port(s) | Detection Method |
|----------|----------------|------------------|
| Ollama | 11434 | `/api/tags`, `/api/version` endpoints + "ollama" in response |
| vLLM | 8000 | OpenAI-compatible API + "vllm" in response |
| Llama.cpp | 8000 | OpenAI-compatible API + "llama"/"ggml"/"gguf" in response |
| NVIDIA Triton | 8000/8001/8002 | `/v2/health/ready`, `/v2/models` + "triton" or ready status |
| LM Studio | 1234 | OpenAI-compatible API + "lm-studio"/"lmstudio" in response |
| GPT4All | 4891 | OpenAI-compatible API + "gpt4all" in response |

## Detection Methodology

The probe uses a multi-layered approach:

1. **Endpoint Probing**: Sends HTTP GET/OPTIONS requests to known API endpoints
2. **Response Analysis**: Parses HTTP status codes and response bodies
3. **Signature Matching**: Searches for service-specific keywords and JSON structures
4. **Version Detection**: Attempts to extract version information when available

## Configuration Options

### Probe Arguments

- `--aggressive`: Enable scanning of all endpoints (not just common ones)
- `--detect-version`: Attempt version detection (enabled by default)
- `--metrics`: Include metrics endpoints in scan
- `--user-agent <string>`: Set custom User-Agent header

### Scan Parameters

- `-ip <targets>`: IP addresses/ranges to scan
- `-p <ports>`: Ports to scan (default: 8000,8001,8002,11434,1234,4891)
- `-rate <pps>`: Packets per second (default: 10000)
- `-scan zbanner`: Use ZBanner for stateless TCP scanning
- `-probe llm-inference`: Use LLM detection probe
- `-output <formats>`: Output formats (text, csv, ndjson)
- `--exclude-file <file>`: Exclusion list for IP ranges

## Usage Examples

### Basic Scans
```bash
# Local network
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24

# Specific subnet with high rate
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000

# Custom ports
sudo ./scripts/scan-llm-services.sh -ip 172.16.0.0/12 -p 8000,11434
```

### Advanced Scans
```bash
# Aggressive scan with all detection methods
sudo ./bin/xtate -ip 192.168.1.0/24 -p 8000-8010,11434 -scan zbanner \
  -probe llm-inference -probe-arg "-aggressive -detect-version"

# Internet scan with exclusions
sudo ./bin/xtate -ip 0.0.0.0/0 -p 11434 -scan zbanner \
  -probe llm-inference -exclude-file data/exclude-private.conf -rate 100000

# Multi-format output
sudo ./bin/xtate -ip 10.0.0.0/24 -p 11434,8000 -scan zbanner \
  -probe llm-inference -output text,csv,ndjson \
  -output-file results/scan.txt \
  -output-arg-csv "-file results/scan.csv" \
  -output-arg-ndjson "-file results/scan.ndjson"

# Distributed scanning (3 machines)
sudo ./bin/xtate -ip 10.0.0.0/8 -shard 1/3 -scan zbanner -probe llm-inference
sudo ./bin/xtate -ip 10.0.0.0/8 -shard 2/3 -scan zbanner -probe llm-inference
sudo ./bin/xtate -ip 10.0.0.0/8 -shard 3/3 -scan zbanner -probe llm-inference
```

### Target Specification
```bash
# From file
sudo ./bin/xtate -ip-file data/example-targets.txt -p 11434 \
  -scan zbanner -probe llm-inference

# Using configuration file
sudo ./bin/xtate -c data/llm-scan.conf -ip 192.168.1.0/24

# Resume interrupted scan
sudo ./bin/xtate --resume results/llm-scan-resume.conf
```

## Output Formats

### Text Format
```
[+] 192.168.1.100:11434 - Ollama (status: 200, details: version-detected)
[+] 192.168.1.105:8000 - vLLM (status: 200)
```

### CSV Format
```csv
timestamp,ip,port,service,status,details
2025-09-30T12:34:56,192.168.1.100,11434,Ollama,200,version-detected
2025-09-30T12:34:57,192.168.1.105,8000,vLLM,200,
```

### NDJSON Format
```json
{"timestamp":"2025-09-30T12:34:56","ip":"192.168.1.100","port":11434,"service":"Ollama","status":200,"details":"version-detected"}
{"timestamp":"2025-09-30T12:34:57","ip":"192.168.1.105","port":8000,"service":"vLLM","status":200}
```

## Build Instructions

### Linux
```bash
./build.sh
```

Or with custom compiler:
```bash
./build.sh clang          # Release with Clang
./build.sh debug gcc      # Debug with GCC
```

### macOS
```bash
./build.sh
```

### Dependencies
```bash
# Ubuntu/Debian
sudo apt install libpcap-dev libssl-dev libpcre2-dev libxml2-dev

# macOS
brew install libpcap openssl pcre2 libxml2
```

## Firewall Configuration

### Linux (iptables)
```bash
# Add rules to prevent OS interference
cd firewall
sudo ./add_rules.sh

# Check rules
sudo ./check_rules.sh

# Remove rules
sudo ./rm_rules.sh
```

### Why Needed
The OS kernel may send RST packets in response to SYN-ACK packets from probed services, interfering with banner grabbing. Firewall rules prevent this.

## Performance Tuning

### Scan Rate
- Local networks: 10,000 - 50,000 pps
- Large subnets: 50,000 - 100,000 pps
- Internet-scale: 100,000+ pps

### Threading
```bash
-tx-threads 4 -rx-handlers 4
```

### Batch Sending (Linux)
```bash
-sendmmsg -batch 128
```

### Deduplication
```bash
-dedup-window 1000000  # microseconds
```

## Security & Ethics

### Designed For (Defensive Use)
- ✅ Security auditing of owned infrastructure
- ✅ Asset discovery in authorized networks
- ✅ Compliance checking
- ✅ Academic research with permission

### NOT For (Offensive Use)
- ❌ Unauthorized network scanning
- ❌ Exploitation or unauthorized access
- ❌ Credential harvesting
- ❌ Service disruption

### Best Practices
1. Only scan networks you own or have explicit written permission to scan
2. Use appropriate scan rates to avoid overwhelming services
3. Follow responsible disclosure for discovered vulnerabilities
4. Comply with local laws and regulations
5. Document your authorization before scanning

## Troubleshooting

### No Results
1. Verify firewall rules: `cd firewall && sudo ./add_rules.sh`
2. Check network interface: `./bin/xtate --list-adapters`
3. Increase wait time: `-wait 30`
4. Enable verbose output: `-show all`

### Permission Errors
- Run with sudo: `sudo ./scripts/scan-llm-services.sh ...`
- Raw socket access requires root privileges

### Build Failures
- Install dependencies (see above)
- Check CMake version: `cmake --version` (need >= 3.20)
- Try different compiler: `./build.sh clang`

### OS Interference
- Configure firewall rules (Linux only)
- Use separate source IP if available
- Check for existing iptables rules

## Testing the Module

```bash
# List all probe modules (should include llm-inference)
./bin/xtate --list-probe

# View probe help
./bin/xtate --help-probe llm-inference

# Test on known service (if you have one running)
sudo ./bin/xtate -ip 127.0.0.1 -p 11434 -scan zbanner -probe llm-inference -show all
```

## Integration with Original Xtate

All modifications maintain compatibility with original Xtate functionality:
- Other scan modules still work
- Other probe modules still work
- All original features preserved
- Can combine with other modules if needed

The LLM detection is simply a new probe module added to the existing framework.

## Future Enhancements

Potential additions:
- More LLM platforms (HuggingFace TGI, OpenAI-compatible servers, etc.)
- Better version detection and fingerprinting
- Model enumeration and capability detection
- Authentication detection (open vs protected services)
- False positive reduction
- Performance optimizations

## Files Modified

1. `src/probe-modules/probe-modules.c` - Added module registration
2. All other files are new additions, no existing functionality modified

## Files Added

### Source Code
- `src/probe-modules/llm-inference-probe.c`

### Configuration
- `data/llm-scan.conf`
- `data/exclude-private.conf`
- `data/example-targets.txt`

### Scripts
- `scripts/scan-llm-services.sh`

### Documentation
- `QUICK-START-LLM.md`
- `LLM-SCANNING.md`
- `README-LLM-SCANNER.md`
- `PROJECT-MODIFICATIONS.md`

## License

All modifications maintain AGPL-3.0 license compatibility with original Xtate project.

## Credits

- Original Xtate: Alvin Chen (chenchiyu14@nudt.edu.cn)
- LLM scanning modifications: Custom implementation
- Based on ZBanner and HLTCP technologies from research papers

## Support

For issues specific to LLM scanning:
1. Check documentation: `LLM-SCANNING.md`
2. View probe help: `./bin/xtate --help-probe llm-inference`
3. Review examples: `QUICK-START-LLM.md`

For general Xtate issues:
- Original repository: https://github.com/babycoff/xtate
- General help: `./bin/xtate --help`

---

**Last Updated**: 2025-09-30
**Version**: Custom LLM Scanner v1.0 (based on Xtate v2.13.1)
