@echo OFF
REM="""
setlocal
set PythonExe=""
set PythonExeFlags=
for %%i in (cmd bat exe) do (
    for %%j in (python.%%i) do (
        call :SetPythonExe "%%~$PATH:j"
    )
)
for /f "tokens=2 delims==" %%i in ('assoc .py') do (
    for /f "tokens=2 delims==" %%j in ('ftype %%i') do (
        for /f "tokens=1" %%k in ("%%j") do (
            call :SetPythonExe %%k
        )
    )
)
%PythonExe% -x %PythonExeFlags% "%~f0" %*
exit /B %ERRORLEVEL%
goto :EOF
:SetPythonExe
if not ["%~1"]==[""] (
    if [%PythonExe%]==[""] (
        set PythonExe="%~1"
    )
)
goto :EOF
"""

#!/usr/bin/env python

import nbformat
import subprocess
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('notebook', type=str, nargs=1,
                    help='notebookfile')
parser.add_argument('--linter', type=str,
                    help='Which linter to use')

args = parser.parse_args()

nb = nbformat.read(args.notebook[0], as_version=4)
linter = args.linter
code_cells = [i.source for i in nb.cells if i.cell_type == 'code']
commands = {'pycodestyle': (['pycodestyle', 'tmp.py'], 'tmp.py'), 'eslint':
            (['eslint', 'tmp.js'], 'tmp.js'),
            'golint': (['/Users/acb/work/bin/golint', 'tmp.go'], 'tmp.go'),
            'lintjl': (['julia -e "using Lint; "', 'tmp.jl'], 'tmp.jl'),
            'lintr': (['/Library/Frameworks/R.framework/Resources/Rscript',
                      'rlint.r', 'tmp.r'], 'tmp.r'),
            'pyflakes': (['pyflakes', 'tmp.py'], 'tmp.py')}


class BaseLinter:
    def __init__(self):
        self.nb = nb
        self.linter = linter
        self.code_cells = code_cells
        self.commands = commands

    def checkCells(self, linter, command):
        for i in range(len(self.code_cells)):
            self.outfile = self.commands[command][1]
            with open(self.outfile, "w") as f:
                lines = self.code_cells[i].split("\n")
                for line in lines:
                    f.write(line + "\n")
            out = subprocess.Popen(self.commands[command][0],
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT
                                   ).communicate()[0]
            if not out:
                pass
            else:
                print("Code Cell %s that starts with '%s' has the following \
                      errors\n" % (i, lines[0]), out.decode("utf-8"))
            os.remove(self.outfile)

    def checkFile(self, linter, command):
        self.outfile = self.commands[command][1]
        with open(self.outfile, "w") as f:
            for i in range(len(self.code_cells)):
                lines = self.code_cells[i].split("\n")
                for line in lines:
                    f.write(line + "\n")
        out = subprocess.Popen(self.commands[command][0],
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT).communicate()[0]
        if not out:
            pass
        else:
            print("Code Cell %s that starts with '%s' has the following flake8\
                  errors\n"
                  % (i, lines[0][:10]), out.decode("utf-8"))
            os.remove(self.outfile)


if not linter:
    BaseLinter().checkCells(linter, 'pycodestyle')

if linter == 'eslint':
    BaseLinter().checkCells(linter, 'eslint')

if linter == 'lintr':
    BaseLinter().checkCells(linter, 'lintr')

if linter == 'golint':
    BaseLinter().checkCells(linter, 'golint')

if linter == 'lintjl':
    BaseLinter().checkCells(linter, 'lintjl')

if linter == 'pyflakes':
    BaseLinter().checkFile(linter, 'pyflakes')
