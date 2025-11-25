# Docker ReefModEngine.jl Engine

Ensure your RME is installed at rme_ml inside this directory. See [here](https://open-aims.github.io/ReefModEngine.jl/v1.4.1/getting_started#Pre-initialization-setup)
Configure target locations in target_locations.csv or leave as the two minimal examples provided.
run_example.jl has the example script.

The docker build will copy in the RME library from rme_ml and other src and build the julia package.
Inspect the docker-compose.yml. The container is desgined to execute the script mounted in with the desired target locations (also mounted in).

Run `docker compose up` to run the container (and it will build too if this is your first time).
