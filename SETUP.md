# LLM Scanner Setup Guide

Complete setup instructions for using Xtate to scan for LLM/AI inference services.

## Prerequisites

### System Requirements
- **OS**: Linux (recommended) or macOS
- **Architecture**: 64-bit x86_64 or ARM64
- **Privileges**: Root/sudo access for packet capture
- **CMake**: Version 3.20 or higher
- **Compiler**: GCC, Clang, or MSVC

### Network Requirements
- Network interface card with packet capture support
- Sufficient bandwidth for desired scan rate
- Network access to target ranges

## Step 1: Install Dependencies

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    libpcap-dev \
    libssl-dev \
    libpcre2-dev \
    libxml2-dev \
    git
```

### CentOS/RHEL/Fedora
```bash
sudo dnf install -y \
    gcc \
    gcc-c++ \
    cmake \
    libpcap-devel \
    openssl-devel \
    pcre2-devel \
    libxml2-devel \
    git
```

### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install cmake libpcap openssl pcre2 libxml2
```

## Step 2: Get the Code

```bash
# Clone the repository
git clone <repository-url>
cd xtate

# Or if you already have it
cd /path/to/xtate
```

## Step 3: Build

### Linux
```bash
# Standard build
./build.sh

# Or with specific compiler
./build.sh clang

# Or debug build
./build.sh debug
```

### macOS
```bash
./build.sh
```

### Verify Build
```bash
# Check the binary exists
ls -lh bin/xtate

# Check version and build info
./bin/xtate --version

# List probe modules (should include llm-inference)
./bin/xtate --list-probe | grep llm-inference
```

Expected output should include:
```
llm-inference
    Detect open LLM/AI inference services
```

## Step 4: Configure Firewall (Linux Only)

### Why This Is Needed
When scanning, the OS kernel may send RST packets in response to SYN-ACK, interfering with banner grabbing. Firewall rules prevent this.

### Add Rules
```bash
cd firewall
sudo ./add_rules.sh
cd ..
```

### Verify Rules
```bash
cd firewall
sudo ./check_rules.sh
cd ..
```

### Remove Rules (When Done)
```bash
cd firewall
sudo ./rm_rules.sh
cd ..
```

## Step 5: Test Installation

### Test 1: Help Command
```bash
./bin/xtate --help-probe llm-inference
```

Should display probe module documentation.

### Test 2: Local Test (if you have an LLM service running)
```bash
# Example: Test against local Ollama instance
sudo ./bin/xtate \
    -ip 127.0.0.1 \
    -p 11434 \
    -scan zbanner \
    -probe llm-inference \
    -show all
```

### Test 3: Network Adapter Check
```bash
./bin/xtate --list-adapters
```

Should list available network interfaces.

## Step 6: Your First Scan

### Scan Local Network
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

### Or Manual Command
```bash
sudo ./bin/xtate \
    -ip 192.168.1.0/24 \
    -p 8000,11434 \
    -scan zbanner \
    -probe llm-inference \
    -rate 10000 \
    -output text \
    -output-file results/first-scan.txt
```

### Check Results
```bash
ls -lh results/
cat results/first-scan.txt
```

## Configuration Files

### Main Scan Config
[data/llm-scan.conf](data/llm-scan.conf)
- Pre-configured scanning parameters
- Default ports and settings
- Output format configuration

Usage:
```bash
sudo ./bin/xtate -c data/llm-scan.conf -ip YOUR_TARGETS
```

### Exclusion List
[data/exclude-private.conf](data/exclude-private.conf)
- Private IP ranges to exclude
- Use for internet scanning

Usage:
```bash
sudo ./bin/xtate -ip 0.0.0.0/0 --exclude-file data/exclude-private.conf ...
```

### Example Targets
[data/example-targets.txt](data/example-targets.txt)
- Example target specification
- Multiple formats shown

Usage:
```bash
sudo ./bin/xtate -ip-file data/example-targets.txt ...
```

## Quick Reference Commands

### Scan Commands
```bash
# Local network scan
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24

# High-speed scan
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000

# Aggressive scan (all endpoints)
sudo ./scripts/scan-llm-services.sh -ip 172.16.0.0/12 --aggressive

# Custom ports
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24 -p 8000,11434

# Specific interface
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/24 --interface eth0
```

### Direct Xtate Commands
```bash
# Basic scan
sudo ./bin/xtate -ip 192.168.1.0/24 -p 11434,8000 -scan zbanner -probe llm-inference

# With configuration file
sudo ./bin/xtate -c data/llm-scan.conf -ip 192.168.1.0/24

# Multiple outputs
sudo ./bin/xtate -ip 10.0.0.0/24 -p 11434 -scan zbanner -probe llm-inference \
    -output text,csv,ndjson \
    -output-file results/scan.txt \
    -output-arg-csv "-file results/scan.csv" \
    -output-arg-ndjson "-file results/scan.ndjson"

# High-performance scan
sudo ./bin/xtate -ip 172.16.0.0/12 -p 8000,11434 -scan zbanner \
    -probe llm-inference -rate 100000 -tx-threads 4 -rx-handlers 4
```

## Environment Variables

### Optional Settings
```bash
# Skip root check warning in scan script
export SKIP_ROOT_CHECK=1

# Custom results directory
export RESULTS_DIR=/path/to/results
```

## Directory Structure

```
xtate/
├── bin/                    # Built binaries
│   └── xtate              # Main executable
├── src/                   # Source code
│   └── probe-modules/
│       └── llm-inference-probe.c  # LLM detection probe
├── data/                  # Configuration files
│   ├── llm-scan.conf      # Main scan config
│   ├── exclude-private.conf  # Exclusion list
│   └── example-targets.txt   # Example targets
├── scripts/               # Helper scripts
│   └── scan-llm-services.sh  # Main scan script
├── firewall/              # Firewall rule scripts
│   ├── add_rules.sh       # Add rules
│   ├── check_rules.sh     # Check rules
│   └── rm_rules.sh        # Remove rules
├── results/               # Scan results (created on first run)
├── QUICK-START-LLM.md     # Quick start guide
├── LLM-SCANNING.md        # Complete documentation
├── README-LLM-SCANNER.md  # Project overview
└── SETUP.md               # This file
```

## Troubleshooting Setup

### Build Issues

#### "cmake: command not found"
```bash
# Ubuntu/Debian
sudo apt install cmake

# macOS
brew install cmake
```

#### "pcap.h: No such file"
```bash
# Ubuntu/Debian
sudo apt install libpcap-dev

# CentOS/RHEL
sudo dnf install libpcap-devel

# macOS
brew install libpcap
```

#### Compiler errors
```bash
# Try different compiler
./build.sh clang

# Or install GCC
sudo apt install gcc g++
```

### Runtime Issues

#### "Permission denied"
Always run with sudo:
```bash
sudo ./bin/xtate ...
sudo ./scripts/scan-llm-services.sh ...
```

#### "No such interface"
List available interfaces:
```bash
./bin/xtate --list-adapters
```

Then specify:
```bash
sudo ./bin/xtate --interface eth0 ...
```

#### "Address already in use"
Another instance may be running:
```bash
ps aux | grep xtate
sudo killall xtate
```

#### No results found
1. Check firewall rules (Linux): `cd firewall && sudo ./add_rules.sh`
2. Verify targets are reachable: `ping TARGET_IP`
3. Try verbose output: `--show all`
4. Increase wait time: `-wait 30`

### Performance Issues

#### Low scan rate
- Increase rate: `-rate 50000`
- Add more threads: `-tx-threads 4 -rx-handlers 4`
- Use batch sending (Linux): `-sendmmsg -batch 128`

#### High CPU usage
- Decrease rate: `-rate 5000`
- Reduce thread count: `-tx-threads 1 -rx-handlers 1`

#### Memory usage
- Reduce dedup window: `-dedup-window 500000`
- Decrease buffer sizes in config

## Next Steps

1. **Read Quick Start**: [QUICK-START-LLM.md](QUICK-START-LLM.md)
2. **Review Examples**: [LLM-SCANNING.md](LLM-SCANNING.md)
3. **Explore Features**: [README-LLM-SCANNER.md](README-LLM-SCANNER.md)
4. **Check Modifications**: [PROJECT-MODIFICATIONS.md](PROJECT-MODIFICATIONS.md)

## Getting Help

### Documentation
- `./bin/xtate --help` - General help
- `./bin/xtate --help-probe llm-inference` - Probe module help
- `./bin/xtate --usage` - Usage examples
- `./bin/xtate --list-probe` - List all probes

### Common Questions

**Q: Do I need root?**
A: Yes, raw packet capture requires root/sudo privileges.

**Q: What ports should I scan?**
A: Default: 8000, 8001, 8002, 11434, 1234, 4891. See port table in docs.

**Q: Is this legal?**
A: Only scan networks you own or have explicit permission to scan.

**Q: Can I scan the internet?**
A: Yes, with permission and proper rate limiting. Use exclude lists.

**Q: How fast can I scan?**
A: Depends on hardware and network. Start with 10k pps, increase carefully.

**Q: What if I find vulnerable services?**
A: Practice responsible disclosure. Don't exploit.

## Additional Resources

- **Original Xtate**: https://github.com/babycoff/xtate
- **ZBanner Paper**: arXiv:2405.07409
- **Issues**: Use GitHub issues for bug reports

## Summary Checklist

- [ ] Dependencies installed
- [ ] Project built successfully
- [ ] Binary verified (`./bin/xtate --version`)
- [ ] Firewall rules configured (Linux)
- [ ] Test scan completed
- [ ] Results directory created
- [ ] Documentation reviewed

**Ready to scan?** Start with a small network first:
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

Good luck and scan responsibly! 🚀
