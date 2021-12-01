BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    YEAR = 3
    AGE_GROUP = 4
    SEX = 5
    REGION = 6
    METHOD = 7
    UNIT = 8
    VALUE = 9
}
FNR == 1 {
    next
}
# We're only interested in county data.
$STATISTIC == "Projected Population" \
&& $SEX != "Both sexes" \
&& $AGE_GROUP == "All ages" \
&& $REGION != "State" \
{
    if ($REGION == "Midland") {
        region = "Midlands"
    } else {
        region = $REGION
    }
    data[$YEAR][region][$METHOD][$SEX] = $VALUE
}
END {
    i = 0
    for (year in data) {
        for (region in data[year]) {
            for (method in data[year][region]) {
                male_population = data[year][region][method]["Male"]
                female_population = data[year][region][method]["Female"]
                rows[i++] = Q \
                    year \
                    D region \
                    D method \
                    D male_population \
                    D female_population \
                Q
            }
        }
    }
    print Q \
        "Year" \
        D "Region" \
        D "Method" \
        D "Male Population" \
        D "Female Population" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
