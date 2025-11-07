#!/bin/bash
set -e

# Check if required volume mounts exist
if [ ! -f "/app/run_script.jl" ]; then
    echo "ERROR: Script file mount is required but not found at: /app/run_script.jl"
    echo "Usage: docker run -v /path/to/your_script.jl:/app/run_script.jl ..."
    exit 1
fi

if [ ! -f "/app/target_locations.csv" ]; then
    echo "ERROR: Data file mount is required but not found at: /app/target_locations.csv"
    echo "Usage: docker run -v /path/to/target_locations.csv:/app/target_locations.csv ..."
    exit 1
fi

if [ ! -d "/app/outputs" ]; then
    echo "ERROR: Output directory mount is required but not found at: /app/outputs"
    echo "Usage: docker run -v /path/to/outputs:/app/outputs ..."
    exit 1
fi

echo "✓ All required volume mounts validated"
echo "  - Script: /app/run_script.jl"
echo "  - Data: /app/target_locations.csv"
echo "  - Output: /app/outputs"

# If all checks pass, execute the provided command
exec "$@"
