#!/bin/bash
#
# LLM Inference Service Scanner
# Wrapper script for scanning LLM/AI inference services using Xtate
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XTATE_BIN="$PROJECT_ROOT/bin/xtate"
RESULTS_DIR="$PROJECT_ROOT/results"
CONF_FILE="$PROJECT_ROOT/data/llm-scan.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS] -ip TARGET_IPS

Scan for open LLM/AI inference services (Ollama, vLLM, Llama.cpp, Triton, etc.)

Required Arguments:
  -ip TARGETS          IP addresses/ranges to scan (e.g., 10.0.0.0/8, 192.168.1.1-255)

Optional Arguments:
  -p PORTS             Override default ports (default: 8000,8001,8002,11434,1234,4891)
  -r RATE              Packet rate in pps (default: 10000)
  --local              Scan local network only (192.168.0.0/16)
  --internet           Scan public internet (excludes private IPs)
  --aggressive         Enable aggressive scanning (all endpoints)
  --interface IF       Network interface to use (default: auto-detect)
  --output DIR         Output directory (default: ./results)
  --config FILE        Use custom config file
  -h, --help           Show this help message

Examples:
  # Scan local network for LLM services
  $0 -ip 192.168.1.0/24

  # Scan specific subnet at high speed
  $0 -ip 10.0.0.0/16 -r 50000

  # Scan custom ports on specific hosts
  $0 -ip 192.168.1.100-200 -p 8000,11434

  # Scan public internet (requires root/sudo)
  sudo $0 -ip 0.0.0.0/0 --internet -r 100000

  # Aggressive scan with all detection methods
  $0 -ip 172.16.0.0/12 --aggressive

Service Detection:
  This scanner detects the following LLM inference platforms:
  - Ollama (port 11434)
  - vLLM (port 8000)
  - Llama.cpp / llama-cpp-python (port 8000)
  - NVIDIA Triton Inference Server (ports 8000/8001/8002)
  - LM Studio (port 1234)
  - GPT4All (port 4891)

EOF
}

# Print colored message
print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check if xtate binary exists
check_binary() {
    if [ ! -f "$XTATE_BIN" ]; then
        print_error "Xtate binary not found at $XTATE_BIN"
        print_info "Please build the project first: ./build.sh"
        exit 1
    fi

    if [ ! -x "$XTATE_BIN" ]; then
        print_error "Xtate binary is not executable"
        print_info "Run: chmod +x $XTATE_BIN"
        exit 1
    fi
}

# Check if running as root (required for raw sockets)
check_root() {
    if [ "$EUID" -ne 0 ] && [ "$SKIP_ROOT_CHECK" != "1" ]; then
        print_warning "Not running as root. Raw socket operations may fail."
        print_info "Consider running with sudo for better performance."
        echo ""
    fi
}

# Create results directory
setup_results_dir() {
    mkdir -p "$RESULTS_DIR"
}

# Parse command line arguments
TARGETS=""
PORTS="8000,8001,8002,11434,1234,4891"
RATE="10000"
SCAN_MODE="normal"
AGGRESSIVE=""
INTERFACE=""
OUTPUT_DIR="$RESULTS_DIR"
CUSTOM_CONFIG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -ip)
            TARGETS="$2"
            shift 2
            ;;
        -p)
            PORTS="$2"
            shift 2
            ;;
        -r)
            RATE="$2"
            shift 2
            ;;
        --local)
            SCAN_MODE="local"
            shift
            ;;
        --internet)
            SCAN_MODE="internet"
            shift
            ;;
        --aggressive)
            AGGRESSIVE="-aggressive"
            shift
            ;;
        --interface)
            INTERFACE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --config)
            CUSTOM_CONFIG="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$TARGETS" ]; then
    print_error "Target IP addresses are required"
    usage
    exit 1
fi

# Set defaults based on scan mode
if [ "$SCAN_MODE" == "local" ]; then
    TARGETS="192.168.0.0/16"
    print_info "Local network scan mode: targeting $TARGETS"
fi

# Main execution
main() {
    print_info "LLM Inference Service Scanner"
    echo ""

    check_binary
    check_root
    setup_results_dir

    print_info "Configuration:"
    echo "  Targets:   $TARGETS"
    echo "  Ports:     $PORTS"
    echo "  Rate:      $RATE pps"
    echo "  Mode:      $SCAN_MODE"
    echo "  Output:    $OUTPUT_DIR"
    echo ""

    # Build command
    CMD="$XTATE_BIN"

    # Add IP targets
    CMD="$CMD -ip $TARGETS"

    # Add ports
    CMD="$CMD -p $PORTS"

    # Add scan and probe modules
    CMD="$CMD -scan zbanner -probe llm-inference"

    # Add probe arguments
    if [ -n "$AGGRESSIVE" ]; then
        CMD="$CMD -probe-arg \"$AGGRESSIVE -detect-version\""
    else
        CMD="$CMD -probe-arg \"-detect-version\""
    fi

    # Add rate
    CMD="$CMD -rate $RATE"

    # Add output
    CMD="$CMD -output text,csv,ndjson"
    CMD="$CMD -output-file $OUTPUT_DIR/llm-scan.txt"
    CMD="$CMD -output-arg-csv \"-file $OUTPUT_DIR/llm-scan.csv\""
    CMD="$CMD -output-arg-ndjson \"-file $OUTPUT_DIR/llm-scan.ndjson\""

    # Add interface if specified
    if [ -n "$INTERFACE" ]; then
        CMD="$CMD --interface $INTERFACE"
    fi

    # Add exclusions for internet scan
    if [ "$SCAN_MODE" == "internet" ]; then
        CMD="$CMD --exclude-file $PROJECT_ROOT/data/exclude-private.conf"
    fi

    # Add show all
    CMD="$CMD --show all"

    print_info "Starting scan..."
    print_info "Command: $CMD"
    echo ""

    # Execute
    eval "$CMD"

    echo ""
    print_success "Scan complete!"
    print_info "Results saved to: $OUTPUT_DIR/"
    echo ""

    # Show summary if results exist
    if [ -f "$OUTPUT_DIR/llm-scan.txt" ]; then
        print_info "Results summary:"
        grep -c "llm-inference" "$OUTPUT_DIR/llm-scan.txt" || echo "  No services found"
    fi
}

main
