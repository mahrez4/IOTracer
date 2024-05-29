import plotly.graph_objects as go
import plotly.express as px
import numpy as np

# Load your trace data or read it from a file
with open(r'trace_output_bcc', 'r') as file:
	data = file.read() 

lines = data.strip().split('\n')

# Initialize lists to store data
start_times = []
end_times = []
operation_types = []
color_entry =[]
color_exit = []

times = []
colors = []

# Parse the trace data
for line in lines:
    if "activate" in line or line == "\n" or line ==""   or "ID" in line:
        continue
    fields = line.split('\t')
    if fields[6] == 'E':
        colors.append((fields[2],"Entry"))
    else:
        colors.append((fields[2],"Exit"))
    times.append(int(fields[0]))
    operation_types.append(fields[2])

# Create a Gantt chart
#fig = go.Figure()

x=(np.array(times)-times[0])/10e6

fig = px.scatter(x=x, y=np.ones(len(times)),color=colors)
#fig.add_traces(
#    list(px.scatter(x=end_times, y=np.ones(len(end_times)), color=color_exit).select_traces())
#)

#for start, end, operation_type in zip(start_times, end_times, operation_types):
#    fig.add_trace(go.Bar(
#        x=[dict(Task=operation_type, Start=start, Finish=end)],
#        orientation='h',
#        name=f"{operation_type} operation"
#    ))

# Customize the layout
fig.update_layout(
    title='I/O Operations Timeline',
    yaxis=dict(showgrid=False, showline=False, zeroline=False, showticklabels=True),
    xaxis=dict(type='linear', tickangle=-45),
)

# Show the plot
fig.show()