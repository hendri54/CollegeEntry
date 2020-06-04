function test_value_cl(nc, nl)
    if nl == 1
        return CollegeEntry.matrix_from_vector(range(1.2, 1.5, length = nc));
    else
        return range(1.2, 2.5, length = nc) * range(1.0, 0.8, length = nl)';
    end
end

# Low capacity sequential ensures that there are full colleges
function test_entry_switches(J, nc)
    return [
    # CollegeEntry.make_test_entry_one_step(J, nc), 
    # CollegeEntry.make_test_entry_two_step(J, nc),
    # CollegeEntry.make_test_entry_sequential(J, nc, 3.0),
    # CollegeEntry.make_test_entry_sequential(J, nc, 0.2),
    CollegeEntry.make_test_entry_sequ_multiloc(J, nc, nc + 1, 0.3 * J * nc),
    CollegeEntry.make_test_entry_sequ_multiloc(J, nc, 1, 0.3 * J)
    ];
end

# ---------------------