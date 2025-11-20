#!/bin/bash
set -e

if [ ! -d $OUTPUTS_PATH ]; then
    echo "ERROR: Output directory mount is required but not found at: $OUTPUTS_PATH. Customise this path with the OUTPUTS_PATH environment variable."
    exit 1
fi

if [ ! -d $RME_PATH ]; then
    echo "ERROR: RME directory mount is required but not found at: $RME_PATH. Customise this path with the RME_PATH environment variable."
    echo "IMPORTANT NOTE : This RME must have the reefmod_gbr.gpkg inside /path/to/rme/data_files/region. See step 1 of https://open-aims.github.io/ReefModEngine.jl/v1.4.1/getting_started#Pre-initialization-setup. Step 2 is not required in this image."
    exit 1
fi



echo "✓ All required volume mounts validated"
echo "  - Script: /app/run_script.jl"
echo "  - Data: /app/target_locations.csv"
echo "  - Output: /app/outputs"

# If all checks pass, execute the provided command
exec "$@"
