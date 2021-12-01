BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
}
FNR == 1 {
    next
}
# We're only interested in county data.
$6 !~ /(,| (City|Town)$|[0-9])/ &&
# We're only interested in specific bedroom categories.
$4 ~ /^(All bedrooms|Four plus bed|One bed|Three bed|Two bed)$/ {
    year = substr($3, 0, 4)
    switch ($4) {
        case "All bedrooms":
            bedrooms = "All"
            break
        case "One bed":
            bedrooms = 1
            break
        case "Two bed":
            bedrooms = 2
            break
        case "Three bed":
            bedrooms = 3
            break
        case "Four plus bed":
            bedrooms = "4+"
            break
        default:
            print "error"
            exit
    }
    switch ($5) {
        case "All property types":
            property_type = "All"
            break
        default:
            property_type = $5
    }
    county = $6
    value = $8
    rent_data[property_type][bedrooms][county][year] += value
    total_data[property_type][bedrooms][county][year] += 1
}
END {
    print Q \
          "County" \
        D "Type" \
        D "Bedrooms" \
        D "Year" \
        D "Rent" \
    Q
    i = 0
    BEDROOMS["All"]
    BEDROOMS[1]
    BEDROOMS[2]
    BEDROOMS[3]
    BEDROOMS["4+"]
    TYPES["All"]
    TYPES["Detached house"]
    TYPES["Semi detached house"]
    TYPES["Terrace house"]
    TYPES["Other flats"]
    TYPES["Apartment"]
    for (county in rent_data["All"]["All"]) {
        for (year in rent_data["All"]["All"][county]) {
            for (bedrooms in BEDROOMS) {
                for (property_type in TYPES) {
                    sum = rent_data[property_type][bedrooms][county][year]
                    total = total_data[property_type][bedrooms][county][year]
                    value = sum / total
                    rows[i++] = Q \
                          county \
                        D property_type \
                        D bedrooms \
                        D year \
                        \
                        D value \
                    Q
                }
            }
        }
    }
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
