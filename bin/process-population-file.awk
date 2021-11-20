BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
}
# We only want county data.
/South Dublin|Rathdown|Fingal/ {
    next
}
$2 == "Population" && NR != 1 {
    year = $3
    sex = $4
    rurality = $5
    county = gensub(" (City and )?County$", "", 1, $6)
    population = $8
    data[county][year][sex][rurality] = population
}
END {
    i = 0
    for (year in data["Cork"]) {
        non_dublin_total_women_in_rural = 0
        non_dublin_total_men_in_rural = 0
        non_dublin_total_women_in_town = 0
        non_dublin_total_men_in_town = 0
        for (county in data) {
            total_women_in_rural = county_data = data[county][year]["Female"]["Aggregate Rural Area"]
            total_men_in_rural = county_data = data[county][year]["Male"]["Aggregate Rural Area"]

            total_women_in_town = county_data = data[county][year]["Female"]["Aggregate Town Area"]
            total_men_in_town = county_data = data[county][year]["Male"]["Aggregate Town Area"]

            # We only want full county population data, not city population data.
            if (total_women_in_rural || total_men_in_rural) {
                if (county == "State") {
                    state_total_women_in_rural = total_women_in_rural
                    state_total_men_in_rural = total_men_in_rural
                    state_total_women_in_town = total_women_in_town
                    state_total_men_in_town = total_men_in_town
                } else {
                    non_dublin_total_women_in_rural += total_women_in_rural
                    non_dublin_total_men_in_rural += total_men_in_rural
                    non_dublin_total_women_in_town += total_women_in_town
                    non_dublin_total_men_in_town += total_men_in_town
                    rows[i++] = Q \
                        county \
                        D year \
                        D total_women_in_rural \
                        D total_men_in_rural \
                        D total_women_in_town \
                        D total_men_in_town \
                    Q
                }
            }
        }
        # Dublin county population data was missing, but we can derive it.
        dublin_total_women_in_rural = state_total_women_in_rural - non_dublin_total_women_in_rural
        dublin_total_men_in_rural = state_total_men_in_rural - non_dublin_total_men_in_rural
        dublin_total_women_in_town = state_total_women_in_town - non_dublin_total_women_in_town
        dublin_total_men_in_town = state_total_men_in_town - non_dublin_total_men_in_town
        rows[i++] = Q \
            "Dublin" \
            D year \
            D dublin_total_women_in_rural \
            D dublin_total_men_in_rural \
            D dublin_total_women_in_town \
            D dublin_total_men_in_town \
        Q
    }
    asort(rows)
    print Q \
        "County" \
        D "Year" \
        D "Rural Women" \
        D "Rural Men" \
        D "Town Women" \
        D "Town Men" \
    Q
    for (row in rows) {
        print rows[row]
    }
}
