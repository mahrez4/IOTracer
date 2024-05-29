import plotly.graph_objects as go
import plotly.express as px
import numpy as np

# Load your trace data or read it from a file
with open(r'viz_test_small', 'r') as file:
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


line_counter = 0
curr_state = ""
tid = 0
# Parse the trace data
for line in lines:
    line_counter += 1
    if "activat" in line or line == "\n" or line ==""   or "ID" in line:
        continue
    fields = line.split('\t')

    if tid == 0:
        tid = fields[8]
    if fields[8] != tid:
         continue
    
    if fields[1] == 'S': 
        if curr_state == "":
            if fields[6] == 'E':
                curr_state == 'E'
            else:
                continue
    
    if fields[1] == 'S':    
        if curr_state == 'E':
             if fields[6] == 'E':
                  start_times.pop()
                  start_times.append(int(fields[0]))
                  operation_types.append(fields[2])
                  print("successive Entry:", line_counter) 
                  continue
        if curr_state == 'L':
             if fields[6] == 'L':
                  continue

        if fields[6] == 'E':
            curr_state = 'E'
            colors.append((fields[2],"Entry"))
            color_entry.append((fields[2],"Entry"))
            start_times.append(int(fields[0]))
        else:
            curr_state = 'L'
            colors.append((fields[2],"Exit"))
            end_times.append(int(fields[0]))
        times.append(int(fields[0]))
        operation_types.append(fields[2])

# Create a Gantt chart
#fig = go.Figure()
        
d = []

print(start_times)
print(end_times)
for i in range(len(end_times)):
    if i >= min(len(start_times),len(end_times)):
        continue
    d.append(int(end_times[i]) - int(start_times[i]))
x= (np.array(start_times)-start_times[0])/10e6
x_end = (np.array(end_times)-start_times[0])/10e6

maximum = max(x_end)
duration=np.array(d)/10e6
print(d)

## Error checking
print("end_times:",len(end_times),"start_times",len(start_times))
for i,y in enumerate(d):
     if y < 0:
          d[i] = 0
          print("\nNegative duration\n")
          break

fig = px.scatter(x=x, y=np.ones(len(start_times)), error_x=duration, error_x_minus= np.zeros(len(start_times)), color=color_entry, render_mode="auto", facet_row=None)

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