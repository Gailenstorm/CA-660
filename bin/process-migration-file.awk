BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    YEAR = 3
    COUNTRY = 4
    SEX = 5
    ORIGIN_DESTINATION = 6
    UNIT = 7
    VALUE = 8
}
FNR == 1 {
    next
}
# We're only interested in county data.
$STATISTIC == "Estimated Migration (Persons in April)" \
&& $SEX == "Both sexes" \
&& $COUNTRY == "All countries" \
&& $ORIGIN_DESTINATION != "Net migration" \
{
    switch ($ORIGIN_DESTINATION) {
        case "Emigrants: All destinations":
            emigration[$YEAR] = $VALUE
            break
        case "Immigrants: All origins":
            immigration[$YEAR] = $VALUE
            break
    }
}
END {
    i = 0
    for (year in emigration) {
        emigrants = emigration[year]
        immigrants = immigration[year]
        rows[i++] = Q \
            year \
            D emigrants \
            D immigrants \
        Q
    }
    print Q \
        "Year" \
        D "Emigrants" \
        D "Immigrants" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
