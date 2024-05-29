import sys
from collections import Counter

def remove_lines(file_path):
    f = open(file_path,'r')
    lines = f.readlines()
    new_lines = []
    for line in lines:
        if "activat" not in line and "Exiting" not in line and "ID" not in line and line.strip() != "":
            new_lines.append(line)
    f.close()
    return new_lines
    

def most_common_command(lines, field_index):
    # Split each line into fields and extract the command name
    commands = []
    for line in lines:
        #print(line)
        commands.append(line.split()[field_index - 1])
    #commands = [line.split()[field_index - 1] for line in lines]

    # Count occurrences of each command
    command_counts = Counter(commands)

    # Find the most common command
    most_common_commands = command_counts.most_common()
    
    return most_common_commands

if __name__ == "__main__":
    # Check if the correct number of command-line arguments is provided
    if len(sys.argv) != 3:
        print("Usage: python script.py <file_path> <field_index>")
        sys.exit(1)

    # Get the file path and field index from command-line arguments
    file_path = sys.argv[1]
    field_index = int(sys.argv[2])

    lines = remove_lines(file_path)
    # Call the function to find the most common command
    most_common_commands = most_common_command(lines, field_index)

    # Display all commands and their number of occurrences
    print("Command Name\t\tOccurrences")
    for command, count in most_common_commands:
        print(f"{command}\t\t{count}")
