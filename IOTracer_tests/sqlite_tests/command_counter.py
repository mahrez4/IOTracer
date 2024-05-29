import sys
from collections import Counter

def remove_lines(file_path):
    f = open(file_path,'r')
    lines = f.readlines()
    print(lines[0])
    if "activat" not in lines[0]:
        return 0
    f.close()
    nlines = lines[7:]
    f = open(file_path,'w')
    f.writelines(nlines)
    f.close()
    

def most_common_command(file_path, field_index):
    # Open the file for reading
    with open(file_path, 'r') as file:
            
        # Read all lines from the file
        lines = file.readlines()

        # Split each line into fields and extract the command name
        commands = [line.split()[field_index - 1] for line in lines]

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

    remove_lines(file_path)
    # Call the function to find the most common command
    most_common_commands = most_common_command(file_path, field_index)

    # Display all commands and their number of occurrences
    print("Command Name\t\tOccurrences")
    for command, count in most_common_commands:
        print(f"{command}\t\t{count}")
