import pandas as pd
import matplotlib.pyplot as plt
import plotly.graph_objs as go
import plotly.express as px

# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_ringbufsize.csv')

# Remove NaN values


# Transpose the dataframe
df_t = df.set_index('Size').T

# Calculate the mean runtime for each API
mean_runtimes = df_t.mean().sort_values()

# Create box plots
fig = go.Figure()

for api in mean_runtimes.index:
    fig.add_trace(go.Box(y=df_t[api], name=api))

# Update layout
fig.update_layout(title='Box plots of runtimes for each ringbuffer size',
                  xaxis_title='Ringbuf size',
                  yaxis_title='Runtime (ms)')

# Show plot
fig.show()




# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_kernel_api.csv')
df_t = df.set_index('API').T

# Calculate the mean runtime for each API
mean_runtimes = df_t.mean().sort_values()

# Create box plots
fig = go.Figure()

for api in mean_runtimes.index:
    fig.add_trace(go.Box(y=df_t[api], name=api))

# Update layout
fig.update_layout(title='Box plots of runtimes for each kernel API',
                  xaxis_title='Kernel API',
                  yaxis_title='Runtime (ms)')

# Show plot
fig.show()



# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_userspace_api.csv')
df_t = df.set_index('API').T

# Calculate the mean runtime for each API
mean_runtimes = df_t.mean().sort_values()

# Create box plots
fig = go.Figure()

for api in mean_runtimes.index:
    fig.add_trace(go.Box(y=df_t[api], name=api))

# Update layout
fig.update_layout(title='Box plots of runtimes for each userspace API',
                  xaxis_title='Userspace API',
                  yaxis_title='Runtime (ms)')

# Show plot
fig.show()

# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_storage.csv')
df_t = df.set_index('Trace storage').T

# Calculate the mean runtime for each API
mean_runtimes = df_t.mean().sort_values()

# Create box plots
fig = go.Figure()

for method in mean_runtimes.index:
    fig.add_trace(go.Box(y=df_t[method], name=method))

# Update layout
fig.update_layout(title='Box plots of runtimes for each trace storage method',
                  xaxis_title='Storage method',
                  yaxis_title='Runtime (ms)')

# Show plot
fig.show()

#####################################################