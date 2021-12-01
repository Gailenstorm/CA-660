# "Wicklow","1936","29868","28701"
#     2       3       4       5
BEGIN {
    FS = "\"(,\")*"
    C = ","
    Q = "\""
    D = Q C Q
    COUNTY = 2
    YEAR = 3
    FEMALE_POPULATION = 4
    MALE_POPULATION = 5
}
previous_county == $COUNTY && previous_year < $YEAR {
    year_diff = ($YEAR - previous_year)
    male_diff = ($MALE_POPULATION - previous_male) / year_diff
    female_diff = ($MALE_POPULATION - previous_male) / year_diff
    estimated_male = previous_male
    estimated_female = previous_female
    for (year = previous_year + 1; year < $YEAR; ++year) {
        estimated_male += male_diff
        estimated_female += female_diff
        print Q $COUNTY D year D int(estimated_female) D int(estimated_male) Q
    }
}
{print}
{
    previous_county = $COUNTY
    previous_year = $YEAR
    previous_female = $FEMALE_POPULATION
    previous_male = $MALE_POPULATION
}
