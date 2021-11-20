#"Statistic","Year","County and Region","UNIT","VALUE"
#"Compensation of Employees (i.e. Wages and Salaries, Benefits in kind, Employers' social insurance contribution)","2000","State","Euro Million","42023"
#"Compensation of Employees (i.e. Wages and Salaries, Benefits in kind, Employers' social insurance contribution)","2000","Northern and Western","Euro Million","5749"
#                                            2                                                                       3           4                   5           6
BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    employee_income                         = "Compensation of Employees (i.e. Wages and Salaries, Benefits in kind, Employers' social insurance contribution)"
    taxes                                   = "Current Taxes on Income"
    disposable_income_per_household         = "Disposable Household Income"
    disposable_income_per_person            = "Disposable Income per Person"
    disposable_income_per_person_minus_rent = "Disposable Income per Person (excluding Rent)"
    self_employed_income                    = "Income of Self Employed"
    interest_and_dividends                  = "Net Interest and Dividends (payments by households of interest are deducted from interest received by households)"
    primary_income                          = "Primary Income"
    income_from_rent                        = "Rent of dwellings (including imputed rent of owner-occupied dwellings)"
    social_benefit                          = "Social Benefits and Other Current Transfers"
    total_income_per_household              = "Total Household Income"
    total_income_per_person                 = "Total Income per Person"
    statistic_i = 2
    year_i = 3
    county_i = 4
    value_i = 6
}
FNR == 1 {
    next
}
# We're only interested in county data.
$4 !~ /^(Midland|(Mid-)?(East|West)|Northern and Western|Eastern and Midland|South-(East|West)|Southern|Border|State)$/ &&
# We're not interested in indexes.
$2 !~ /^Index of / {
    statistic = $statistic_i
    year = $year_i
    county = $county_i
    value = $value_i
    income_data[statistic][county][year] = value
}
END {
    i = 0
    for (county in income_data[total_income_per_person]) {
        for (year in income_data[total_income_per_person][county]) {
            c_employee_income = income_data[employee_income][county][year]
            c_taxes = income_data[taxes][county][year]
            c_disposable_income_per_household = income_data[disposable_income_per_household][county][year]
            c_disposable_income_per_person = income_data[disposable_income_per_person][county][year]
            c_disposable_income_per_person_minus_rent = income_data[disposable_income_per_person_minus_rent][county][year]
            c_self_employed_income = income_data[self_employed_income][county][year]
            c_interest_and_dividends = income_data[interest_and_dividends][county][year]
            c_primary_income = income_data[primary_income][county][year]
            c_income_from_rent = income_data[income_from_rent][county][year]
            c_social_benefit = income_data[social_benefit][county][year]
            c_total_income_per_household = income_data[total_income_per_household][county][year]
            c_total_income_per_person = income_data[total_income_per_person][county][year]
            rows[i++] = Q \
                  county \
                D year \
                D c_employee_income \
                D c_taxes \
                D c_disposable_income_per_household \
                D c_disposable_income_per_person \
                D c_disposable_income_per_person_minus_rent \
                D c_self_employed_income \
                D c_interest_and_dividends \
                D c_primary_income \
                D c_income_from_rent \
                D c_social_benefit \
                D c_total_income_per_household \
                D c_total_income_per_person \
            Q
        }
    }
    print Q \
          "County" \
        D "Year" \
        D "Employee Income" \
        D "Taxes Paid" \
        D "Disposable Income per Household" \
        D "Disposable Income per Person" \
        D "Disposable Income per Person Minus Rent" \
        D "Self Employed Income" \
        D "Capital Gains" \
        D "Primary Income" \
        D "Income from Rent" \
        D "Social Benefits" \
        D "Total Income per Household" \
        D "Total Income per Person" \
    Q
    asort(rows)
    for (row in rows) {
        print rows[row]
    }
}
