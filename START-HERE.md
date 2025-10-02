# 🚀 START HERE: LLM Service Scanner

**Welcome!** This project finds open LLM/AI inference services on networks.

## 🎯 What This Does

Scans networks to find exposed instances of:
- 🦙 **Ollama** (port 11434)
- ⚡ **vLLM** (port 8000)
- 🦙 **Llama.cpp** (port 8000)
- 🟢 **NVIDIA Triton** (ports 8000-8002)
- 🎨 **LM Studio** (port 1234)
- 🤖 **GPT4All** (port 4891)

## ⚡ Quick Start (3 Steps)

### 1. Build
```bash
./build.sh
```

### 2. Setup Firewall (Linux only)
```bash
cd firewall && sudo ./add_rules.sh && cd ..
```

### 3. Scan!
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

**Done!** Results are in `results/` directory.

---

## 📚 What to Read Next

Choose your path:

### 🏃 I want to start scanning NOW
→ **[QUICK-START-LLM.md](QUICK-START-LLM.md)** - Fast track guide with commands

### 🔧 I need to set up the project first
→ **[SETUP.md](SETUP.md)** - Complete setup instructions

### 📖 I want to understand everything
→ **[LLM-SCANNING.md](LLM-SCANNING.md)** - Comprehensive documentation

### 🎓 I want to know what was changed
→ **[PROJECT-MODIFICATIONS.md](PROJECT-MODIFICATIONS.md)** - All modifications explained

### 🌟 I want the overview
→ **[README-LLM-SCANNER.md](README-LLM-SCANNER.md)** - Project overview and features

---

## 🎬 Example Commands

### Scan your local network
```bash
sudo ./scripts/scan-llm-services.sh -ip 192.168.1.0/24
```

### Scan a specific subnet faster
```bash
sudo ./scripts/scan-llm-services.sh -ip 10.0.0.0/16 -r 50000
```

### Scan just Ollama on common ports
```bash
sudo ./bin/xtate -ip 192.168.0.0/16 -p 11434 -scan zbanner -probe llm-inference
```

### Scan with all detection methods
```bash
sudo ./scripts/scan-llm-services.sh -ip 172.16.0.0/12 --aggressive
```

---

## ⚠️ Important!

✅ **Only scan networks you own or have permission to scan**

❌ **Do NOT scan unauthorized networks** - it's illegal and unethical

This tool is for:
- Security auditing your infrastructure
- Finding exposed services you manage
- Research with proper authorization

---

## 🆘 Need Help?

### Quick Help
```bash
./bin/xtate --help-probe llm-inference
```

### Issues?
1. **Build problems?** → See [SETUP.md](SETUP.md#troubleshooting-setup)
2. **No results?** → Check firewall rules: `cd firewall && sudo ./add_rules.sh`
3. **Permission denied?** → Run with `sudo`

### Documentation Tree
```
START-HERE.md (you are here)
├── QUICK-START-LLM.md ........... Fast commands and examples
├── SETUP.md ..................... Installation and configuration
├── LLM-SCANNING.md .............. Complete scanning guide
├── README-LLM-SCANNER.md ........ Project overview
└── PROJECT-MODIFICATIONS.md ..... Technical details of changes
```

---

## 🎯 Common Use Cases

### Find exposed services in your network
```bash
sudo ./scripts/scan-llm-services.sh -ip YOUR_NETWORK_CIDR
```

### Audit specific hosts
```bash
sudo ./bin/xtate -ip 192.168.1.100-200 -p 8000,11434 -scan zbanner -probe llm-inference
```

### Export results to CSV
```bash
sudo ./bin/xtate -ip 10.0.0.0/24 -p 11434 -scan zbanner -probe llm-inference \
    -output csv -output-file results/found.csv
```

---

## 📊 What You'll Get

### Text Output
```
[+] 192.168.1.100:11434 - Ollama (status: 200, version-detected)
[+] 192.168.1.105:8000 - vLLM (status: 200)
```

### CSV Output
```csv
timestamp,ip,port,service,status,details
2025-09-30T12:34:56,192.168.1.100,11434,Ollama,200,version-detected
```

### JSON Output
```json
{"timestamp":"2025-09-30T12:34:56","ip":"192.168.1.100","port":11434,"service":"Ollama","status":200}
```

---

## 🚦 Status Check

Before your first scan, verify:

```bash
# 1. Build successful?
ls -lh bin/xtate

# 2. Probe registered?
./bin/xtate --list-probe | grep llm-inference

# 3. Network interfaces?
./bin/xtate --list-adapters

# 4. Have sudo access?
sudo echo "Ready!"
```

All good? → Start scanning! 🎉

---

## 💡 Pro Tips

1. **Start small** - Test on your local network first
2. **Check permissions** - Ensure you're authorized to scan
3. **Rate limit** - Start with `-rate 10000` and increase carefully
4. **Save results** - Always use `-output-file` to keep records
5. **Be ethical** - Only scan what you're allowed to scan

---

## 🎓 Learning Path

1. ✅ Read this file (you're doing it!)
2. → Run a test scan on localhost/local network
3. → Read [QUICK-START-LLM.md](QUICK-START-LLM.md) for more examples
4. → Explore [LLM-SCANNING.md](LLM-SCANNING.md) for advanced features
5. → Check [PROJECT-MODIFICATIONS.md](PROJECT-MODIFICATIONS.md) to understand the code

---

## 🔗 Quick Links

| Link | Description |
|------|-------------|
| [QUICK-START-LLM.md](QUICK-START-LLM.md) | Fast commands and one-liners |
| [SETUP.md](SETUP.md) | Build and installation guide |
| [LLM-SCANNING.md](LLM-SCANNING.md) | Complete documentation |
| [README-LLM-SCANNER.md](README-LLM-SCANNER.md) | Project overview |
| [PROJECT-MODIFICATIONS.md](PROJECT-MODIFICATIONS.md) | Technical changes |

---

**Ready to find some LLM services?**

Choose your next step:
- 🏃 **Quick start** → [QUICK-START-LLM.md](QUICK-START-LLM.md)
- 🔧 **Setup help** → [SETUP.md](SETUP.md)
- 📖 **Full docs** → [LLM-SCANNING.md](LLM-SCANNING.md)

Happy scanning! 🚀 (responsibly!)
