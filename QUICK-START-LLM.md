# Quick Start: LLM Service Scanning

Find open LLM/AI inference services in 3 easy steps!

## 1. Build

```bash
./build.sh
```

## 2. Configure Firewall (Linux only)

```bash
cd firewall && sudo ./add_rules.sh && cd ..
```

## 3. Scan!

### Scan Your Local Network
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

### Scan a Subnet
```bash
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000
```

### Scan Specific Hosts
```bash
sudo ./bin/xtate -ip 192.168.1.100-200 -p 11434,8000 -scan zbanner -probe llm-inference
```

## What Gets Detected

- 🦙 **Ollama** (port 11434)
- ⚡ **vLLM** (port 8000)
- 🦙 **Llama.cpp** (port 8000)
- 🟢 **NVIDIA Triton** (ports 8000/8001/8002)
- 🎨 **LM Studio** (port 1234)
- 🤖 **GPT4All** (port 4891)

## Common Commands

### All Common Ports
```bash
sudo ./bin/xtate \
  -ip 192.168.0.0/16 \
  -p 8000,8001,8002,11434,1234,4891 \
  -scan zbanner \
  -probe llm-inference \
  -rate 10000
```

### Just Ollama
```bash
sudo ./bin/xtate -ip 10.0.0.0/8 -p 11434 -scan zbanner -probe llm-inference
```

### Aggressive Scan
```bash
sudo ./scripts/scan-llm-services.sh -ip 172.16.0.0/12 --aggressive
```

### Save Results
```bash
sudo ./bin/xtate \
  -ip 192.168.1.0/24 \
  -p 11434,8000 \
  -scan zbanner \
  -probe llm-inference \
  -output csv \
  -output-file results/found.csv
```

## View Results

Results are saved to `results/` directory:
- `llm-scan.txt` - Human-readable text
- `llm-scan.csv` - CSV format for spreadsheets
- `llm-scan.ndjson` - Newline-delimited JSON for processing

## Need Help?

- Full documentation: [LLM-SCANNING.md](LLM-SCANNING.md)
- Probe options: `./bin/xtate --help-probe llm-inference`
- General help: `./bin/xtate --help`

## One-Liner Examples

```bash
# Fast local scan
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24

# Internet scan (replace IPs with authorized targets!)
sudo ./bin/xtate -ip YOUR_AUTHORIZED_RANGES -p 11434,8000 -scan zbanner -probe llm-inference -exclude-file data/exclude-private.conf -rate 100000

# Find ALL services on a host
sudo ./bin/xtate -ip 192.168.1.100 -p 1-65535 -scan zbanner -probe llm-inference -rate 1000

# Scan and save to all formats
sudo ./bin/xtate -ip 10.0.0.0/24 -p 11434,8000 -scan zbanner -probe llm-inference -output text,csv,ndjson -output-file results/scan.txt -output-arg-csv "-file results/scan.csv" -output-arg-ndjson "-file results/scan.ndjson"
```

## Safety First! ⚠️

✅ **Only scan networks you own or have permission to scan**
✅ **Use appropriate scan rates to avoid disruption**
✅ **This tool is for defensive security and research**

❌ **Do NOT scan unauthorized networks**
❌ **Do NOT attempt unauthorized access**
❌ **Do NOT use for malicious purposes**

---

**Ready for more?** See [LLM-SCANNING.md](LLM-SCANNING.md) for comprehensive documentation.
