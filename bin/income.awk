BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    EMPLOYEE_INCOME                         = "Compensation of Employees (i.e. Wages and Salaries, Benefits in kind, Employers' social insurance contribution)"
    TAXES                                   = "Current Taxes on Income"
    DISPOSABLE_INCOME_PER_HOUSEHOLD         = "Disposable Household Income"
    DISPOSABLE_INCOME_PER_PERSON            = "Disposable Income per Person"
    DISPOSABLE_INCOME_PER_PERSON_MINUS_RENT = "Disposable Income per Person (excluding Rent)"
    SELF_EMPLOYED_INCOME                    = "Income of Self Employed"
    INTEREST_AND_DIVIDENDS                  = "Net Interest and Dividends (payments by households of interest are deducted from interest received by households)"
    PRIMARY_INCOME                          = "Primary Income"
    INCOME_FROM_RENT                        = "Rent of dwellings (including imputed rent of owner-occupied dwellings)"
    SOCIAL_BENEFIT                          = "Social Benefits and Other Current Transfers"
    TOTAL_INCOME_PER_HOUSEHOLD              = "Total Household Income"
    TOTAL_INCOME_PER_PERSON                 = "Total Income per Person"
    STATISTIC = 2
    YEAR = 3
    COUNTY = 4
    VALUE = 6
}
FNR == 1 {
    next
}
# We're only interested in county data.
$4 !~ /^(Midland|(Mid-)?(East|West)|Northern and Western|Eastern and Midland|South-(East|West)|Southern|Border|State)$/ &&
# We're not interested in indexes.
$2 !~ /^Index of / {
    statistic = $STATISTIC
    year = $YEAR
    county = $COUNTY
    value = $VALUE
    income_data[statistic][county][year] = value
}
END {
    i = 0
    for (county in income_data[TOTAL_INCOME_PER_PERSON]) {
        for (year in income_data[TOTAL_INCOME_PER_PERSON][county]) {
            employee_income = income_data[EMPLOYEE_INCOME][county][year]
            taxes = income_data[TAXES][county][year]
            disposable_income_per_household = income_data[DISPOSABLE_INCOME_PER_HOUSEHOLD][county][year]
            disposable_income_per_person = income_data[DISPOSABLE_INCOME_PER_PERSON][county][year]
            disposable_income_per_person_minus_rent = income_data[DISPOSABLE_INCOME_PER_PERSON_MINUS_RENT][county][year]
            self_employed_income = income_data[SELF_EMPLOYED_INCOME][county][year]
            interest_and_dividends = income_data[INTEREST_AND_DIVIDENDS][county][year]
            primary_income = income_data[PRIMARY_INCOME][county][year]
            income_from_rent = income_data[INCOME_FROM_RENT][county][year]
            social_benefit = income_data[SOCIAL_BENEFIT][county][year]
            total_income_per_household = income_data[TOTAL_INCOME_PER_HOUSEHOLD][county][year]
            total_income_per_person = income_data[TOTAL_INCOME_PER_PERSON][county][year]
            rows[i++] = Q \
                  county \
                D year \
                D employee_income \
                D taxes \
                D disposable_income_per_household \
                D disposable_income_per_person \
                D disposable_income_per_person_minus_rent \
                D self_employed_income \
                D interest_and_dividends \
                D primary_income \
                D income_from_rent \
                D social_benefit \
                D total_income_per_household \
                D total_income_per_person \
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
