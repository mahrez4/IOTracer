import dash
from dash import dcc, html
import pandas as pd
import plotly.graph_objs as go
from plotly.subplots import make_subplots

# Function to calculate overhead compared to "notracing"
def calculate_overhead(df, reference_label='notracing'):
    mean_runtimes = df.mean()
    notracing_mean = mean_runtimes[reference_label]
    overhead = ((mean_runtimes - notracing_mean) / notracing_mean) * 100
    overhead = overhead.drop(reference_label)  # Remove "notracing" from overhead calculation
    return overhead

# Function to create combined plot with box plot and overhead table
def create_combined_plot(df, x_label, y_label, title):
    df_t = df.set_index(df.columns[0]).T
    mean_runtimes = df_t.mean().sort_values()
    
    # Create a subplot figure with 'domain' type for the table
    fig = make_subplots(
        rows=2, cols=1,
        specs=[[{"type": "xy"}],
               [{"type": "domain"}]],
        subplot_titles=[title, 'Overhead compared to no tracing'],
        row_heights=[0.7, 0.3]
    )
    
    # Add box plots
    for param in mean_runtimes.index:
        fig.add_trace(go.Box(y=df_t[param], name=param), row=1, col=1)
    
    fig.update_xaxes(title_text=x_label, row=1, col=1)
    fig.update_yaxes(title_text=y_label, row=1, col=1)

    # Calculate overhead and add table
    overhead = calculate_overhead(df_t)
    table = go.Table(
        header=dict(values=["Config", "Overhead (%)"],
        	height=45,
        	font=dict(size=22, family='Calibri', color='black'),
        	align='center',  # Center text vertically
        	),
        cells=dict(values=[overhead.index, overhead.round(2)],
        	height=30,
        	font=dict(size=20, family='Calibri',color='rgb(30, 30, 150)'),
        	align='center',  # Center text vertically
        	)
    )
    fig.add_trace(table, row=2, col=1)
    
    fig.update_layout(height=1000)
    return fig

# Initialize Dash app
app = dash.Dash(__name__)

# Read CSV files and create plots
files = ['run_times_ringbufsize.csv', 'run_times_kernel_api.csv', 'run_times_userspace_api.csv', 'run_times_storage.csv']
titles = [
    'Box plots of runtimes for each ringbuffer size',
    'Box plots of runtimes for each kernel API',
    'Box plots of runtimes for each userspace API',
    'Box plots of runtimes for each trace storage method'
]
x_labels = ['Ringbuf size', 'Kernel API', 'Userspace API', 'Storage method']
y_label = 'Runtime (ms)'

# Generate figures for each CSV file
figures = []
for file, title, x_label in zip(files, titles, x_labels):
    df = pd.read_csv(file)
    fig = create_combined_plot(df, x_label, y_label, title)
    figures.append(fig)

# Layout of the Dash app
app.layout = html.Div([
    html.H2("FIO Results"),
    html.Div([
        dcc.Graph(figure=fig,style={'marginBottom': 0, 'marginTop': 10}) for fig in figures
    ])
])

# Run the Dash app
if __name__ == '__main__':
    app.run_server(debug=True,port=8054)
