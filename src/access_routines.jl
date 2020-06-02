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
n_locations(switches :: AbstractEntrySwitches) = 1;
n_locations(switches :: EntrySequMultiLocSwitches{F1}) where F1 = 
    size(switches.typeMass_jlM, 2);

value_local(e :: AbstractEntryDecision) = value_local(e.switches);
value_local(switches :: AbstractEntrySwitches{F1}) where F1 = zero(F1);
value_local(a :: EntrySequMultiLoc{F1}) where F1 = a.valueLocal;

n_types(e :: AbstractEntryDecision) = n_types(e.switches);
n_types(switches :: AbstractEntrySwitches{F1}) where F1 = switches.nTypes;

n_colleges(e :: AbstractEntryDecision) = n_colleges(e.switches);
n_colleges(switches :: AbstractEntrySwitches{F1}) where F1 = switches.nColleges;

"""
	$(SIGNATURES)

Mass of each type. Only plays a role when colleges have capacities. Set to 1 otherwise. By location, if available.
"""
type_mass(a :: AbstractEntryDecision{F1}, j :: Integer) where F1 = 
    type_mass(a.switches, j);
type_mass(a :: AbstractEntryDecision{F1}, j :: Integer, l :: Integer) where F1 = 
    type_mass(a.switches, j, l);

type_mass(e :: AbstractEntrySwitches{F1}, j :: Integer) where F1 = 
    one(F1);
type_mass(a :: EntrySequentialSwitches{F1}, j :: Integer) where F1 = 
    a.typeMass_jV[j];
type_mass(switches :: EntrySequMultiLocSwitches{F1}, j :: Integer) where F1 =
    switches.typeMass_jlM[j, :]
type_mass(a :: EntrySequMultiLocSwitches{F1}, j, l) where F1 = 
    a.typeMass_jlM[j, l];

# By location, if any
type_masses(a :: AbstractEntryDecision{F1}) where F1 = type_masses(a.switches);
type_masses(switches :: AbstractEntrySwitches{F1}) where F1 = 
    ones(F1, n_types(switches));
type_masses(a :: EntrySequentialSwitches{F1}) where F1 = a.typeMass_jV;
type_masses(switches :: EntrySequMultiLocSwitches{F1}) where F1 = 
    switches.typeMass_jlM;



"""
	$(SIGNATURES)

College capacities. Set to an arbitrary large number for entry mechanisms where capacities do not matter.
"""
capacities(a :: AbstractEntryDecision{F1}) where F1 = capacities(a.switches);
capacities(e :: AbstractEntrySwitches{F1}) where F1 = fill(F1(1e8), n_colleges(e));
capacities(a :: EntrySequentialSwitches{F1}) where F1 = a.capacityV;
capacities(a :: EntrySequMultiLocSwitches{F1}) where F1 = a.capacity_clM;

limited_capacity(a :: AbstractEntryDecision{F1}) where F1 = 
    limited_capacity(a.switches);
limited_capacity(switches:: AbstractEntrySwitches{F1}) where F1 = false;
limited_capacity(switches :: EntrySequentialSwitches{F1}) where F1 = true;
limited_capacity(switches :: EntrySequMultiLocSwitches{F1}) where F1 = true;

capacity(e :: AbstractEntryDecision{F1}, iCollege :: Integer) where F1 = 
    capacity(e.switches, iCollege);
capacity(e :: AbstractEntrySwitches{F1}, iCollege :: Integer) where F1 = 
    F1(1e8);
capacity(switches :: EntrySequentialSwitches{F1}, iCollege :: Integer) where F1 = 
    switches.capacityV[iCollege];
capacity(a :: EntrySequMultiLocSwitches{F1}, iCollege :: Integer) where F1 = 
    a.capacity_clM[iCollege, :];

# --------------