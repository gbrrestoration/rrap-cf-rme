FROM julia:1.12.1

WORKDIR /app

# Try to coerce Julia to build across multiple targets
ENV JULIA_CPU_TARGET=x86_64;haswell;skylake;skylake-avx512;tigerlake

# Copy project files for dependency installation
COPY ./src /app/src
COPY ./Manifest.toml /app/Manifest.toml
COPY ./Project.toml /app/Project.toml
COPY ./target_locations /app/target_locations

# ReefModEngine.jl is not on Julia registry, requiring this step
RUN julia --project=@app \
    -e 'using Pkg; Pkg.add(url="https://github.com/open-AIMS/ReefModEngine.jl", rev="main");'

# Initialize Julia environment, install dependencies, and precompile
RUN julia -t auto --project=. -e "using Pkg; Pkg.instantiate(); using RMECf; Pkg.precompile();"

# Copy entrypoint script
COPY ./docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables for mount paths expected to be fulfilled at runtime. Overridable.
ENV RME_PATH="/app/rme"
ENV OUTPUTS_PATH="/app/outputs"

# Set entrypoint to validate mounts, then run Julia
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "julia", "--project=.", "-t", "auto", "-e"]

# Derived applications can override the commands
CMD ["using RMECf; RMECf.run()"]
