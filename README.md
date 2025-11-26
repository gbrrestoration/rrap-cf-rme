# Docker ReefModEngine.jl Engine

Ensure your RME is installed at rme_ml inside this directory. See [here](https://open-aims.github.io/ReefModEngine.jl/v1.4.1/getting_started#Pre-initialization-setup)
Configure target locations in target_locations.csv or leave as the two minimal examples provided.
run_example.jl has the example script.

The docker build will copy in the RME library from rme_ml and other src and build the julia package.
Inspect the docker-compose.yml. The container is desgined to execute the script mounted in with the desired target locations (also mounted in).

Run `docker compose up` to run the container (and it will build too if this is your first time).


## Postprocess target locations

We have provided a list of target locations.
* For testing: target_locations_small.csv (2), target_locations_medium.csv (194), target_locations_full.csv (3806)
* GBRMPA Zones: target_locations_gbrmpa_general_management_zones.csv and target_locations_gbrmpa_preservation_zones.csv
* Clusters: Moore Reef

The have been exported from Canonical reefs using values from the `RME_GBRMPA_ID` field. More target locations could be added.

Run the following perl command to make target locations use uppercase letters as RME expects it that way.
```
$ perl -i -pe '$_ = uc($_)' target_locations/target_locations_full.csv
```