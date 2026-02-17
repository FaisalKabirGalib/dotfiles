#!/bin/bash
# Opencode MCP Environment Variables
# This file should be sourced before running opencode to load API keys
# Add to .gitignore or keep private

export CONTEXT7_API_KEY=$(pass ApiKey/context7/personal)
export ZAI_API_KEY=$(pass ApiKey/ZAi/opencode)
export ZAI_WEB_SEARCH_KEY=$(pass ApiKey/ZAi/opencode)
export REF_API_KEY=$(pass ApiKey/Ref)
