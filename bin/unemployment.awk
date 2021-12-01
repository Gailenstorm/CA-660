BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    MONTH = 3
    AGE_GROUP = 4
    SEX = 5
    UNIT = 6
    VALUE = 7
}
FNR == 1 {
    next
}
# We're not interested in unemployment rates.
$STATISTIC == "Seasonally Adjusted Monthly Unemployment Rate" {
    switch ($SEX) {
        case "Both sexes":
            sex = "All"
            break
        default:
            sex = $SEX
    }
    age_group = gensub(" years", "", 1, $AGE_GROUP)
    year = substr($MONTH, 0, 4)
    month = int(substr($MONTH, 6))
    value = $VALUE
    unemployment_sum_data[year][sex][age_group] += value
    unemployment_count_data[year][sex][age_group]++;
}
END {
    i = 0
    for (year in unemployment_sum_data) {
        for (sex in unemployment_sum_data[year]) {
            for (age_group in unemployment_sum_data[year][sex]) {
                year_sum = unemployment_sum_data[year][sex][age_group]
                year_count = unemployment_count_data[year][sex][age_group]
                year_rate = year_sum / year_count
                rows[i++] = Q \
                    year \
                    D sex \
                    D age_group \
                    D year_rate \
                Q
            }
        }
    }
    print Q \
        "Year" \
        D "Sex" \
        D "Age Group" \
        D "Year Rate" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
