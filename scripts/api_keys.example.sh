#!/usr/bin/env bash
###############################################################################
# API keys for every part of the tutorial (part1, part2, part3, part4).
#
# Copy this file to api_keys.sh, fill in your keys, then load them in the container shell BEFORE running any script:
#     source /home/scripts/api_keys.sh
#
# The configs read the keys from these variables (api_key: "$GEMINI_API_KEY"),
# so you never write a key inside a config file.
# Leave a key empty if you do not use that provider. Local Ollama models need no key.
###############################################################################

# Google Gemini (free tier: https://ai.google.dev/)
export GEMINI_API_KEY=""

# Anthropic Claude (https://console.anthropic.com/)
export ANTHROPIC_API_KEY=""

# OpenAI (https://platform.openai.com/)
export OPENAI_API_KEY=""

# Groq (https://console.groq.com/)
export GROQ_API_KEY=""

# --- Check (do not edit) ---------------------------------------------------------
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "Run this file with 'source', otherwise the keys are not kept:"
    echo "    source ${BASH_SOURCE[0]}"
fi
for _var in GEMINI_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY GROQ_API_KEY; do
    if [ -n "${!_var}" ]; then echo "  [set]     $_var"; else echo "  [not set] $_var"; fi
done
unset _var
