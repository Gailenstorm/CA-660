BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    YEAR = 3
    VALUE = 6
}
FNR == 1 {
    next
}
# We're not interested in construction_employment rates.
$STATISTIC == "House Construction Cost Index" {
    year = $YEAR
    value = $VALUE
    construction_cost[year] += value
}
END {
    i = 0
    for (year in construction_cost) {
        cost = construction_cost[year]
        rows[i++] = Q \
            year \
            D cost \
        Q
    }
    print Q \
        "Year" \
        D "Cost" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
