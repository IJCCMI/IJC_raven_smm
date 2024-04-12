@echo off
copy .\stmary.rvp model\stmary.rvp
cd model

REM run the raven executable, which creates the diagnostics file
Raven stmary -o out\

cd ..
