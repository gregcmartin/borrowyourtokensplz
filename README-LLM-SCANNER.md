# Xtate LLM Inference Service Scanner

> **A specialized configuration of Xtate for discovering open LLM/AI inference services**

This is a customized version of [Xtate](https://github.com/babycoff/xtate) focused exclusively on finding and identifying exposed LLM and AI inference services across networks.

## 🎯 What This Detects

This scanner identifies open inference services running:

| Software | Default Port(s) | Description |
|----------|----------------|-------------|
| **Ollama** | 11434 (HTTP) | User-friendly tool for running open-source LLMs locally |
| **vLLM** | 8000 (HTTP) | High-throughput inference engine with OpenAI-compatible API |
| **Llama.cpp** | 8000 (HTTP) | Python server for llama.cpp with OpenAI-compatible API |
| **NVIDIA Triton** | 8000/8001/8002 | Enterprise inference server (HTTP/gRPC/Metrics) |
| **LM Studio** | 1234 | Desktop GUI application for running local LLMs |
| **GPT4All** | 4891 | Free AI chatbot for consumer hardware |

## 🚀 Quick Start

### 1️⃣ Build the Scanner

```bash
git clone <this-repo>
cd xtate
./build.sh
```

### 2️⃣ Configure Your System (Linux only)

```bash
cd firewall
sudo ./add_rules.sh
cd ..
```

### 3️⃣ Run Your First Scan

```bash
# Scan your local network
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24

# Or scan a specific subnet
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000
```

**That's it!** Results will be in the `results/` directory.

## 📖 Documentation

- **[QUICK-START-LLM.md](QUICK-START-LLM.md)** - Fast track to your first scan
- **[LLM-SCANNING.md](LLM-SCANNING.md)** - Complete scanning guide
- **[README.md](README.md)** - Original Xtate documentation

## 💡 Common Use Cases

### Security Auditing
Find exposed LLM services in your infrastructure:
```bash
sudo ./scripts/scan-llm-services.sh -ip YOUR_NETWORK_RANGE
```

### Asset Discovery
Identify all LLM deployments in your organization:
```bash
sudo ./bin/xtate \
  -ip 10.0.0.0/8 \
  -p 8000,11434 \
  -scan zbanner \
  -probe llm-inference \
  -output csv \
  -output-file results/llm-assets.csv
```

### Compliance Checking
Ensure services follow security policies:
```bash
sudo ./scripts/scan-llm-services.sh -ip CORPORATE_NETWORK --aggressive
```

### Research
Study LLM service deployment patterns (authorized networks only):
```bash
sudo ./bin/xtate \
  -ip RESEARCH_RANGES \
  -p 8000,8001,8002,11434,1234,4891 \
  -scan zbanner \
  -probe llm-inference \
  -probe-arg "-aggressive -detect-version" \
  -rate 100000
```

## 🔍 How It Works

1. **High-Speed Scanning**: Uses Xtate's asynchronous packet engine (10,000+ pps)
2. **ZBanner Technology**: Stateless TCP banner grabbing for efficiency
3. **Smart Detection**: Probes common API endpoints (`/api/tags`, `/v1/models`, etc.)
4. **Service Fingerprinting**: Analyzes HTTP responses to identify specific software
5. **Multi-Format Output**: Text, CSV, and JSON formats for easy processing

## 🎨 Example Output

### Text Format
```
[+] 192.168.1.100:11434 - Ollama (status: 200, version-detected)
[+] 192.168.1.105:8000 - vLLM (status: 200)
[+] 10.0.0.50:8000 - Llama.cpp (status: 200)
[+] 172.16.5.10:8000 - NVIDIA-Triton (status: 200, ready)
```

### CSV Format
```csv
timestamp,ip,port,service,status,details
2025-09-30T12:34:56,192.168.1.100,11434,Ollama,200,version-detected
2025-09-30T12:34:57,192.168.1.105,8000,vLLM,200,
```

### JSON Format
```json
{"timestamp":"2025-09-30T12:34:56","ip":"192.168.1.100","port":11434,"service":"Ollama","status":200,"details":"version-detected"}
```

## 📊 Scan Options

### Basic Scan
```bash
sudo ./bin/xtate \
  -ip 192.168.1.0/24 \
  -p 11434,8000 \
  -scan zbanner \
  -probe llm-inference
```

### Aggressive Scan (All Endpoints)
```bash
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 --aggressive
```

### High-Speed Scan
```bash
sudo ./bin/xtate \
  -ip 172.16.0.0/12 \
  -p 8000,11434 \
  -scan zbanner \
  -probe llm-inference \
  -rate 100000
```

### All Ports on Specific Hosts
```bash
sudo ./bin/xtate \
  -ip 192.168.1.100-200 \
  -p 1-65535 \
  -scan zbanner \
  -probe llm-inference \
  -rate 5000
```

## 🛠️ Advanced Features

### Probe Module Options

Enable aggressive scanning:
```bash
-probe-arg "-aggressive"
```

Detect software versions:
```bash
-probe-arg "-detect-version"
```

Include metrics endpoints:
```bash
-probe-arg "-metrics"
```

Custom User-Agent:
```bash
-probe-arg "-user-agent 'MyScanner/1.0'"
```

### Performance Tuning

Multi-threaded scanning:
```bash
-tx-threads 4 -rx-handlers 4
```

Adjust scan rate:
```bash
-rate 100000  # 100k packets per second
```

Batch sending (Linux):
```bash
-sendmmsg -batch 128
```

### Distributed Scanning

Split work across multiple machines:
```bash
# Machine 1
./bin/xtate -ip 10.0.0.0/8 -shard 1/3 -scan zbanner -probe llm-inference

# Machine 2
./bin/xtate -ip 10.0.0.0/8 -shard 2/3 -scan zbanner -probe llm-inference

# Machine 3
./bin/xtate -ip 10.0.0.0/8 -shard 3/3 -scan zbanner -probe llm-inference
```

## ⚠️ Important Notes

### Legal & Ethical Use

✅ **DO:**
- Scan networks you own or have explicit permission to scan
- Use for security auditing, asset discovery, and research
- Follow responsible disclosure for found vulnerabilities
- Respect rate limits and target system resources

❌ **DON'T:**
- Scan unauthorized networks
- Attempt unauthorized access
- Harvest credentials or sensitive data
- Disrupt services or cause harm

### System Requirements

- **OS**: Linux or macOS (Windows supported but not recommended for scanning)
- **Privileges**: Root/sudo required for raw socket access
- **Dependencies**: libpcap, OpenSSL (optional), PCRE2 (optional)
- **Network**: Sufficient bandwidth for your desired scan rate

### Performance

- **Local networks**: 10,000 - 50,000 pps recommended
- **Large subnets**: 50,000 - 100,000 pps
- **Internet-scale**: 100,000+ pps (requires tuning)

## 🐛 Troubleshooting

### "Permission denied"
Run with sudo: `sudo ./scripts/scan-llm-services.sh -ip ...`

### "No results found"
1. Check firewall rules: `cd firewall && sudo ./add_rules.sh`
2. Verify network interface: `--interface eth0`
3. Increase wait time: `-wait 30`

### Build errors
Install dependencies:
```bash
# Ubuntu/Debian
sudo apt install libpcap-dev libssl-dev libpcre2-dev

# macOS
brew install libpcap openssl pcre2
```

## 📚 Learn More

- **Probe Module Help**: `./bin/xtate --help-probe llm-inference`
- **All Parameters**: `./bin/xtate --help`
- **List All Modules**: `./bin/xtate --list-probe`
- **Scan Examples**: `./bin/xtate --usage`

## 🤝 Contributing

Want to add detection for more LLM services?

1. Edit `src/probe-modules/llm-inference-probe.c`
2. Add endpoint patterns and detection logic
3. Rebuild and test
4. Submit a pull request!

## 📄 License

This project is licensed under **AGPL-3.0**. See [LICENSE](LICENSE) for details.

Original Xtate created by Alvin Chen (chenchiyu14@nudt.edu.cn)

## 🔗 Related Projects

- **Original Xtate**: https://github.com/babycoff/xtate
- **Masscan**: https://github.com/robertdavidgraham/masscan (spiritual predecessor)
- **ZMap**: https://github.com/zmap/zmap (alternative scanner)

## 🎓 Citation

If you use this tool in research, please cite:

```bibtex
@misc{chen2024zbanner,
    title={ZBanner: Fast Stateless Scanning Capable of Obtaining Responses over TCP},
    author={Chiyu Chen and Yuliang Lu and Guozheng Yang and Yi Xie and Shasha Guo},
    year={2024},
    eprint={2405.07409},
    archivePrefix={arXiv},
    primaryClass={cs.NI}
}
```

---

**Ready to scan?** Start with [QUICK-START-LLM.md](QUICK-START-LLM.md)!

**Need more details?** Check out [LLM-SCANNING.md](LLM-SCANNING.md)!

**Questions?** Open an issue on GitHub!
