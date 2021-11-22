BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
}
FILENAME ~ /eircode/ {
    eircode_to_county[$2] = $3
    next
}
FNR != 1 {
    statistic = $2
    year = substr($3, 0, 4)
    month = int(substr($3, 6))
    eircode = gensub(":.*", "", 1, $5)
    stamp_duty_event = $6
    buyer_type = gensub("Household Buyer - ", "", 1, $7)
    switch (buyer_type) {
        case "All Buyer Types":
            buyer_type = "All"
            break
        case "First-Time Buyer Owner-Occupier":
            buyer_type = "First-Time Owner-Occupier"
            break
    }
    value = $9

    if (statistic == "Mean Sale Price") {
        mean_sale_price[eircode][stamp_duty_event][buyer_type][year][month] = value
    } else if (statistic == "Volume of Sales") {
        volume_of_sales[eircode][stamp_duty_event][buyer_type][year][month] = value
    }
}
END {
    for (eircode in mean_sale_price) {
        county = eircode_to_county[eircode]
        if (county) {
            all_buyer_filings
            first_time_owner_occupier_filings
            former_owner_occupier_filings
            non_occupier_filings
            stamp_duty_events["Filings"]
            stamp_duty_events["Executions"]
            buyer_types["All"]
            buyer_types["First-Time Owner-Occupier"]
            buyer_types["Former Owner-Occupier"]
            buyer_types["Non-Occupier"]
            for (stamp_duty_event in stamp_duty_events) {
                for (buyer_type in buyer_types) {
                    for (year in mean_sale_price[eircode][stamp_duty_event][buyer_type]) {
                        year_sum = 0
                        year_total = 0
                        for (month in mean_sale_price[eircode][stamp_duty_event][buyer_type][year]) {
                            mean = mean_sale_price[eircode][stamp_duty_event][buyer_type][year][month]
                            volume = volume_of_sales[eircode][stamp_duty_event][buyer_type][year][month]
                            year_sum += mean * volume
                            year_total += volume
                        }
                        if (stamp_duty_event == "Executions") {
                            county_execution_sums[county][buyer_type][year] += year_sum
                            county_execution_totals[county][buyer_type][year] += year_total
                        } else if (stamp_duty_event == "Filings") {
                            county_filing_sums[county][buyer_type][year] += year_sum
                            county_filing_totals[county][buyer_type][year] += year_total
                        }
                    }
                }
            }
        }
    }
    print \
        Q \
              "County" \
            D "Buyer Type" \
            D "Year" \
            D "Execution Volume" \
            D "Execution Mean Value" \
            D "Filing Volume" \
            D "Filing Mean Value" \
        Q
    i = 0
    for (county in county_execution_sums) {
        for (buyer_type in county_execution_sums[county]) {
            for (year in county_execution_sums[county][buyer_type]) {
                execution_volume = county_execution_totals[county][buyer_type][year]
                execution_mean = county_execution_sums[county][buyer_type][year] / execution_volume
                filing_volume = county_filing_totals[county][buyer_type][year]
                filing_mean = county_filing_sums[county][buyer_type][year] / filing_volume
                rows[i++] = Q \
                      county \
                    D buyer_type \
                    D year \
                    D execution_volume \
                    D execution_mean \
                    D filing_volume \
                    D filing_mean \
                Q
            }
        }
    }
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
