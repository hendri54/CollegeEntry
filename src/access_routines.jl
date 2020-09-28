## --------------   Access methods

Base.show(io :: IO, e :: AbstractEntrySwitches) =
    print(io, typeof(e));
Base.show(io :: IO, e :: AbstractEntryDecision) =
    print(io, typeof(e), 
        ":  preference scale ",  round(entry_pref_scale(e), digits = 2),
        "  ",  n_colleges(e), " colleges  ",  n_locations(e), " locations.");

min_entry_prob(e :: AbstractEntryDecision{F1}) where F1 = min_entry_prob(e.switches);
min_entry_prob(switches :: AbstractEntrySwitches) = switches.minEntryProb;
max_entry_prob(e :: AbstractEntryDecision{F1}) where F1 = max_entry_prob(e.switches);
max_entry_prob(switches :: AbstractEntrySwitches) = switches.maxEntryProb;

fix_entry_probs!(e :: AbstractEntryDecision) = fix_entry_probs!(e.switches);
fix_entry_probs!(switches :: AbstractEntrySwitches) = switches.fixEntryProbs = true;

entry_probs_fixed(e :: AbstractEntryDecision) = e.switches.fixEntryProbs;
entry_pref_scale(e :: AbstractEntryDecision) = e.entryPrefScale;

# Colleges that can only be attended locally
local_only_colleges(switches :: AbstractEntrySwitches) = 
    switches.localOnlyIdxV;
local_only_colleges(e :: AbstractEntryDecision) = local_only_colleges(e.switches);

"""
	$(SIGNATURES)

Mark which colleges can be attended by locals only.
"""
function set_local_only_colleges!(switches :: AbstractEntrySwitches, icV)
    if !isempty(icV)
        @assert all(icV .>= 1)  &&  all(icV .<= n_colleges(switches));
        switches.localOnlyIdxV = deepcopy(icV);
    end
    return nothing
end


"""
	$(SIGNATURES)

Number of locations.
"""
n_locations(e :: AbstractEntryDecision) = n_locations(e.switches);
n_locations(e :: AbstractEntryResults) = n_locations(e.switches);
n_locations(switches :: AbstractEntrySwitches) = switches.nLocations;
# n_locations(switches :: EntryDecisionSwitches{F1}) where F1 = 
#     size(switches.typeMass_jlM, 2);

value_local(e :: AbstractEntryDecision) = value_local(e.switches);
value_local(switches :: AbstractEntrySwitches{F1}) where F1 = switches.valueLocal;
# value_local(a :: EntryDecision{F1}) where F1 = a.valueLocal;

"""
	$(SIGNATURES)

Number of student types.
"""
n_types(e :: AbstractEntryDecision) = n_types(e.switches);
n_types(er :: AbstractEntryResults{F1}) where F1 = n_types(er.switches);
n_types(switches :: AbstractEntrySwitches{F1}) where F1 = switches.nTypes;

"""
	$(SIGNATURES)

Number of colleges.
"""
n_colleges(e :: AbstractEntryDecision) = n_colleges(e.switches);
n_colleges(er :: AbstractEntryResults{F1}) where F1 = n_colleges(er.switches);
n_colleges(switches :: AbstractEntrySwitches{F1}) where F1 = switches.nColleges;

"""
	$(SIGNATURES)

Mass of each type. Only plays a role when colleges have capacities. Set to 1 otherwise. By location, if available.
"""
type_mass_jl(a :: AbstractEntryDecision{F1}, j :: Integer) where F1 = 
    type_mass_jl(a.switches, j);
type_mass_jl(switches :: AbstractEntrySwitches{F1}, j :: Integer) where F1 = 
    switches.typeMass_jlM[j, :];

type_mass_jl(a :: AbstractEntryDecision{F1}, j :: Integer, l :: Integer) where F1 = 
    type_mass_jl(a.switches, j, l);
type_mass_jl(switches :: AbstractEntrySwitches{F1}, j, l) where F1 = 
    switches.typeMass_jlM[j, l];

# By location, if any
type_mass_jl(a :: AbstractEntryDecision{F1}) where F1 = type_mass_jl(a.switches);
type_mass_jl(e :: AbstractEntryResults{F1}) where F1 = type_mass_jl(e.switches);
type_mass_jl(switches :: AbstractEntrySwitches{F1}) where F1 = 
    switches.typeMass_jlM;

type_mass_j(a :: AbstractEntryDecision{F1}) where F1 = type_mass_j(a.switches);
type_mass_j(e :: AbstractEntryResults{F1}) where F1 = type_mass_j(e.switches);
type_mass_j(switches :: AbstractEntrySwitches{F1}) where F1 = 
    vec(sum(switches.typeMass_jlM, dims = 2));
    
type_mass_j(a :: AbstractEntryDecision{F1}, j :: Integer) where F1 = 
    type_mass_j(a.switches, j);
type_mass_j(e :: AbstractEntryResults{F1}, j :: Integer) where F1 = 
    type_mass_j(e.switches, j);
type_mass_j(switches :: AbstractEntrySwitches{F1}, j :: Integer) where F1 = 
    sum(switches.typeMass_jlM[j,:]);
    

"""
	$(SIGNATURES)

College capacities. Set to an arbitrary large number for entry mechanisms where capacities do not matter.
"""
capacities(a :: AbstractEntryDecision{F1}) where F1 = capacities(a.switches);
capacities(e :: AbstractEntryResults{F1}) where F1 = capacities(e.switches);
capacities(switches :: AbstractEntrySwitches{F1}) where F1 = 
    switches.capacity_clM;

"""
	$(SIGNATURES)

Set college capacities.
"""    
function set_capacities!(switches :: AbstractEntrySwitches{F1}, 
    capacity_clM :: Matrix{F1}) where F1

    @assert size(capacity_clM) == size(switches.capacity_clM)
    switches.capacity_clM = capacity_clM;
    return nothing
end

"""
	$(SIGNATURES)

Increase one college capacities by a factor.
"""
increase_capacity!(switches :: AbstractEntrySwitches{F1}, 
    cFactor :: F1, cIdx :: Integer) where F1 = 
    switches.capacity_clM[cIdx,:] .*= cFactor;


"""
	$(SIGNATURES)

Increase all college capacities by a common factor.
"""
increase_capacities!(switches :: AbstractEntrySwitches{F1}, 
    cFactor :: F1) where F1 = 
    switches.capacity_clM .*= cFactor;

"""
	$(SIGNATURES)

Capacities; summed across locations
"""
capacities_c(a :: AbstractEntryDecision{F1}) where F1 = capacities_c(a.switches);
capacities_c(e :: AbstractEntryResults{F1}) where F1 = capacities_c(e.switches);
capacities_c(switches :: AbstractEntrySwitches{F1}) where F1 = 
    vec(sum(switches.capacity_clM, dims = 2));


"""
	$(SIGNATURES)

Capacity of one college by location.
"""
capacity(e :: AbstractEntryDecision{F1}, iCollege :: Integer) where F1 = 
    capacity(e.switches, iCollege);
capacity(switches :: AbstractEntrySwitches{F1}, iCollege :: Integer) where F1 = 
    switches.capacity_clM[iCollege, :];

capacity(e :: AbstractEntryDecision{F1}, iCollege :: Integer, 
    l :: Integer) where F1 = capacity(e.switches, iCollege, l);
capacity(switches :: AbstractEntrySwitches{F1}, iCollege :: Integer,
    l :: Integer) where F1 = switches.capacity_clM[iCollege, l];

limited_capacity(a :: AbstractEntryDecision{F1}) where F1 = 
    limited_capacity(a.switches);
limited_capacity(switches:: AbstractEntrySwitches{F1}) where F1 = 
    any(capacities(switches) .< CapacityInf);


# Change the number of types
# Useful for solving with a subset of types, keeping in mind that 
# capacity constraints likely won't bind with fewer types.
function subset_types!(switches :: EntryDecisionSwitches{F1}, typeV :: AbstractVector{I1}) where {F1, I1 <: Integer}

    @assert maximum(typeV) <= n_types(switches)
    switches.nTypes = length(typeV);
    switches.typeMass_jlM = switches.typeMass_jlM[typeV, :];
    @assert validate_es(switches)
    return nothing
end


"""
	$(SIGNATURES)

Adjust the `EntryDecision` so that only a subset of types is kept.
Useful for solving with a subset of types, keeping in mind that 
capacity constraints likely won't bind with fewer types.
`deepcopy(entryS)` first to keep the original `EntryDecision` unchanged.
"""
subset_types!(entryS :: EntryDecision{F1}, typeV :: AbstractVector{I1}) where {F1, I1 <: Integer} =
    subset_types!(entryS.switches, typeV);

# --------------