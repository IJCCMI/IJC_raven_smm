@echo off
copy .\milk.rvp model\milk.rvp
cd model

REM run the raven executable, which creates the diagnostics file
Raven milk -o out\

cd ..
