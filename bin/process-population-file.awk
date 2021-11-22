BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    YEAR = 3
    SEX = 4
}
FNR == 1 {
    next
}
# We only want county data.
FILENAME ~ /historical/ && /Connacht|Leinster|Ulster|State|Munster/ {
    next
}
FILENAME ~ /historical/ {
    COUNTY = 5
    VALUE = 7
    county = gensub("^(North|South) ", "", 1, $COUNTY)
    historical_data[county][$YEAR][$SEX] += $VALUE
    next
}
# We only want county data.
$6 ~ /South Dublin|Rathdown|Fingal|Ulster|Leinster|Munster|Connacht| City$/ {
    next
}
$6 ~ /(Limerick|Waterford|Galway|Cork) County$/ && FILENAME ~ /2006/ {
    # The 2006 population file counts Cork, Limerick, Waterford and Galway twice;
    # e.g. firstly as 'Cork', then secondly as 'Cork County'.
    # Exclude the latter from the aggregate counts.
    next
}
$2 == "Population" && NR != 1 {
    rurality = $5
    county = gensub(" (City and )?County$", "", 1, $6)
    county = gensub("^(North|South) ", "", 1, county)
    population = $8
    population_data[county][$YEAR][$SEX][rurality] += population
}
END {
    i = 0
    for (year in population_data["Cork"]) {
        non_dublin_total_women_in_rural = 0
        non_dublin_total_men_in_rural = 0
        non_dublin_total_women_in_town = 0
        non_dublin_total_men_in_town = 0
        dublin_present = 0
        for (county in population_data) {
            if (county == "Dublin") {
                dublin_present = year in population_data[county]
            }
            total_women_in_rural = population_data[county][year]["Female"]["Aggregate Rural Area"]
            total_men_in_rural = population_data[county][year]["Male"]["Aggregate Rural Area"]

            total_women_in_town = population_data[county][year]["Female"]["Aggregate Town Area"]
            total_men_in_town = population_data[county][year]["Male"]["Aggregate Town Area"]

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
                        D (total_women_in_rural + total_women_in_town) \
                        D (total_men_in_rural + total_men_in_town) \
                    Q
                }
            }
        }
        if (!dublin_present) {
            # Dublin county population data was missing, but we can derive it.
            dublin_total_women_in_rural = state_total_women_in_rural - non_dublin_total_women_in_rural
            dublin_total_men_in_rural = state_total_men_in_rural - non_dublin_total_men_in_rural
            dublin_total_women_in_town = state_total_women_in_town - non_dublin_total_women_in_town
            dublin_total_men_in_town = state_total_men_in_town - non_dublin_total_men_in_town
            rows[i++] = Q \
                "Dublin" \
                D year \
                D (dublin_total_women_in_rural + dublin_total_women_in_town) \
                D (dublin_total_men_in_rural + dublin_total_men_in_town) \
            Q
        }
    }
    for (county in historical_data) {
        for (year in historical_data[county]) {
            male_pop = historical_data[county][year]["Male"]
            female_pop = historical_data[county][year]["Female"]
            both_pop = historical_data[county][year]["Both sexes"]
            if (male_pop + female_pop != both_pop) {
                print "assumption broken"
                exit 1
            }
            rows[i++] = Q \
                  county \
                D year \
                D male_pop \
                D female_pop \
            Q
        }
    }
    asort(rows)
    print Q \
        "County" \
        D "Year" \
        D "Female Population" \
        D "Male Population" \
    Q
    for (row in rows) {
        print rows[row]
    }
}
