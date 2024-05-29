import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

# Parse the provided I/O trace

with open(r'viz_test_small_2', 'r') as file:
	data = file.read() 


lines = data.strip().split('\n')
timestamps = []
levels = []
actions = []
entry_leave = []
x = "activate"
for line in lines:
    if line == "" or x in line:
        continue
    #print(line)
    
    #x+= 1
    #print(fields)
    fields = line.strip(' ').split('\t')
    #if fields[1] != 'S':
    #    continue
    timestamps.append(int(fields[0]))
    levels.append(fields[1])
    actions.append(fields[2])
    entry_leave.append(fields[6])

# Convert timestamps to milliseconds for better readability
timestamps_ms = [(ts - timestamps[0]) / 1e6 for ts in timestamps]

# Create a timeline plot
fig, ax = plt.subplots(figsize=(12, 6))

# Plot ENTRY/LEAVE events as vertical lines
for i, action in enumerate(entry_leave):
    if levels[i] == 'S':
        color = "green"
    elif levels[i] == 'V':
        color = "purple"
    elif levels[i] == 'F':
        color = "orange"
    elif levels[i] == 'B':
        color = "red"
    elif levels[i] == 'X':
        color = "pink"
    elif levels[i] == 'Y':
        color = "blue"
    elif levels[i] == 'Z':
        color = "teal"
    elif levels[i] == 'A':
        color = "black"
    elif levels[i] == 'D':
        color = "grey"
    if action == 'E':
        ax.vlines(timestamps_ms[i], 0, 1, colors=color, linestyles='dashed', label='ENTRY')
    elif action == 'L':
        ax.vlines(timestamps_ms[i], 0, 1, colors=color, linestyles='solid', label='LEAVE')
    
# Customize the plot
ax.set_yticks([])
ax.set_xlabel('Timestamp (ms)')
ax.set_title('I/O Trace Timeline')

# Add legend
legend_elements = [Line2D([0], [0], color='black', linestyle='dashed', label='ENTRY'),
                   Line2D([0], [0], color='black', linestyle='solid', label='LEAVE'),
                   Line2D([0], [0], color='green', linestyle='solid', label='SYS'),
                   Line2D([0], [0], color='purple', linestyle='solid', label='VFS'),
                   Line2D([0], [0], color='orange', linestyle='solid', label='FS'),
                   Line2D([0], [0], color='red', linestyle='solid', label='BLK'),]
ax.legend(handles=legend_elements)

# Show the plot
plt.show()
