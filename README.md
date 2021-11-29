# CA-660

## FYI

Monday: Hey Sorën, I'm going to redo the graphs today to optimise for the two column
spacing on the paper.

I'm not sure if the Households.csv file is usable.  The CSO site doesn't really provide explanation.  Is that % figure indicating
% of person's income spent on housing, or is it % of state spending, or something else?  Also, there's a lot of missing data.
E.g. I don't trust that 1% for 2015 onwards.

## Updates

I added a pre-processing step, just to get all the data into a format that we can easily compare.
- Raw data goes in the data/raw directory.
- Pre-processed data goes in the data/processed directory.
- The generation of data in the above directory can be carried out with the script ./bin/pre-process-raw-data.
- The above script uses some AWK to aggregate locations/eircodes into counties, etc.
- See the AWK scripts in the bin directory if you want a clear idea of what's going on.
- A better way to see what's going on is simply to compare the CSVs in the data/raw and data/processed directories.
- Our jupyter notebooks can now import from the data/processed directory instead of data/raw.

I added a file for income data.  This is useful for normalising.  It also has some rent data, which we could use.
