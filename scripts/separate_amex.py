from datetime import datetime
import pandas

FILE_NAME = 'amex.csv'
# Read the CSV file
df = pandas.read_csv(FILE_NAME, header=None)
print(df.head())

# Reformat first column from %d $b $Y into date format %Y-%m-%d
df[0] = df[0].apply(lambda x: datetime.strptime(x, '%d %b %Y'))

# Separate the csv by month and year
for year in df[0].dt.year.unique():
    for month in df[0].dt.month.unique():
        # Create a new dataframe for each month and year
        month_df = df[(df[0].dt.year == year) & (df[0].dt.month == month)]
        # Save the dataframe to a new csv file
        month_df.to_csv(f'amex_{year}_{month}.csv', index=False, header=False)

