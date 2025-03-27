#!/usr/bin/env python

import os
import sys
import argparse

def expand_vars(string, vars):
    while True:
        match = re.search(r'(.*?[^\\]|^|.*?\\\\)\${(.*?)}(.*)', string)
        if not match:
            break
        pre, var_name, post = match.groups()
        var_name = var_name.lower()
        value = vars.get(var_name, os.getenv(var_name, ''))
        string = f"{pre}{value}{post}"
    return string

def wchomp(line):
    return line.rstrip("\n\r")

parser = argparse.ArgumentParser(description="Script runner with variable expansion.",
                                 formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('-f', '--file', type=str, default='', help="Specify a command file.")
parser.add_argument('-n', action='store_true', help="Do not execute the command.")
parser.add_argument('-d', action='append', default=[], help="Define additional variables.")
parser.add_argument('--print-vars', action='store_true', help="Print variables and exit.")
parser.add_argument('args', nargs=argparse.REMAINDER, help="Additional arguments.")

args = parser.parse_args()

more_vars = {k.split('=')[0].lower(): k.split('=')[1] for k in args.d}

vars = {}
vars.update(more_vars)

if args.print_vars:
    for key, value in vars.items():
        print(f"{key}\t{value}")
    sys.exit(0)

script = args.args[0] if args.args else None

if not script:
    print("No script specified. Aborting.", file=sys.stderr)
    sys.exit(1)

if not os.path.isfile(script):
    print(f"Script {script} not found.", file=sys.stderr)
    sys.exit(1)

command = ""
with open(script, 'r') as file:
    for line in file:
        line = line.rstrip()
        if line.startswith("#"):
            continue
        command += expand_vars(line + " ", vars)

for arg in args.args[1:]:
    command += expand_vars(arg + " ", vars)

if args.n:
    if args.file:
        try:
            with open(args.file, 'w') as cmd_file:
                cmd_file.write(command + "\n")
        except IOError:
            print(f"Cannot create file {args.file}", file=sys.stderr)
            sys.exit(1)
    else:
        print(command)
else:
    os.system(command)
