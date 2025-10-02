#!/bin/bash
#
# Internet-Scale LLM Inference Service Scanner
#
# ⚠️  WARNING ⚠️
# This script scans the ENTIRE IPv4 internet!
# Only use this if you have:
# 1. Legal authorization
# 2. Ethical approval
# 3. Sufficient bandwidth and resources
# 4. Understanding of the implications
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCAN_RATE="${SCAN_RATE:-50000}"  # Default 50k pps
TARGET_RANGE="${TARGET_RANGE:-0.0.0.0/0}"  # Default: entire internet
OUTPUT_DIR="${OUTPUT_DIR:-/xtate/results}"

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║        INTERNET-SCALE LLM INFERENCE SERVICE SCANNER           ║"
    echo "║                                                               ║"
    echo "║  Scanning for: Ollama, vLLM, Llama.cpp, Triton, LM Studio   ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print warning
print_warning() {
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                       ⚠️  WARNING ⚠️                           ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║                                                               ║"
    echo "║  You are about to scan the ENTIRE IPv4 INTERNET!             ║"
    echo "║                                                               ║"
    echo "║  This requires:                                               ║"
    echo "║   • Legal authorization from network owner                    ║"
    echo "║   • Ethical approval from your institution                    ║"
    echo "║   • Understanding of scanning laws in your jurisdiction       ║"
    echo "║   • Significant bandwidth and compute resources               ║"
    echo "║                                                               ║"
    echo "║  Unauthorized scanning may be ILLEGAL and UNETHICAL!          ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print scan info
print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning_msg() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Confirmation prompt
confirm_scan() {
    echo ""
    echo -e "${YELLOW}Do you have legal authorization to scan the target network?${NC}"
    read -p "Type 'YES I AM AUTHORIZED' to continue: " -r
    echo ""

    if [[ ! $REPLY == "YES I AM AUTHORIZED" ]]; then
        print_error "Scan cancelled. Authorization required."
        exit 1
    fi

    echo -e "${YELLOW}Are you sure you want to continue? This will generate significant traffic.${NC}"
    read -p "Type 'CONTINUE' to proceed: " -r
    echo ""

    if [[ ! $REPLY == "CONTINUE" ]]; then
        print_error "Scan cancelled by user."
        exit 1
    fi
}

# Calculate scan statistics
calculate_stats() {
    local ports="11434,8000,8001,8002,1234,4891"
    local port_count=6
    local total_ipv4=$((2**32))
    local excluded_ips=$((16777216 + 1048576 + 65536 + 16777216 + 268435456))  # Rough estimate of excluded IPs
    local scannable_ips=$((total_ipv4 - excluded_ips))
    local total_probes=$((scannable_ips * port_count))
    local scan_time_seconds=$((total_probes / SCAN_RATE))
    local scan_time_hours=$((scan_time_seconds / 3600))
    local scan_time_days=$((scan_time_hours / 24))

    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                      SCAN STATISTICS                          ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    printf "║  Scan Rate:           %'15d pps                   ║\n" $SCAN_RATE
    printf "║  Target Range:        %-35s║\n" "$TARGET_RANGE"
    printf "║  Ports:               %'15d ports                 ║\n" $port_count
    printf "║  Total IPv4 Space:    %'15d IPs                  ║\n" $total_ipv4
    printf "║  Excluded IPs:        %'15d IPs                  ║\n" $excluded_ips
    printf "║  Scannable IPs:       %'15d IPs                  ║\n" $scannable_ips
    printf "║  Total Probes:        %'15d probes               ║\n" $total_probes
    printf "║  Estimated Time:      %'15d seconds              ║\n" $scan_time_seconds
    printf "║                       %'15d hours                ║\n" $scan_time_hours
    printf "║                       %'15d days                 ║\n" $scan_time_days
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main scan function
run_scan() {
    print_info "Starting internet-scale LLM inference service scan..."
    echo ""

    print_info "Configuration:"
    echo "  Target:    $TARGET_RANGE"
    echo "  Ports:     11434,8000,8001,8002,1234,4891"
    echo "  Rate:      $SCAN_RATE pps"
    echo "  Threads:   4 TX / 4 RX"
    echo "  Output:    $OUTPUT_DIR/"
    echo ""

    # Build command
    CMD="xtate"
    CMD="$CMD -ip $TARGET_RANGE"
    CMD="$CMD -p 11434,8000,8001,8002,1234,4891"
    CMD="$CMD -scan zbanner"
    CMD="$CMD -probe llm-inference"
    CMD="$CMD -probe-arg \"-aggressive -detect-version\""
    CMD="$CMD -rate $SCAN_RATE"
    CMD="$CMD -tx-threads 4 -rx-handlers 4"
    CMD="$CMD --exclude-file /xtate/data/exclude-private.conf"
    CMD="$CMD -output text,csv,ndjson"
    CMD="$CMD -output-file $OUTPUT_DIR/internet-scan.txt"
    CMD="$CMD -output-arg-csv \"-file $OUTPUT_DIR/internet-scan.csv\""
    CMD="$CMD -output-arg-ndjson \"-file $OUTPUT_DIR/internet-scan.ndjson\""
    CMD="$CMD --resume-file $OUTPUT_DIR/internet-scan-resume.conf"
    CMD="$CMD --wait 30"
    CMD="$CMD --show all"

    print_info "Command: $CMD"
    echo ""

    print_success "Scan starting..."
    echo ""

    # Execute scan
    eval "$CMD"

    local EXIT_CODE=$?

    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        print_success "Scan completed successfully!"
    else
        print_error "Scan exited with code $EXIT_CODE"
    fi

    echo ""
    print_info "Results saved to: $OUTPUT_DIR/"
    echo ""

    # Show summary if results exist
    if [ -f "$OUTPUT_DIR/internet-scan.txt" ]; then
        print_info "Results summary:"
        local total_lines=$(wc -l < "$OUTPUT_DIR/internet-scan.txt" 2>/dev/null || echo "0")
        echo "  Total results: $total_lines lines"

        if [ -f "$OUTPUT_DIR/internet-scan.csv" ]; then
            local csv_lines=$(($(wc -l < "$OUTPUT_DIR/internet-scan.csv") - 1))
            echo "  Services found: ~$csv_lines"
        fi
    fi

    echo ""
    print_success "Scan complete!"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rate)
            SCAN_RATE="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_RANGE="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -r, --rate RATE       Scan rate in packets per second (default: 50000)"
            echo "  -t, --target RANGE    Target IP range (default: 0.0.0.0/0)"
            echo "  -y, --yes             Skip confirmation prompts (USE WITH CAUTION!)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Scan entire internet at 50k pps"
            echo "  $0 --rate 100000                      # Scan at 100k pps"
            echo "  $0 --target 1.0.0.0/8                 # Scan specific range"
            echo "  $0 --rate 200000 --target 8.8.0.0/16 # Custom rate and range"
            echo ""
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_banner
    print_warning

    if [ -z "$SKIP_CONFIRM" ]; then
        confirm_scan
    fi

    calculate_stats

    echo ""
    print_warning_msg "Last chance to cancel! Press Ctrl+C within 10 seconds..."
    sleep 10
    echo ""

    run_scan
}

main
