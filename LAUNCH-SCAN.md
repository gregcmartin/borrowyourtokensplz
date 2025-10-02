# 🚀 LAUNCH INTERNET SCAN

## ✅ Pre-Flight Checklist

Your scanner is **READY TO GO!** Here's what we have:

### Docker Container
- ✅ Built successfully
- ✅ LLM inference probe registered and working
- ✅ All dependencies included
- ✅ Scripts and configs loaded

### Capabilities
- 🎯 Detects 6+ LLM platforms
- 🌍 Can scan entire IPv4 space
- ⚡ Up to 1M+ packets per second
- 📊 Multiple output formats
- 💾 Resume capability for interrupted scans

---

## 🎯 Launch Commands

### Option 1: Interactive Scan (Recommended for First Time)

This will prompt for confirmation and show scan statistics:

```bash
docker-compose run --rm xtate-scanner /xtate/scripts/scan-internet-llm.sh
```

**You will see:**
1. Warning banner about authorization
2. Confirmation prompts
3. Scan statistics and time estimates
4. Real-time progress

### Option 2: Quick Test First

**HIGHLY RECOMMENDED** - Test on a small network first:

```bash
# Test on your local network (replace with your network)
docker-compose run --rm xtate-scanner \
  xtate -ip 192.168.1.0/24 -p 11434,8000 -scan zbanner -probe llm-inference
```

### Option 3: Full Internet Scan (AUTHORIZED USE ONLY!)

For a complete IPv4 scan at 100k pps:

```bash
docker-compose run --rm \
  -e SCAN_RATE=100000 \
  -v $(pwd)/results:/xtate/results \
  xtate-scanner /xtate/scripts/scan-internet-llm.sh
```

### Option 4: Specific IP Range

Scan a specific block:

```bash
docker-compose run --rm xtate-scanner \
  xtate -ip 1.0.0.0/8 \
  -p 11434,8000,8001,8002,1234,4891 \
  -scan zbanner \
  -probe llm-inference \
  -rate 100000 \
  --exclude-file /xtate/data/exclude-private.conf \
  -output text,csv,ndjson \
  -output-file /xtate/results/scan.txt \
  -output-arg-csv "-file /xtate/results/scan.csv" \
  -output-arg-ndjson "-file /xtate/results/scan.ndjson"
```

---

## 📊 What To Expect

### Scan Parameters

**Default Configuration:**
- **Targets**: All public IPv4 addresses (0.0.0.0/0)
- **Ports**: 11434, 8000, 8001, 8002, 1234, 4891
- **Rate**: 50,000 pps (adjustable)
- **Threads**: 4 TX / 4 RX
- **Excluded**: Private networks automatically excluded

### Scan Statistics

At **50,000 pps**:
- Total probes: ~24 billion
- Estimated time: **~5.5 days**
- Expected throughput: ~50 Mbps

At **100,000 pps**:
- Estimated time: **~2.8 days**
- Expected throughput: ~100 Mbps

At **500,000 pps**:
- Estimated time: **~13 hours**
- Expected throughput: ~500 Mbps

At **1,000,000 pps**:
- Estimated time: **~6.5 hours**
- Expected throughput: ~1 Gbps

### Expected Results

You'll find:
- Ollama instances (port 11434)
- vLLM services (port 8000)
- Llama.cpp servers (port 8000)
- NVIDIA Triton servers (ports 8000-8002)
- LM Studio instances (port 1234)
- GPT4All services (port 4891)
- Unknown OpenAI-compatible APIs

---

## 📁 Output Files

Results will be in `./results/`:

```
results/
├── internet-scan.txt          # Human-readable text
├── internet-scan.csv          # Spreadsheet format
├── internet-scan.ndjson       # JSON format
└── internet-scan-resume.conf  # Resume file if interrupted
```

### View Results Live

```bash
# In another terminal
tail -f results/internet-scan.txt

# Count services found
wc -l results/internet-scan.csv

# Watch in real-time
watch -n 5 'wc -l results/internet-scan.csv'
```

---

## 🎛️ Scan Control

### Adjust Scan Rate

```bash
# Conservative (1 Gbps network)
docker-compose run --rm -e SCAN_RATE=50000 xtate-scanner /xtate/scripts/scan-internet-llm.sh

# Moderate (10 Gbps network)
docker-compose run --rm -e SCAN_RATE=200000 xtate-scanner /xtate/scripts/scan-internet-llm.sh

# Aggressive (40+ Gbps network)
docker-compose run --rm -e SCAN_RATE=1000000 xtate-scanner /xtate/scripts/scan-internet-llm.sh
```

### Pause/Resume

```bash
# Ctrl+C to pause (saves resume state)

# Resume later
docker-compose run --rm xtate-scanner \
  xtate --resume /xtate/results/internet-scan-resume.conf
```

### Distributed Scanning

Split across 4 machines:

```bash
# Machine 1
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 1/4 -p 11434,8000 -scan zbanner -probe llm-inference -rate 100000

# Machine 2
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 2/4 -p 11434,8000 -scan zbanner -probe llm-inference -rate 100000

# Machine 3
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 3/4 -p 11434,8000 -scan zbanner -probe llm-inference -rate 100000

# Machine 4
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 4/4 -p 11434,8000 -scan zbanner -probe llm-inference -rate 100000
```

This completes in **1/4 the time**!

---

## ⚠️ IMPORTANT REMINDERS

### Legal Requirements

- ✅ **You MUST have legal authorization to scan target networks**
- ✅ **Comply with laws in your jurisdiction and target locations**
- ✅ **Unauthorized scanning may be ILLEGAL**

### Ethical Requirements

- ✅ **Use for defensive security, research, or authorized assessments only**
- ✅ **Do NOT attempt unauthorized access or exploitation**
- ✅ **Practice responsible disclosure for any vulnerabilities found**
- ✅ **Respect rate limits and target resources**

### Technical Requirements

- ✅ **Sufficient bandwidth** (1 Gbps minimum for 50k pps)
- ✅ **Network access** (no egress filtering on raw sockets)
- ✅ **Disk space** (several GB for results)
- ✅ **Time commitment** (hours to days depending on rate)

---

## 🔥 READY TO LAUNCH?

### Step 1: Verify Container

```bash
docker-compose run --rm xtate-scanner xtate --version
docker-compose run --rm xtate-scanner xtate --list-probe | grep llm-inference
```

### Step 2: Test on Small Network

```bash
# Replace with YOUR authorized network
docker-compose run --rm xtate-scanner \
  xtate -ip 192.168.1.0/24 -p 11434 -scan zbanner -probe llm-inference
```

### Step 3: Launch Full Scan

```bash
docker-compose run --rm \
  -v $(pwd)/results:/xtate/results \
  xtate-scanner /xtate/scripts/scan-internet-llm.sh
```

---

## 📊 Monitoring

### Real-Time Stats

```bash
# Terminal 1: Run scan
docker-compose run --rm xtate-scanner /xtate/scripts/scan-internet-llm.sh

# Terminal 2: Watch results
tail -f results/internet-scan.txt

# Terminal 3: Count services
watch -n 10 'echo "Services found: $(wc -l < results/internet-scan.csv)"'
```

### Check Progress

```bash
# View last 20 results
tail -20 results/internet-scan.txt

# Count by service type
awk -F',' 'NR>1 {print $4}' results/internet-scan.csv | sort | uniq -c

# Get IPs of found services
awk -F',' 'NR>1 {print $2}' results/internet-scan.csv | sort -u
```

---

## 🎯 Example Session

Here's what a typical launch looks like:

```bash
$ docker-compose run --rm xtate-scanner /xtate/scripts/scan-internet-llm.sh

╔═══════════════════════════════════════════════════════════════╗
║        INTERNET-SCALE LLM INFERENCE SERVICE SCANNER           ║
║  Scanning for: Ollama, vLLM, Llama.cpp, Triton, LM Studio   ║
╚═══════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════╗
║                       ⚠️  WARNING ⚠️                           ║
║  You are about to scan the ENTIRE IPv4 INTERNET!             ║
║  This requires legal authorization and ethical approval       ║
╚═══════════════════════════════════════════════════════════════╝

Do you have legal authorization to scan the target network?
Type 'YES I AM AUTHORIZED' to continue: YES I AM AUTHORIZED

Are you sure you want to continue?
Type 'CONTINUE' to proceed: CONTINUE

╔═══════════════════════════════════════════════════════════════╗
║                      SCAN STATISTICS                          ║
║  Scan Rate:           50,000 pps                             ║
║  Total Probes:        24,000,000,000 probes                  ║
║  Estimated Time:      480,000 seconds (~5.5 days)            ║
╚═══════════════════════════════════════════════════════════════╝

[*] Starting scan...
[+] 1.2.3.4:11434 - Ollama (200, version-detected)
[+] 5.6.7.8:8000 - vLLM (200)
[+] 9.10.11.12:8000 - Llama.cpp (200)
...
```

---

## 🚦 **YOU ARE GO FOR LAUNCH!**

Everything is ready. The scanner is built, tested, and configured.

**To launch the scan:**

```bash
docker-compose run --rm xtate-scanner /xtate/scripts/scan-internet-llm.sh
```

**Remember:**
- ✅ Ensure you have authorization
- ✅ Start with a test scan
- ✅ Monitor results
- ✅ Be responsible

**Good luck and scan responsibly!** 🚀

---

For more information:
- [INTERNET-SCAN-GUIDE.md](INTERNET-SCAN-GUIDE.md) - Complete scanning guide
- [DOCKER.md](DOCKER.md) - Docker usage details
- [LLM-SCANNING.md](LLM-SCANNING.md) - LLM detection details
