import pandas as pd

# Lire le fichier CSV
df = pd.read_csv('/home/adminuser/csvfile.csv')

# Imprimer le dataframe pour vérifier l'importation
print(df.head())
