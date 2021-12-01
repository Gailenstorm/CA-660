#"Statistic","Month","Type of Residential Property","UNIT","VALUE"
#"Residential Property Price Index","2005M01","National - all residential properties","Base 2015=100","124.9"
#"Residential Property Price Index","2005M01","National - houses","Base 2015=100","120.7"
#           2                           3               4               5            6
BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    STATISTIC = 2
    MONTH = 3
    REGION_AND_TYPE = 4
    UNIT = 5
    VALUE = 6
}
FNR == 1 {
    next
}
$STATISTIC == "Residential Property Price Index" \
&& $REGION_AND_TYPE ~ /Dublin - all residential properties$/ \
{
    switch ($REGION_AND_TYPE) {
        case "Dublin - all residential properties":
            region = "Dublin"
            break
        case "National excluding Dublin - all residential properties":
            region = "not Dublin"
            break
        default:
            next
    }
    year = substr($3, 0, 4)
    sum_data[region][year] += $VALUE
    total_data[region][year] += 1
}
END {
    print Q \
        "Dublin" \
        D "Year" \
        D "Index" \
    Q
    i = 0
    for (region in sum_data) {
        for (year in sum_data[region]) {
            sum = sum_data[region][year]
            total = total_data[region][year]
            value = sum / total
            rows[i++] = Q \
                region \
                D year \
                D value \
            Q
        }
    }
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
