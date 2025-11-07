using ReefModEngine
using CSV, DataFrames

# Initialize RME (may take a minute or two)
init_rme("rme_ml") # TODO fill in path
# [ Info: Loaded RME 1.0.28

set_option("thread_count", 2)  # Set to use two threads # TODO, set threads. seems not to go past 2 on my 4 core machine. 
set_option("use_fixed_seed", 1)  # Turn on use of a fixed seed value
set_option("fixed_seed", 123.0)  # Set the fixed seed value

# Load target intervention locations determined somehow (e.g., by ADRIA)
# The first column is simply the row number.
# The second column is a list of target reef ids matching the format as found in
# the id list file (the file is found under `data_files/id` of the RME data set)
deploy_loc_details = CSV.read(
    "./target_locations.csv",
    DataFrame,
    header=["index_id", "reef_id"],
    types=Dict(1=>Int64, 2=>String)  # Force values to be interpreted as expected types
)

# Reef indices and IDs
target_reef_idx = deploy_loc_details.index_id
target_reef_ids = deploy_loc_details.reef_id
n_target_reefs = length(target_reef_idx)

# Get list of reef ids as specified by ReefMod Engine
reef_id_list = reef_ids()

name = "Example"       # Name to associate with this set of runs
start_year = 2022
end_year = 2099
RCP_scen = "SSP 2.45"  # RCP/SSP scenario to use
gcm = "CNRM_ESM2_1"    # The base Global Climate Model (GCM)
reps = 1               # Number of repeats: number of random environmental sequences to run # TODO, small for testing
n_reefs = length(reef_id_list)

# Get reef areas from RME
reef_area_km² = reef_areas()

# Get list of areas for the target reefs
target_reef_areas_km² = reef_areas(target_reef_ids)

# Define coral outplanting density (per m²)
d_density_m² = 6.8

# Initialize result store
result_store = ResultStore(start_year, end_year)

@info "Starting runs"
reset_rme()  # Reset RME to clear any previous runs

# Note: if the Julia runtime crashes, check that the specified data file location is correct
@RME runCreate(name::Cstring, start_year::Cint, end_year::Cint, RCP_scen::Cstring, gcm::Cstring, reps::Cint)::Cint

# TODO, online page is out of date so this was commented. see getting_start.md in this repo which is more recent than the online doc.
# Adding dhw tolerance was removed in v1.0.31
# Add 3 DHW enhancement to outplanted corals
# set_option("restoration_dhw_tolerance_outplants", 3

# Create a reef set using the target reefs
@RME reefSetAddFromIdList("iv_example"::Cstring, target_reef_ids::Ptr{Cstring}, length(target_reef_ids)::Cint)::Cint

# Deployments occur between 2025 2030
# Year 1: 100,000 outplants; Year 2: 500,000; Year 3: 1,1M; Year 4: 1,1M; Year 5: 1,1M and Year 6: 1,1M.
# set_outplant_deployment!("outplant_iv_2026", "iv_example", 100_000, 2026, target_reef_areas_km², d_density_m²)
# set_outplant_deployment!("outplant_iv_2027", "iv_example", 500_000, 2027, target_reef_areas_km², d_density_m²)

# Can also specify deployments to occur over a range of years
# set_outplant_deployment!("outplant_iv_2028_2031", "iv_example", Int64(1.1e6), Int64(1.1e6), 2028, 2031, 1, target_reef_areas_km², d_density_m²)

# If no deployment density is specified, ReefModEngine.jl will attempt to calculate the
# most appropriate density to maintain the specified grid size (defaulting to 10x10).
set_outplant_deployment!("outplant_iv_2026", "iv_example", 100_000, 2026, target_reef_areas_km²)
set_outplant_deployment!("outplant_iv_2027", "iv_example", 500_000, 2027, target_reef_areas_km²)
set_outplant_deployment!("outplant_iv_2028_2031", "iv_example", Int64(1.1e6), 2028, 2031, 1, target_reef_areas_km²)

# Initialize RME runs as defined above
run_init()

# Run all years and all reps
@time @RME runProcess()::Cint

# Collect and store results
concat_results!(result_store, start_year, end_year, reps)

#TODO - added save function   
save_result_store("./outputs", result_store)