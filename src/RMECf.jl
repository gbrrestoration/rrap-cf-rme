module RMECf

# Adapted from https://open-aims.github.io/ReefModEngine.jl/v1.4.1/getting_started#Example-usage
using ReefModEngine
using CSV, DataFrames

export run

"""
    run()

Execute a ReefMod Engine simulation run using parameters from environment variables.

# Required Environment Variables
- `RME_PATH`: Location of the ReefMod Engine data files
- `OUTPUTS_PATH`: Output directory for simulation results
- `RUN_NAME`: Name to associate with this set of runs
- `START_YEAR`: Simulation start year
- `END_YEAR`: Simulation end year
- `RCP_SCEN`: RCP/SSP scenario (e.g., "SSP 2.45")
- `GCM`: Global Climate Model (e.g., "CNRM_ESM2_1")
- `REPS`: Number of random environmental sequences to run

# Optional Environment Variables
- `THREAD_COUNT`: Number of threads to use (default: "2")
- `USE_FIXED_SEED`: Use fixed random seed (default: "1")
- `FIXED_SEED`: Fixed seed value (default: "123.0")
- `D_DENSITY_M2`: Coral outplanting density per m² (default: "6.8")
- `RUN_ID`: Run identifier (default: "0")
- `TARGET`: Target locations mode - "FULL", "MEDIUM", "SMALL", "GBRMPA_GENERAL_MANAGEMENT_ZONES", "GBRMPA_PRESERVATION_ZONES", "MOORE_REEF_CLUSTER", or "NORTH_GBR" (default: "default")
"""
function run()
    # Mount paths: These 2 are checked in entrypoint and have defaults in the image build. They can be overriden in CDK config.
    rme_path = get(ENV, "RME_PATH", nothing)
    outputs_path = get(ENV, "OUTPUTS_PATH", nothing)
    if isnothing(rme_path)
        error("RME_PATH environment variable not set. Please set it to the location of the ReefMod Engine data files.")
    end
    if isnothing(outputs_path)
        error("OUTPUTS_PATH environment variable not set. Please set it to the desired output directory for this run.")
    end

    # ENV with Defaults 
    thread_count = parse(Int, get(ENV, "THREAD_COUNT", "2"))  #* For ECS, set in cdk (others to set in DAG) https://github.com/gbrrestoration/rrap-cf-aws-infra/blob/main/lib/rrap-cf-airflow-stack.ts
    # Turn on use of a fixed seed value
    use_fixed_seed = parse(Int, get(ENV, "USE_FIXED_SEED", "1"))
    # Set the fixed seed value
    fixed_seed = parse(Float64, get(ENV, "FIXED_SEED", "123.0"))
    # Define coral outplanting density (per m²)
    d_density_m² = parse(Float64, get(ENV, "D_DENSITY_M2", "6.8"))  # e.g., 1.0 coral per m²
    # optional run ID. default to 0
    run_id = get(ENV, "RUN_ID", "0")

    # Non default ENV vars
    target_locations_mode = get(ENV, "TARGET", "default") # one of ["FULL", "MEDIUM", "SMALL", "GBRMPA_GENERAL_MANAGEMENT_ZONES", "GBRMPA_PRESERVATION_ZONES", "MOORE_REEF_CLUSTER", "NORTH_GBR"]
    # Name to associate with this set of runs
    name = get(ENV, "RUN_NAME", nothing)
    start_year = parse(Int, get(ENV, "START_YEAR", nothing))
    end_year = parse(Int, get(ENV, "END_YEAR", nothing))
    # RCP/SSP scenario to use
    RCP_scen = get(ENV, "RCP_SCEN", nothing)
    # The base Global Climate Model (GCM)
    gcm = get(ENV, "GCM", nothing)
    # Number of repeats: number of random environmental sequences to run
    reps = parse(Int, get(ENV, "REPS", nothing))  

    # Assert target locations set properly and then set path
    if target_locations_mode == "FULL"
        target_locations_path = "./target_locations/target_locations_full.csv"
    elseif target_locations_mode == "MEDIUM"
        target_locations_path = "./target_locations/target_locations_medium.csv"
    elseif target_locations_mode == "SMALL"
        target_locations_path = "./target_locations/target_locations_small.csv"
    elseif target_locations_mode == "GBRMPA_GENERAL_MANAGEMENT_ZONES"
        target_locations_path = "./target_locations/target_locations_gbrmpa_general_management_zones.csv"
    elseif target_locations_mode == "GBRMPA_PRESERVATION_ZONES"
        target_locations_path = "./target_locations/target_locations_gbrmpa_preservation_zones.csv"
    elseif target_locations_mode == "MOORE_REEF_CLUSTER"
        target_locations_path = "./target_locations/target_locations_moore_reef_cluster.csv"
    elseif target_locations_mode == "NORTH_GBR"
        target_locations_path = "./target_locations/target_locations_north_gbr.csv"
    else
        error("TARGET environment variable set to invalid value. Please set it to one of: FULL, MEDIUM, SMALL, GBRMPA_GENERAL_MANAGEMENT_ZONES, GBRMPA_PRESERVATION_ZONES, MOORE_REEF_CLUSTER, NORTH_GBR.")
    end

    if isnothing(name)
        error("RUN_NAME environment variable not set. Please set it to the desired name for this run.")
    end
    if isnothing(start_year)
        error("START_YEAR environment variable not set. Please set it to the desired start year for this run.")
    end
    if isnothing(end_year)
        error("END_YEAR environment variable not set. Please set it to the desired end year for this run.")
    end
    if isnothing(RCP_scen)
        error("RCP_SCEN environment variable not set. Please set it to the desired RCP/SSP scenario for this run.")
    end
    if isnothing(gcm)
        error("GCM environment variable not set. Please set it to the desired Global Climate Model for this run.")
    end
    if isnothing(reps)
        error("REPS environment variable not set. Please set it to the desired number of repeats for this run.")
    end

    init_rme(rme_path)

    set_option("thread_count", thread_count) #! set threads. seems not to go past 2 on my 4 core machine. 
    set_option("use_fixed_seed", use_fixed_seed)  
    set_option("fixed_seed", fixed_seed)  

    # Load target intervention locations determined somehow (e.g., by ADRIA)
    # The first column is simply the row number.
    # The second column is a list of target reef ids matching the format as found in
    # the id list file (the file is found under `data_files/id` of the RME data set)
    deploy_loc_details = CSV.read(
        target_locations_path,
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

    n_reefs = length(reef_id_list)

    # Get reef areas from RME
    reef_area_km² = reef_areas()

    # Get list of areas for the target reefs
    target_reef_areas_km² = reef_areas(target_reef_ids)

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
    # set_outplant_deployment!("outplant_iv_2028_2030", "iv_example", Int64(1.1e6), Int64(1.1e6), 2028, 2030, 1, target_reef_areas_km², d_density_m²)

    # If no deployment density is specified, ReefModEngine.jl will attempt to calculate the
    # most appropriate density to maintain the specified grid size (defaulting to 10x10).
    set_outplant_deployment!("outplant_iv_2026", "iv_example", 100_000, 2026, target_reef_areas_km²)
    set_outplant_deployment!("outplant_iv_2027", "iv_example", 500_000, 2027, target_reef_areas_km²)
    set_outplant_deployment!("outplant_iv_2028_2030", "iv_example", Int64(1.1e6), 2028, 2030, 1, target_reef_areas_km²)

    # Initialize RME runs as defined above
    run_init()

    # Run all years and all reps
    @time @RME runProcess()::Cint

    # Collect and store results
    concat_results!(result_store, start_year, end_year, reps)

    save_result_store(joinpath(outputs_path, run_id), result_store)
end

end
