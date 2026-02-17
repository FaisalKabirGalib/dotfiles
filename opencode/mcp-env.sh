#!/bin/bash
# Opencode MCP Environment Variables
# This file should be sourced before running opencode to load API keys
# Add to .gitignore or keep private

export CONTEXT7_API_KEY=$(pass ApiKey/context7/personal | head -n 1)
export ZAI_API_KEY=$(pass ApiKey/ZAi/opencode | head -n 1)
export ZAI_WEB_SEARCH_KEY=$(pass ApiKey/ZAi/opencode | head -n 1)
export REF_API_KEY=$(pass ApiKey/Ref | head -n 1)
