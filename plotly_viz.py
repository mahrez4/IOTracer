import pandas as pd
import plotly.express as px

# Load the trace data into a pandas DataFrame
data = pd.read_csv("trace_output.csv", sep=",", header=None)
data.columns = ['timestamp', 'level', 'operation', 'address', 'size', 'probe_number', 'enter_leave', 'pid', 'tid', 'command', 'inode', 'inode_p']

#### Convert timestamp to datetime
#data['timestamp'] = pd.to_datetime(data['timestamp'], unit='ns')

#### Time Series Plot of I/O Operations Over Time
#fig = px.line(data, x='timestamp', y='operation', color='operation', title='I/O Operations Over Time')
#fig.show()

#### Stacked Bar Chart of Operations by Level
#fig = px.bar(data, x='level', color='operation', title='Operations by Level')
#fig.show()

### Scatter Plot of Operation Size vs. Timestamp
#fig = px.scatter(data, x='timestamp', y='size', title='Operation Size vs. Timestamp')
#fig.show()

#### Box Plot of Operation Size by Level
#fig = px.box(data, x='level', y='size', title='Operation Size Distribution by Level')
#fig.show()

#### Heatmap of Operation Frequency by Level and Operation Type
fig = px.histogram(data, x='operation', y='size', color='operation', marginal='histogram', title='Operation Frequency by Level and Operation Type')
fig.show()

#### Stacked Bar Chart of Operations by Command
#fig = px.bar(data, x='command', color='operation', title='Operations by Command')
#fig.show()

#### Scatter Plot of Operation Size vs. Address
#fig = px.scatter(data, x='address', y='size', title='Operation Size vs. Address')
#fig.show()

#### Histogram of Operation Sizes Grouped by Command
fig = px.histogram(data, x='size', color='command', title='Operation Size Distribution by Command')
fig.show()

#### Sunburst Chart of Operation Flow
fig10 = px.sunburst(data, path=['level', 'operation'], title='Operation Flow')
fig10.show()