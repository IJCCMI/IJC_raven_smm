@echo off
@TITLE SAVE BEST SOLUTION
echo saving input files for the best solution found...
IF NOT EXIST best mkdir best
set "sourceFolder=model"
set "destinationFolder=best"
xcopy "%sourceFolder%" "%destinationFolder%" /E /I /H /K /Y