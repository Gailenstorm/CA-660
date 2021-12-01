import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
from scipy.stats import spearmanr
from ggplot import *

TABLE_DIR = "data/processed"

#plt.rcParams["figure.figsize"] = (18, 20)

def filter_by_county(data, county, negate=False):
    return data.loc[(data["County"] == county) != negate]

def add_legend(data, groupby, sortby):
    current_handles, current_labels = plt.gca().get_legend_handles_labels()
    handles = dict(list(zip(current_labels, current_handles)))
    data = data.loc[data["Year"] == max(data["Year"])]
    labels = list(reversed(data.sort_values(by=sortby)[groupby].tolist()))
    plt.legend([handles[str(l)] for l in labels], labels)

def save(plot, name):
    path = f"media/{name}.svg"
    print(path)
    if type(plot) == ggplot:
        plot.save(path)
        plt.clf()
    else:
        try:
            plot.savefig(path)
            plot.clf()
        except:
            plot.figure.savefig(path)
            plot.figure.clf()

def crop_by_year(*data_sources):
    min_year = max(data.Year.min() for data in data_sources)
    max_year = min(data.Year.max() for data in data_sources)
    return [
        data.copy().loc[(data.Year >= min_year) & (data.Year <= max_year)]
        for data in data_sources
    ]

def load(name, fallback=None):
    path = os.path.join(TABLE_DIR, f"{name}.csv")
    if os.path.exists(path):
        data = pd.read_csv(path)
    else:
        data = fallback()
        data.to_csv(path, index=False)
    return data

# https://www.cso.ie/en/releasesandpublications/ep/p-rpp/regionalpopulationprojections2017-2036/appendix2conceptsanddefinitions/
region_data = load("region")

# E2004, C0103, B0102
population_data = load("interpolated_population")
population_data["Total Population"] = (
    population_data["Male Population"]
    + population_data["Female Population"]
)
population_data = population_data.sort_values("Year")
population_data = pd.merge(
    population_data,
    region_data,
    how='left',
    left_on=['County'],
    right_on = ['County'],
)
aggregate_population_data = population_data.groupby(["Year", "Region"]).agg(
    regional_total=("Total Population", "sum"),
    regional_female=("Female Population", "sum"),
    regional_male=("Male Population", "sum"),
).reset_index()
# PEC08
population_projection_data = load("population_projection")
population_projection_data = (
    population_projection_data
    .groupby(["Year", "Region"])
    .agg(
        m=("Male Population", "mean"),
        f=("Female Population", "mean"),
    )
    .reset_index()
)
population_projection_data.rename(
    columns={'m':'Male Population', 'f':'Female Population'},
    inplace=True
)
population_projection_data["Total Population"] = (
    population_projection_data["Male Population"]
    + population_projection_data["Female Population"]
)

"""
g = ggplot(population_projection_data, aes(
    x="Year",
    y="Total Population",
    colour="Region",
)) + geom_line() + theme_bw()
save(g, "population_projection")
"""

def create_county_clusters(data, agg):
    data = data.copy()
    data = pd.merge(
        data,
        population_data,
        how='left',
        left_on=['County', 'Year'],
        right_on = ['County', 'Year'],
    )
    data["Agg by Population"] = data[agg] * data["Total Population"]
    while True:
        min_difference = 999999999999999
        counties = sorted(data["County"].unique())
        if len(counties) <= 5: break
        for i in range(len(counties)):
            for j in range(i + 1, len(counties)):
                county_a = counties[i]
                county_b = counties[j]
                county_data_a = (
                    data.loc[data["County"] == county_a]
                    .sort_values(by="Year")[agg].to_numpy()
                )
                county_data_b = (
                    data.loc[data["County"] == county_b]
                    .sort_values(by="Year")[agg].to_numpy()
                )
                difference = sum(abs(county_data_a - county_data_b))
                if difference < min_difference:
                    min_difference = difference
                    min_county_a = county_a
                    min_county_b = county_b
        cluster = (
            data.loc[
                (data["County"] == min_county_a)
                | (data["County"] == min_county_b)
            ]
            .groupby("Year")
            .aggregate("mean")
            .reset_index()
        )
        cluster["County"] = f"{min_county_a},{min_county_b}"
        data = data.loc[
            (data["County"] != min_county_a) & (data["County"] != min_county_b)
        ]
        data = data.append(cluster).reset_index()
        data.pop("index")
    data = (
        data
        .groupby("County")
        .aggregate("mean")
        .sort_values(by="Rent")
        .reset_index()
    )
    groups = []
    counties = []
    for idx, row in data.iterrows():
        group = idx + 1
        for county in row["County"].split(","):
            groups.append(group)
            counties.append(county)

    return pd.DataFrame.from_dict({
        "Group": groups,
        "County": counties,
    })

# RIH02
rent_data = load("rent")

def create_county_clusters_from_rent_data():
    agg_rent_data = rent_data.copy()
    agg_rent_data = agg_rent_data.loc[
        (rent_data["Type"] == "All")
        & (rent_data["Bedrooms"] == "All")
    ]
    agg_rent_data.pop("Type")
    agg_rent_data.pop("Bedrooms")

    return create_county_clusters(
        agg_rent_data, "Rent"
    )

county_group_data = load(
    "county_group",
    create_county_clusters_from_rent_data
)

def group_by_county_group(data, agg):
    total_populations_by_group = {}
    merged_data = pd.merge(
        data,
        county_group_data,
        how='left', left_on=['County'],
        right_on = ['County']
    )
    """
    merged_data = pd.merge(
        merged_data,
        population_data,
        how='left',
        left_on=['County', 'Year'],
        right_on = ['County', 'Year'],
    )
    exit(0)
    """
    if agg == "sum":
        grouped_data = (
            merged_data
            .groupby(["Year", "Group"])
            .aggregate("sum")
            .reset_index()
        )
    elif agg == "mean":
        grouped_data = (
            merged_data
            .groupby(["Year", "Group"])
            .aggregate("mean")
            .reset_index()
        )
    grouped_data["Group"] = grouped_data["Group"].apply(str)
    return grouped_data

proportional_population_data = pd.merge(
    population_data,
    aggregate_population_data,
    how='left',
    left_on=['Year', 'Region'],
    right_on=['Year', 'Region'],
)
proportional_population_data["Regional Proportion Female"] = (
    proportional_population_data["Female Population"]
    / proportional_population_data.regional_female
)
proportional_population_data["Regional Proportion Male"] = (
    proportional_population_data["Male Population"]
    / proportional_population_data.regional_male
)
proportional_population_data["Regional Proportion"] = (
    proportional_population_data["Total Population"]
    / proportional_population_data.regional_total
)
proportional_population_data.pop("regional_total")
proportional_population_data.pop("regional_female")
proportional_population_data.pop("regional_male")
proportional_population_data.pop("Male Population")
proportional_population_data.pop("Female Population")
proportional_population_data.pop("Total Population")
proportional_population_by_group_data = group_by_county_group(
    proportional_population_data, 'sum'
)

# HPM04
property_data = load("property")
# CIA02
income_data = load("income")
income_data_by_group = group_by_county_group(income_data, 'mean')
# BHA12
planning_data = load("planning")
planning_data = planning_data.loc[planning_data["Year"] >= 2016]
planning_data_by_group = group_by_county_group(planning_data, "sum")
# HSA09
construction_cost_data = load("construction_cost")
# BBM02
construction_employment_data = (
    load("construction_employment")
)
# PEA18
migration_data = load("migration")

save(
    construction_cost_data.plot.line(
        x="Year", y="Cost",
    ),
    "construction_cost",
)
save(
    construction_employment_data.plot.line(
        x="Year", y="Index",
    ),
    "construction_employment",
)
plt.plot(migration_data['Year'], migration_data['Immigrants'], label="Immigrants")
plt.plot(migration_data['Year'], migration_data['Emigrants'], label="Emigrants")
plt.legend()
save(plt, "migration")

for g, df in income_data_by_group.groupby('Group'):
    plt.plot(df['Year'], df['Disposable Income per Person'], label=g)
add_legend(
    income_data_by_group, "Group", 'Disposable Income per Person'
)
save(plt, "income")

for g, df in income_data_by_group.groupby('Group'):
    plt.plot(df['Year'], df['Capital Gains'], label=g)
add_legend(
    income_data_by_group, "Group", 'Capital Gains'
)
save(plt, "capital_gains")

for g, df in planning_data_by_group.groupby('Group'):
    plt.plot(df['Year'], df['Planning Permission'], label=g)
add_legend(planning_data_by_group, "Group", "Planning Permission")
save(plt, "planning")

years = np.linspace(
    min(proportional_population_data.Year),
    max(population_projection_data["Year"]),
    (
        max(population_projection_data["Year"])
        - min(proportional_population_data.Year)
        + 1
    )
)
min_projection_year = min(population_projection_data["Year"])
for g, df in proportional_population_data.groupby('County'):
    region = df["Region"].iloc[0]
    data = pd.DataFrame.from_dict({
        "Year": years,
        "Regional Proportion": np.poly1d(
            np.polyfit(df.Year, df["Regional Proportion"], 1)
        )(years),
        "Regional Proportion Male": np.poly1d(
            np.polyfit(df.Year, df["Regional Proportion Male"], 1)
        )(years),
        "Regional Proportion Female": np.poly1d(
            np.polyfit(df.Year, df["Regional Proportion Female"], 1)
        )(years),
        "Region": [region] * len(years),
        "County": [g] * len(years),
    })
    data = pd.merge(
        data,
        population_projection_data,
        left_on=['Region', 'Year'],
        right_on = ['Region', 'Year'],
    )
    data["Total Population"] = (
        data["Total Population"] * data["Regional Proportion"]
    )
    data["Male Population"] = (
        data["Male Population"] * data["Regional Proportion Male"]
    )
    data["Female Population"] = (
        data["Female Population"] * data["Regional Proportion Female"]
    )
    data.pop("Regional Proportion")
    data.pop("Regional Proportion Male")
    data.pop("Regional Proportion Female")
    population_data = population_data.append(data)
    #plt.plot(data["Year"], data["Total Population"], label=g)
#save(plt, "proportional_population_by_county")
fpopulation_data = population_data.loc[
    population_data.County.isin(["Carlow", "Kilkenny", "Clare", "Kerry", "Offaly", "Waterford", "Wexford", "Laois", "Westmeath", "Sligo"])
].copy()
g = ggplot(fpopulation_data, aes(
    x="Year",
    y="Total Population",
    colour="County",
    group="County",
)) + geom_line() + theme_bw()
#g.show()
save(g, "population_by_county")


polyline = np.linspace(
    min(proportional_population_by_group_data.Year),
    max(proportional_population_by_group_data.Year) + 100,
)
for g, df in proportional_population_by_group_data.groupby('Group'):
    model = np.poly1d(
        np.polyfit(
            df.Year, df["Regional Proportion"], 1
        )
    )
    plt.plot(polyline, model(polyline), label=g)
add_legend(
    proportional_population_by_group_data, "Group", 'Regional Proportion'
)
save(plt, "proportional_population_by_group")

county_group_population = group_by_county_group(population_data, "sum")
g = ggplot(county_group_population, aes(
    x="Year",
    y="Total Population",
    group="Group",
    colour="Group",
)) + geom_line()
save(g, "population_by_group")
    
property_data = property_data.loc[property_data["Buyer Type"] == "All"].copy()
execution_volume = property_data["Execution Volume"]
filing_volume = property_data["Filing Volume"]
volume = execution_volume + filing_volume
property_data["Volume"] = volume
property_data["Mean Value"] = (
    execution_volume * property_data["Execution Mean Value"]
    + filing_volume * property_data["Filing Mean Value"]
) / volume

print(property_data)
g = ggplot(property_data, aes(
    x="Year",
    y="Mean Value",
    colour="County",
)) + geom_line()
save(g, "property_value_by_county")

g = ggplot(group_by_county_group(property_data, "mean"), aes(
    x="Year",
    y="Mean Value",
    colour="Group",
)) + geom_line()
save(g, "property_value_by_group")

rent_data = rent_data.loc[(rent_data["Type"] == "All") & (rent_data["Bedrooms"] == "All")]

for county, df in rent_data.groupby('County'):
    plt.plot(df['Year'], df['Rent'], label=county)
save(plt, "rent_by_county")

county_group_rent = group_by_county_group(rent_data, "mean")
for group, df in county_group_rent.groupby('Group'):
    plt.plot(df['Year'], df['Rent'], label=group)
add_legend(county_group_rent, 'Group', 'Rent')
save(plt, 'rent_by_group')

X = 'Mean Value'
Y = 'Rent'
(
    cropped_property_data,
    cropped_rent_data,
    cropped_income_data,
    cropped_population_data,
) = (
    crop_by_year(property_data, rent_data, income_data, population_data)
)
rent_property_income_population = pd.merge(
    cropped_rent_data,
    cropped_property_data,
    how='left',
    left_on=['County', 'Year'],
    right_on = ['County','Year'],
)
rent_property_income_population = pd.merge(
    rent_property_income_population,
    cropped_income_data,
    how='left',
    left_on=['County', 'Year'],
    right_on = ['County','Year'],
)
rent_property_income_population = pd.merge(
    rent_property_income_population,
    cropped_population_data,
    how='left',
    left_on=['County', 'Year'],
    right_on = ['County','Year'],
)
rent_property_income_population = rent_property_income_population.sort_values(by=X)

#rent_and_property = filter_by_county(rent_and_property, "Dublin")

for county, df in rent_property_income_population.groupby('County'):
    plt.scatter(df[X], df[Y], label=county)
plt.xlabel("Mean property sale price")
plt.ylabel(Y)
save(plt, "rent_by_property_price")

rent_property_income_population_by_group = (
    group_by_county_group(rent_property_income_population, "mean")
)
for group, df in rent_property_income_population_by_group.groupby('Group'):
    plt.scatter(df[X], df[Y], label=group)
plt.xlabel("Mean property sale price")
plt.ylabel(Y)
add_legend(rent_property_income_population_by_group, "Group", "Rent")
save(plt, "rent_by_property_price_for_group")

variables = [
    "Mean Value",
    "Rent",
    "Disposable Income per Household",
    "Disposable Income per Person",
    "Disposable Income per Person Minus Rent",
    "Self Employed Income",
    "Capital Gains",
    "Primary Income",
    "Income from Rent",
    "Social Benefits",
    "Total Income per Household",
    "Total Income per Person",
    "Male Population",
    "Female Population",
    "Total Population",
]
input_columns = np.array([rent_property_income_population[variable].to_numpy() for variable in variables])
correlation_matrix = np.corrcoef(input_columns)
h, w = correlation_matrix.shape
plt.imshow(correlation_matrix, cmap='coolwarm', interpolation='nearest')
plt.title("Correlation")
plt.xticks(np.arange(w), variables, rotation=90)
plt.yticks(np.arange(h), variables)
save(plt, "variable_correlation")

X = "Year"
Y = "Capital Gains"
Y = "Taxes Paid"
Y = "Disposable Income per Person Minus Rent"
Y = "Total Income per Person"
for county, df in income_data.groupby('County'):
    plt.plot(
        df[X],
        df[Y],
        label=county,
    )
plt.xlabel(X)
plt.ylabel(Y)
add_legend(income_data, "County", Y)
plt

population_rent_correlation = {}
for county in population_data["County"].unique():
    population_rent_correlation[county] = rent_property_income_population.loc[rent_property_income_population["County"] == county].sort_values(by="Year")["Total Population"].corr(rent_property_income_population.loc[rent_property_income_population["County"] == county].sort_values(by="Year")["Rent"], method="spearman")

save(pd.DataFrame(population_rent_correlation, index=[0]).plot.bar(), "population_rent_correlation")

save(pd.Series(list(population_rent_correlation.values())).plot.kde(), "population_rent_correlation_kde")