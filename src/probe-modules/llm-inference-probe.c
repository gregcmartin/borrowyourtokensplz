#include "probe-modules.h"

#include <string.h>
#include <ctype.h>

#include "../xconf.h"
#include "../version.h"
#include "../util-data/fine-malloc.h"
#include "../util-data/safe-string.h"
#include "../util-misc/misc.h"
#include "../util-out/logger.h"

/***************************************************************************
 * LLM Inference Service Detection Probe
 *
 * This probe detects open LLM/AI inference services by:
 * 1. Sending HTTP requests to common API endpoints
 * 2. Analyzing responses for LLM service signatures
 * 3. Identifying specific software (Ollama, vLLM, Llama.cpp, etc.)
 ***************************************************************************/

/* Forward declaration for internal x-ref */
extern Probe LlmInferenceProbe;

/* Detection patterns for various LLM services */
static const struct {
    const char *endpoint;
    const char *method;
} llm_probes[] = {
    /* Ollama API endpoints */
    {"/api/tags", "GET"},
    {"/api/version", "GET"},

    /* vLLM / Llama.cpp (OpenAI-compatible) */
    {"/v1/models", "GET"},
    {"/models", "GET"},
    {"/health", "GET"},

    /* NVIDIA Triton */
    {"/v2/health/ready", "GET"},
    {"/v2/models", "GET"},

    {NULL, NULL}
};

struct LLMInferenceConf {
    /* Current probe index */
    unsigned probe_idx;

    /* Custom User-Agent */
    char  *user_agent;
    size_t user_agent_length;

    /* Detection options */
    unsigned aggressive_scan : 1;  /* Try all endpoints vs just basic ones */
    unsigned include_metrics : 1;  /* Include metrics endpoints */
    unsigned detect_version : 1;   /* Try to detect specific versions */
};

static struct LLMInferenceConf llm_conf = {0};

/* Default User-Agent for LLM scanning */
static const char default_user_agent[] = "LLM-Scanner/" XTATE_VERSION;

static ConfRes SET_aggressive(void *conf, const char *name, const char *value) {
    UNUSEDPARM(conf);
    UNUSEDPARM(name);

    llm_conf.aggressive_scan = conf_parse_bool(value);
    return Conf_OK;
}

static ConfRes SET_metrics(void *conf, const char *name, const char *value) {
    UNUSEDPARM(conf);
    UNUSEDPARM(name);

    llm_conf.include_metrics = conf_parse_bool(value);
    return Conf_OK;
}

static ConfRes SET_detect_version(void *conf, const char *name, const char *value) {
    UNUSEDPARM(conf);
    UNUSEDPARM(name);

    llm_conf.detect_version = conf_parse_bool(value);
    return Conf_OK;
}


static ConfRes SET_user_agent(void *conf, const char *name, const char *value) {
    UNUSEDPARM(conf);
    UNUSEDPARM(name);

    FREE(llm_conf.user_agent);
    llm_conf.user_agent_length = strlen(value);
    llm_conf.user_agent = STRDUP(value);

    return Conf_OK;
}

static ConfParam llm_inference_parameters[] = {
    {"aggressive",
     SET_aggressive,
     Type_FLAG,
     {"enable", "disable", 0},
     "Enable aggressive scanning (try all endpoints). Default: disable"},

    {"metrics",
     SET_metrics,
     Type_FLAG,
     {"enable", "disable", 0},
     "Include metrics endpoints in scan. Default: disable"},

    {"detect-version",
     SET_detect_version,
     Type_FLAG,
     {"enable", "disable", 0},
     "Attempt to detect specific software versions. Default: enable"},

    {"user-agent",
     SET_user_agent,
     Type_ARG,
     {0},
     "Set custom User-Agent string"},

    {0}
};

static bool llm_inference_init(const XConf *xconf) {
    UNUSEDPARM(xconf);

    /* Set defaults */
    if (!llm_conf.user_agent) {
        llm_conf.user_agent = STRDUP(default_user_agent);
        llm_conf.user_agent_length = strlen(default_user_agent);
    }

    if (!llm_conf.detect_version) {
        llm_conf.detect_version = 1; /* Enabled by default */
    }

    llm_conf.probe_idx = 0;

    return true;
}

static size_t llm_inference_make_payload(ProbeTarget *target, unsigned char *payload_buf) {
    UNUSEDPARM(target);

    /* Build simple HTTP request */
    const char *endpoint = "/v1/models";  /* Most common endpoint */
    const char *method = "GET";

    /* Format HTTP request - use simple host header */
    int len = snprintf((char *)payload_buf, PM_PAYLOAD_SIZE,
                      "%s %s HTTP/1.1\r\n"
                      "Host: localhost\r\n"
                      "User-Agent: %s\r\n"
                      "Accept: */*\r\n"
                      "Connection: close\r\n"
                      "\r\n",
                      method, endpoint,
                      llm_conf.user_agent);

    if (len < 0 || (size_t)len >= PM_PAYLOAD_SIZE) {
        return 0;
    }

    return (size_t)len;
}

static size_t llm_inference_get_payload_length(ProbeTarget *target) {
    /* Just call make_payload to get the length */
    unsigned char temp_buf[PM_PAYLOAD_SIZE];
    return llm_inference_make_payload(target, temp_buf);
}

static unsigned llm_inference_handle_response(unsigned th_idx, ProbeTarget *target,
                                               const unsigned char *px, unsigned sizeof_px,
                                               OutItem *item) {
    UNUSEDPARM(th_idx);

    if (sizeof_px < 12) {
        item->no_output = 1;
        return 0;
    }

    /* Check for HTTP response */
    if (memcmp(px, "HTTP/", 5) != 0) {
        item->no_output = 1;
        return 0;
    }

    /* Extract status code */
    const char *status_start = (const char *)px + 9;
    int status_code = 0;

    if (sizeof_px > 12 && isdigit(status_start[0])) {
        status_code = (status_start[0] - '0') * 100 +
                     (status_start[1] - '0') * 10 +
                     (status_start[2] - '0');
    }

    /* Look for response body */
    const char *body = NULL;
    size_t body_len = 0;

    for (size_t i = 0; i < sizeof_px - 3; i++) {
        if (px[i] == '\r' && px[i+1] == '\n' &&
            px[i+2] == '\r' && px[i+3] == '\n') {
            body = (const char *)px + i + 4;
            body_len = sizeof_px - (i + 4);
            break;
        }
    }

    /* Service detection based on response patterns */
    const char *service = "unknown-llm";
    const char *details = "";

    if (body && body_len > 0) {
        /* Ollama detection */
        if (safe_memmem(body, body_len, "\"models\":", 9) ||
            safe_memmem(body, body_len, "ollama", 6)) {
            service = "Ollama";
            if (safe_memmem(body, body_len, "\"version\":", 10)) {
                details = "version-detected";
            }
        }
        /* vLLM detection */
        else if (safe_memmem(body, body_len, "vllm", 4) ||
                 safe_memmem(body, body_len, "\"object\":\"list\"", 15)) {
            service = "vLLM";
        }
        /* Llama.cpp detection */
        else if (safe_memmem(body, body_len, "llama", 5) ||
                 safe_memmem(body, body_len, "ggml", 4) ||
                 safe_memmem(body, body_len, "gguf", 4)) {
            service = "Llama.cpp";
        }
        /* NVIDIA Triton detection */
        else if (safe_memmem(body, body_len, "triton", 6) ||
                 safe_memmem(body, body_len, "\"ready\":true", 12)) {
            service = "NVIDIA-Triton";
        }
        /* LM Studio detection */
        else if (safe_memmem(body, body_len, "lm-studio", 9) ||
                 safe_memmem(body, body_len, "lmstudio", 8)) {
            service = "LM-Studio";
        }
        /* GPT4All detection */
        else if (safe_memmem(body, body_len, "gpt4all", 7)) {
            service = "GPT4All";
        }
        /* Generic OpenAI-compatible API */
        else if (safe_memmem(body, body_len, "\"data\":[", 8) &&
                 safe_memmem(body, body_len, "\"id\":", 5)) {
            service = "OpenAI-Compatible-API";
        }
    }

    /* Output results */
    item->level = OUT_SUCCESS;

    /* Set classification to include service type */
    safe_strcpy(item->classification, OUT_CLS_SIZE, service);

    /* Just output banner like echo probe */
    dach_append_banner(&item->probe_report, "banner", px, sizeof_px);

    return 0;
}

static void llm_inference_close(void) {
    FREE(llm_conf.user_agent);
    memset(&llm_conf, 0, sizeof(llm_conf));
}

Probe LlmInferenceProbe = {
    .name = "llm-inference",
    .type = ProbeType_TCP,
    .multi_mode = Multi_Null,
    .multi_num = 1,
    .params = llm_inference_parameters,
    .short_desc = "Detect open LLM/AI inference services",
    .desc =
        "The **llm-inference** probe detects and identifies open LLM/AI inference\n"
        "services including:\n"
        "  - Ollama (default port 11434)\n"
        "  - vLLM (default port 8000)\n"
        "  - Llama.cpp / llama-cpp-python (default port 8000)\n"
        "  - NVIDIA Triton Inference Server (ports 8000/8001/8002)\n"
        "  - LM Studio (default port 1234)\n"
        "  - GPT4All (default port 4891)\n\n"
        "This probe sends HTTP requests to common API endpoints and analyzes\n"
        "responses to identify the specific LLM inference software in use.\n\n"
        "**Examples:**\n\n"
        "Scan for Ollama services on port 11434:\n"
        "  `xtate -p 11434 -ip 0.0.0.0/0 -scan zbanner -probe llm-inference`\n\n"
        "Scan all common LLM ports:\n"
        "  `xtate -p 8000,8001,8002,11434,1234,4891 -ip 10.0.0.0/8 \\\n"
        "    -scan zbanner -probe llm-inference -probe-arg \"-aggressive\"`\n\n"
        "Aggressive scan with version detection:\n"
        "  `xtate -p 1-65535 -ip 192.168.1.0/24 -scan zbanner \\\n"
        "    -probe llm-inference -probe-arg \"-aggressive -detect-version\"`\n",

    .init_cb               = &llm_inference_init,
    .make_payload_cb       = &llm_inference_make_payload,
    .get_payload_length_cb = &llm_inference_get_payload_length,
    .handle_response_cb    = &llm_inference_handle_response,
    .close_cb              = &llm_inference_close,
};
