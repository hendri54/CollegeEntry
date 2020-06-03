## --------------   Access methods

Base.show(io :: IO, e :: AbstractEntrySwitches) =
    print(io, typeof(e));
Base.show(io :: IO, e :: AbstractEntryDecision) =
    print(io, typeof(e), ":  preference scale ",  
        round(entry_pref_scale(e), digits = 2));

min_entry_prob(e :: AbstractEntryDecision{F1}) where F1 = e.switches.minEntryProb;
max_entry_prob(e :: AbstractEntryDecision{F1}) where F1 = e.switches.maxEntryProb;

fix_entry_probs!(e :: AbstractEntryDecision) = fix_entry_probs!(e.switches);
fix_entry_probs!(switches :: AbstractEntrySwitches) = switches.fixEntryProbs = true;

entry_probs_fixed(e :: AbstractEntryDecision) = e.switches.fixEntryProbs;
entry_pref_scale(e :: AbstractEntryDecision) = e.entryPrefScale;

n_locations(e :: AbstractEntryDecision) = n_locations(e.switches);
n_locations(e :: AbstractEntryResults) = n_locations(e.switches);
n_locations(switches :: AbstractEntrySwitches) = switches.nLocations;
# n_locations(switches :: EntryDecisionSwitches{F1}) where F1 = 
#     size(switches.typeMass_jlM, 2);

value_local(e :: AbstractEntryDecision) = value_local(e.switches);
value_local(switches :: AbstractEntrySwitches{F1}) where F1 = switches.valueLocal;
# value_local(a :: EntryDecision{F1}) where F1 = a.valueLocal;

n_types(e :: AbstractEntryDecision) = n_types(e.switches);
n_types(er :: AbstractEntryResults{F1}) where F1 = n_types(er.switches);
n_types(switches :: AbstractEntrySwitches{F1}) where F1 = switches.nTypes;

n_colleges(e :: AbstractEntryDecision) = n_colleges(e.switches);
n_colleges(er :: AbstractEntryResults{F1}) where F1 = n_colleges(er.switches);
n_colleges(switches :: AbstractEntrySwitches{F1}) where F1 = switches.nColleges;

"""
	$(SIGNATURES)

Mass of each type. Only plays a role when colleges have capacities. Set to 1 otherwise. By location, if available.
"""
type_mass(a :: AbstractEntryDecision{F1}, j :: Integer) where F1 = 
    type_mass(a.switches, j);
type_mass(switches :: AbstractEntrySwitches{F1}, j :: Integer) where F1 = 
    switches.typeMass_jlM[j, :];

type_mass(a :: AbstractEntryDecision{F1}, j :: Integer, l :: Integer) where F1 = 
    type_mass(a.switches, j, l);
type_mass(switches :: AbstractEntrySwitches{F1}, j, l) where F1 = 
    switches.typeMass_jlM[j, l];

# By location, if any
type_masses(a :: AbstractEntryDecision{F1}) where F1 = type_masses(a.switches);
type_masses(e :: AbstractEntryResults{F1}) where F1 = type_masses(e.switches);
type_masses(switches :: AbstractEntrySwitches{F1}) where F1 = 
    switches.typeMass_jlM;


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

# --------------