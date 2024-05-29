import pandas as pd
import matplotlib.pyplot as plt
import plotly.graph_objs as go
import plotly.express as px

# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_ringbufsize.csv')

# Remove NaN values


# Transpose the dataframe
df_t = df.set_index('Size').T

# Create box plots
fig = go.Figure()

for size in df['Size']:
    fig.add_trace(go.Box(y=df_t[size], name=size))

# Update layout
fig.update_layout(title='Box plots of runtimes for each ringbuffer size',
                  xaxis_title='Ringbuf size',
                  yaxis_title='Runtime (s)')

# Show plot
fig.show()




# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_kernel_api.csv')
df_t = df.set_index('API').T

# Create box plots
fig = go.Figure()

for api in df['API']:
    fig.add_trace(go.Box(y=df_t[api], name=api))

# Update layout
fig.update_layout(title='Box plots of runtimes for each kernel API',
                  xaxis_title='Kernel API',
                  yaxis_title='Runtime (s)')

# Show plot
fig.show()



# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_userspace_api.csv')
df_t = df.set_index('API').T

# Create box plots
fig = go.Figure()

for api in df['API']:
    fig.add_trace(go.Box(y=df_t[api], name=api))

# Update layout
fig.update_layout(title='Box plots of runtimes for each userspace API',
                  xaxis_title='Userspace API',
                  yaxis_title='Runtime (s)')

# Show plot
fig.show()

#####################################################


df = pd.read_csv('run_times_ringbufsize.csv')
df = df.fillna(0)
df = df.set_index('Size')




plt.xlabel('Ring buffer size')
plt.ylabel('Run Time (ms)')
plt.title('Execution runtimes for different ringbuf sizes')
df.T.boxplot()
plt.show()

# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_kernel_api.csv')

# Remove NaN values
plt.xlabel('Kernel API')
plt.ylabel('Run Time (ms)')
plt.title('Execution runtimes for different kernel APIs')
df = df.fillna(0)
df = df.set_index('API')
df.T.boxplot()
plt.show()


# Read the CSV file into a DataFrame
df = pd.read_csv('run_times_userspace_api.csv')

plt.xlabel('Userspace API')
plt.ylabel('Run Time (ms)')
plt.title('Execution runtimes for different userspace APIs')
# Remove NaN values
df = df.fillna(0)
df = df.set_index('API')
df.T.boxplot()
plt.show()
