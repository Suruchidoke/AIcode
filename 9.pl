# ---------------------------------------------------------
# 🌦️ EXP-9: Bayesian Belief Network on Weather Data (VS Code Version)
# ---------------------------------------------------------
# Required packages:
# pip install pandas networkx matplotlib pybbn
import os
import urllib.request
import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt
from pybbn.graph.dag import Bbn
from pybbn.graph.edge import Edge, EdgeType
from pybbn.graph.node import BbnNode
from pybbn.graph.variable import Variable
from pybbn.graph.jointree import EvidenceBuilder
from pybbn.pptc.inferencecontroller import InferenceController
# ---------------------------------------------------------
# 1️⃣  DOWNLOAD DATASET IF MISSING
# ---------------------------------------------------------
csv_name = "weatherAUS.csv"
url = "https://rattle.togaware.com/weatherAUS.csv"
if not os.path.exists(csv_name):
    print("🌦️ Downloading dataset...")
    try:
        urllib.request.urlretrieve(url, csv_name)
        print("✅ Dataset downloaded successfully!")
    except Exception as e:
        print(f"❌ Failed to download dataset: {e}")
        exit()
else:
    print("✅ Dataset already exists.")
# ---------------------------------------------------------
# 2️⃣  LOAD & PREPARE DATA
# ---------------------------------------------------------
df = pd.read_csv(csv_name, encoding='utf-8')
print("\n📋 Columns in dataset:")
print(df.columns.tolist())
# Try to automatically detect the correct 'RainTomorrow' column
target_col = None
for col in df.columns:
    if 'rain' in col.lower() and 'tomorrow' in col.lower():
        target_col = col
        break
if target_col is None:
    raise KeyError("❌ Could not find the 'RainTomorrow' column in the dataset. "
                   "Check the column list printed above.")
# Drop rows where the target variable is missing
df = df[pd.isnull(df[target_col]) == False]
# Fill missing numeric values with mean
df = df.fillna(df.mean(numeric_only=True))
# Create categorical bands for the features
df['WindGustSpeedCat'] = df['WindGustSpeed'].apply(
    lambda x: '0.<=40' if x <= 40 else '1.40-50' if 40 < x <= 50 else '2.>50'
)
df['Humidity9amCat'] = df['Humidity9am'].apply(
    lambda x: '1.>60' if x > 60 else '0.<=60'
)
df['Humidity3pmCat'] = df['Humidity3pm'].apply(
    lambda x: '1.>60' if x > 60 else '0.<=60'
)
print(f"\n✅ Using target column: {target_col}")
print(df[['Humidity9amCat', 'Humidity3pmCat', 'WindGustSpeedCat', target_col]].head())
# ---------------------------------------------------------
# 3️⃣  HELPER FUNCTION TO COMPUTE PROBABILITIES
# ---------------------------------------------------------
def probs(data, child, parent1=None, parent2=None):
    """Compute conditional probability distributions for Bayesian nodes."""
    if parent1 is None:
        prob = (
            pd.crosstab(data[child], 'Empty', normalize='columns')
            .sort_index()
            .to_numpy()
            .reshape(-1)
            .tolist()
        )
    elif parent1 is not None:
        if parent2 is None:
            prob = (
                pd.crosstab(data[parent1], data[child], normalize='index')
                .sort_index()
                .to_numpy()
                .reshape(-1)
                .tolist()
            )
        else:
            prob = (
                pd.crosstab([data[parent1], data[parent2]], data[child], normalize='index')
                .sort_index()
                .to_numpy()
                .reshape(-1)
                .tolist()
            )
    else:
        raise ValueError("Error in probability frequency calculation")
    return prob
# ---------------------------------------------------------
# 4️⃣  CREATE BBN NODES
# ---------------------------------------------------------
H9am = BbnNode(Variable(0, 'H9am', ['<=60', '>60']),
               probs(df, child='Humidity9amCat'))
H3pm = BbnNode(Variable(1, 'H3pm', ['<=60', '>60']),
               probs(df, child='Humidity3pmCat', parent1='Humidity9amCat'))
W = BbnNode(Variable(2, 'W', ['<=40', '40-50', '>50']),
            probs(df, child='WindGustSpeedCat'))
RT = BbnNode(Variable(3, 'RT', ['No', 'Yes']),
             probs(df, child=target_col, parent1='Humidity3pmCat', parent2='WindGustSpeedCat'))
# ---------------------------------------------------------
# 5️⃣  CREATE NETWORK STRUCTURE
# ---------------------------------------------------------
bbn = (
    Bbn()
    .add_node(H9am)
    .add_node(H3pm)
    .add_node(W)
    .add_node(RT)
    .add_edge(Edge(H9am, H3pm, EdgeType.DIRECTED))
    .add_edge(Edge(H3pm, RT, EdgeType.DIRECTED))
    .add_edge(Edge(W, RT, EdgeType.DIRECTED))
)
# Convert to Join Tree for inference
join_tree = InferenceController.apply(bbn)
# ---------------------------------------------------------
# 6️⃣  DRAW GRAPH
# ---------------------------------------------------------
pos = {0: (-1, 2), 1: (-1, 0.5), 2: (1, 0.5), 3: (0, -1)}
options = {
    "font_size": 16,
    "node_size": 4000,
    "node_color": "white",
    "edgecolors": "black",
    "edge_color": "red",
    "linewidths": 3,
    "width": 3,
}
n, d = bbn.to_nx_graph()
nx.draw(n, with_labels=True, labels=d, pos=pos, **options)
plt.axis("off")
plt.title("Bayesian Belief Network - Weather Prediction", fontsize=14)
plt.show()
# ---------------------------------------------------------
# 7️⃣  PRINT MARGINAL PROBABILITIES
# ---------------------------------------------------------
def print_probs():
    """Print marginal probabilities for all nodes."""
    for node in join_tree.get_bbn_nodes():
        potential = join_tree.get_bbn_potential(node)
        print("\nNode:", node)
        print(potential)
        print('----------------')
print("\n🌤️ Initial Marginal Probabilities:")
print_probs()
# ---------------------------------------------------------
# 8️⃣  ADD EVIDENCE & RECOMPUTE
# ---------------------------------------------------------
def add_evidence(node_name, category, value):
    """Add evidence to the join tree."""
    ev = (
        EvidenceBuilder()
        .with_node(join_tree.get_bbn_node_by_name(node_name))
        .with_evidence(category, value)
        .build()
    )
    join_tree.set_observation(ev)
print("\n☁️ Adding evidence: Humidity at 9am is >60 ...")
add_evidence('H9am', '>60', 1.0)
print("\n🔁 Updated Marginal Probabilities after Evidence:")
print_probs()
print("\n✅ Bayesian Belief Network executed successfully!")