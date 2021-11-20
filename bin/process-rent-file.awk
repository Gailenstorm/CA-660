# "Statistic","HalfYear","Number of Bedrooms","Property Type","Location","UNIT","VALUE"
# "RTB Average Monthly Rent Report","2008H1","All bedrooms","All property types","Carlow","Euro","759.62"
#        2                           3           4               5                   6       7       8
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
    half = int(substr($3, 6))
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
    rent_data[property_type][bedrooms][county][year][half] = value
}
END {
    print Q \
          "County" \
        D "Type" \
        D "Bedrooms" \
        D "Year" \
        D "Year Half" \
        \
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
            for (half in rent_data["All"]["All"][county][year]) {
                for (bedrooms in BEDROOMS) {
                    for (property_type in TYPES) {
                        value = rent_data[property_type][bedrooms][county][year][half]
                        rows[i++] = Q \
                              county \
                            D property_type \
                            D bedrooms \
                            D year \
                            D half \
                            \
                            D value \
                        Q
                    }
                }
            }
        }
    }
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
