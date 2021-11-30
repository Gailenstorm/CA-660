BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    YEAR = 3
    TYPE = 4
    COUNTY = 5
    UNIT = 6
    VALUE = 7
}
# Skip header
FNR == 1 {
    next
}
# Only interested in county data
$COUNTY ~ /West|Border|Southern|State|Midland|South-East|Mid-East|Rathdown| City|South / {
    next
}
$STATISTIC == "Units for which Permission Granted" {
#$STATISTIC == "Planning Permissions Granted" {
    year = $YEAR
    value = $VALUE
    type = $TYPE
    county = $COUNTY
    planning[year][county] += value
}
END {
    for (year in planning) {
        for (county in planning[year]) {
            planning_for_year_county = planning[year][county]
            rows[i++] = Q \
                  year \
                D county \
                D planning_for_year_county  \
            Q
        }
    }
    print Q \
          "Year" \
        D "County" \
        D "Planning Permission" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
