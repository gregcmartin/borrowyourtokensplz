# Internet-Scale LLM Inference Service Scanning Guide

## ⚠️ IMPORTANT WARNING ⚠️

**Scanning the internet requires:**
1. ✅ Legal authorization
2. ✅ Ethical approval
3. ✅ Understanding of laws in your jurisdiction
4. ✅ Appropriate resources (bandwidth, compute)

**Unauthorized scanning may be ILLEGAL!**

---

## Quick Start (Docker)

### 1. Build the Scanner

```bash
docker-compose build
```

### 2. Test the Scanner

Test on a small, authorized network first:

```bash
# Test on localhost (if you have a service running)
docker-compose run --rm xtate-scanner \
  xtate -ip 127.0.0.1 -p 11434 -scan zbanner -probe llm-inference -show all

# Test on your local network (replace with your network)
docker-compose run --rm xtate-scanner \
  xtate -ip 192.168.1.0/24 -p 11434,8000 -scan zbanner -probe llm-inference
```

### 3. Run Internet Scan

⚠️ **Only if you have authorization!**

```bash
docker-compose run --rm xtate-scanner \
  /xtate/scripts/scan-internet-llm.sh
```

Or with custom parameters:

```bash
# Custom scan rate
docker-compose run --rm \
  -e SCAN_RATE=100000 \
  xtate-scanner /xtate/scripts/scan-internet-llm.sh

# Specific IP range
docker-compose run --rm xtate-scanner \
  /xtate/scripts/scan-internet-llm.sh --target 1.0.0.0/8 --rate 100000

# Skip confirmations (USE WITH EXTREME CAUTION!)
docker-compose run --rm xtate-scanner \
  /xtate/scripts/scan-internet-llm.sh --yes
```

---

## Scan Targets

### Default Ports Scanned

| Port | Service |
|------|---------|
| 11434 | Ollama |
| 8000 | vLLM, Llama.cpp, Triton HTTP |
| 8001 | Triton gRPC |
| 8002 | Triton Metrics |
| 1234 | LM Studio |
| 4891 | GPT4All |

### IP Ranges Excluded (Automatically)

- 10.0.0.0/8 (Private)
- 172.16.0.0/12 (Private)
- 192.168.0.0/16 (Private)
- 127.0.0.0/8 (Loopback)
- 169.254.0.0/16 (Link-local)
- 224.0.0.0/4 (Multicast)
- 240.0.0.0/4 (Reserved)
- 0.0.0.0/8 (Current network)
- 255.255.255.255/32 (Broadcast)

---

## Scan Statistics

### Full IPv4 Scan Estimates

**Assumptions:**
- Scan rate: 50,000 pps
- Ports: 6
- Total IPv4: ~4.3 billion addresses
- Excluded: ~300 million addresses
- Scannable: ~4 billion addresses

**Estimated Time:**
- Total probes: ~24 billion
- At 50k pps: ~480,000 seconds
- **~5.5 days** for complete scan

**At Higher Rates:**
- 100k pps: ~2.8 days
- 200k pps: ~1.4 days
- 500k pps: ~13 hours
- 1M pps: ~6.5 hours

---

## Performance Tuning

### Scan Rate Guidelines

| Network | Recommended Rate |
|---------|------------------|
| 1 Gbps | 50,000 - 100,000 pps |
| 10 Gbps | 100,000 - 1,000,000 pps |
| 40 Gbps | 1,000,000+ pps |

### Optimize Docker Performance

```bash
# More CPU cores
docker-compose run --rm \
  --cpus="8" \
  xtate-scanner xtate -ip 0.0.0.0/0 ... -tx-threads 8 -rx-handlers 8

# More memory
docker-compose run --rm \
  --memory="8g" \
  xtate-scanner ...
```

### Distributed Scanning

Split scan across multiple machines:

```bash
# Machine 1
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 1/4 -p 11434,8000 -scan zbanner -probe llm-inference

# Machine 2
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 2/4 -p 11434,8000 -scan zbanner -probe llm-inference

# Machine 3
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 3/4 -p 11434,8000 -scan zbanner -probe llm-inference

# Machine 4
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -shard 4/4 -p 11434,8000 -scan zbanner -probe llm-inference
```

---

## Monitoring Progress

### View Results in Real-Time

```bash
# In another terminal, watch results
docker-compose exec xtate-scanner tail -f /xtate/results/internet-scan.txt

# Count found services
docker-compose exec xtate-scanner wc -l /xtate/results/internet-scan.csv

# View CSV results
docker-compose exec xtate-scanner head -20 /xtate/results/internet-scan.csv
```

### Resume Interrupted Scans

If the scan is interrupted, resume from where it left off:

```bash
docker-compose run --rm xtate-scanner \
  xtate --resume /xtate/results/internet-scan-resume.conf
```

---

## Output Formats

### Text Output

```
[+] 1.2.3.4:11434 - Ollama (status: 200, version-detected)
[+] 5.6.7.8:8000 - vLLM (status: 200)
```

### CSV Output

```csv
timestamp,ip,port,service,status,classification
2025-10-02T12:34:56,1.2.3.4,11434,Ollama,200,service-detected
2025-10-02T12:34:57,5.6.7.8,8000,vLLM,200,service-detected
```

### NDJSON Output

```json
{"timestamp":"2025-10-02T12:34:56","ip":"1.2.3.4","port":11434,"service":"Ollama","classification":"service-detected"}
{"timestamp":"2025-10-02T12:34:57","ip":"5.6.7.8","port":8000,"service":"vLLM","classification":"service-detected"}
```

---

## Safety and Ethics

### Legal Considerations

1. **Authorization Required**: Only scan networks you own or have written permission to scan
2. **Compliance**: Ensure scanning complies with laws in your jurisdiction and target locations
3. **Rate Limiting**: Be respectful of target networks - don't overwhelm services
4. **Responsible Disclosure**: If you find vulnerable services, practice responsible disclosure

### Ethical Guidelines

1. **Purpose**: Use for defensive security, research, or asset discovery only
2. **Transparency**: Be prepared to explain your scanning if contacted
3. **No Exploitation**: Never attempt unauthorized access or exploitation
4. **Data Protection**: Handle discovered service data responsibly

### Best Practices

1. **Start Small**: Always test on authorized networks first
2. **Monitor Impact**: Watch for network issues and adjust rate accordingly
3. **Document Everything**: Keep records of authorization and scanning activities
4. **Respect Opt-Outs**: Honor requests to exclude certain networks

---

## Troubleshooting

### No Results

1. **Check firewall**: Ensure Docker has network access
2. **Increase wait time**: Add `--wait 60` for more time
3. **Verify network**: Test with `ping` or `traceroute`
4. **Check logs**: Look at Docker logs for errors

### Low Scan Rate

1. **Increase resources**: Allocate more CPU/memory to Docker
2. **More threads**: Increase `-tx-threads` and `-rx-handlers`
3. **Check bandwidth**: Ensure network isn't saturated
4. **Reduce rate**: Start lower and increase gradually

### Docker Issues

```bash
# Check container status
docker ps -a

# View logs
docker-compose logs xtate-scanner

# Restart Docker
docker-compose down
docker-compose up -d

# Clean rebuild
docker-compose build --no-cache
```

---

## Advanced Usage

### Custom Scan Scripts

Create your own scan configuration:

```bash
# Mount custom config
docker-compose run --rm \
  -v $(pwd)/my-scan.conf:/xtate/my-scan.conf:ro \
  xtate-scanner xtate -c /xtate/my-scan.conf -ip 0.0.0.0/0
```

### Export Results

```bash
# Copy results from container
docker-compose run --rm \
  -v $(pwd)/results:/output \
  xtate-scanner cp -r /xtate/results/* /output/

# Or use docker cp
docker cp <container-id>:/xtate/results ./results
```

### Process Results

```bash
# Parse JSON results
cat results/internet-scan.ndjson | jq -r '.service' | sort | uniq -c

# Find Ollama instances
grep "Ollama" results/internet-scan.txt

# Extract IPs only
awk -F',' 'NR>1 {print $2}' results/internet-scan.csv
```

---

## Example Scan Scenarios

### 1. Quick Test Scan

```bash
# Scan a single /16 at low rate
docker-compose run --rm xtate-scanner \
  xtate -ip 1.2.0.0/16 -p 11434 -scan zbanner -probe llm-inference -rate 10000
```

### 2. High-Speed Regional Scan

```bash
# Scan APNIC region at high rate
docker-compose run --rm xtate-scanner \
  xtate -ip 1.0.0.0/8 -p 11434,8000 -scan zbanner -probe llm-inference -rate 500000
```

### 3. Complete Internet Scan

```bash
# Full internet scan with all ports
docker-compose run --rm \
  -e SCAN_RATE=100000 \
  xtate-scanner /xtate/scripts/scan-internet-llm.sh
```

### 4. Targeted Port Scan

```bash
# Just Ollama (most common)
docker-compose run --rm xtate-scanner \
  xtate -ip 0.0.0.0/0 -p 11434 -scan zbanner -probe llm-inference -rate 200000
```

---

## Results Analysis

### Post-Scan Analysis

```bash
# Count by service type
awk -F',' 'NR>1 {print $4}' results/internet-scan.csv | sort | uniq -c

# Geographic distribution (requires geoip)
# Parse IPs and lookup locations

# Port distribution
awk -F',' 'NR>1 {print $3}' results/internet-scan.csv | sort | uniq -c

# Response status codes
awk -F',' 'NR>1 {print $5}' results/internet-scan.csv | sort | uniq -c
```

### Visualization

Use the results for:
- Heat maps of LLM service distribution
- Timeline of discovered services
- Service type distribution charts
- Geographic clustering analysis

---

## Support

For issues or questions:
1. Check [LLM-SCANNING.md](LLM-SCANNING.md) for detailed documentation
2. Review [DOCKER.md](DOCKER.md) for Docker-specific help
3. See [BUILD-STATUS.md](BUILD-STATUS.md) for build information

---

## Quick Reference Commands

```bash
# Build
docker-compose build

# Test scan
docker-compose run --rm xtate-scanner xtate --help-probe llm-inference

# Small scan
docker-compose run --rm xtate-scanner \
  xtate -ip 192.168.1.0/24 -p 11434 -scan zbanner -probe llm-inference

# Internet scan (AUTHORIZED ONLY!)
docker-compose run --rm xtate-scanner /xtate/scripts/scan-internet-llm.sh

# Resume scan
docker-compose run --rm xtate-scanner \
  xtate --resume /xtate/results/internet-scan-resume.conf

# View results
tail -f results/internet-scan.txt
```

---

**Remember: Only scan networks you are authorized to scan!** 🔒
