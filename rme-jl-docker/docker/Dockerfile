FROM julia:1.12.1

WORKDIR /app

# Copy project files for dependency installation
COPY ./src /app/src
COPY ./Manifest.toml /app/
COPY ./Project.toml /app/
# The RME src will use.
COPY ./rme_ml /app/rme_ml

# Initialize Julia environment, install dependencies, and precompile
RUN julia -t auto --project=. -e "using Pkg; Pkg.instantiate(); using ReefModEngine; Pkg.precompile();"

# Copy entrypoint script
COPY ./docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set entrypoint to validate mounts, then run Julia
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "julia", "--project=.", "-t", "auto"]

# Default: run script at the configured path (can be overridden)
CMD ["/app/run_script.jl"]
