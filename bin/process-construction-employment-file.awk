BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    MONTH = 3
    VALUE = 6
}
FNR == 1 {
    next
}
# We're not interested in construction_employment rates.
$STATISTIC == "Index of Employment (January 1975 to December 2008) in Building and Const" {
    year = substr($MONTH, 0, 4)
    month = int(substr($MONTH, 6))
    value = $VALUE
    construction_employment_sum_data[year] += value
    construction_employment_count_data[year]++
}
END {
    i = 0
    for (year in construction_employment_sum_data) {
        year_sum = construction_employment_sum_data[year]
        year_count = construction_employment_count_data[year]
        year_index = year_sum / year_count
        rows[i++] = Q \
            year \
            D year_index \
        Q
    }
    print Q \
        "Year" \
        D "Year Index" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
