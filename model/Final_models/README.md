
Please follow these steps to run the model:

1) First, unzip the model folders. Then, within each model folder, locate the `input`folder. Download the model forcing file, which is a large netCDF file, using the provided link:

[download forcing functions](https://drive.google.com/file/d/1SXuMMbNPUgF_BWalM0qYuwvGavvBLzsA/view?usp=sharing)

Save the forcing file within each model folder under the "./input/" subdirectory.

2) There are two options for running the model:

  a) Double click `Run_Raven.bat` file to run the model.
  b) In your Windows search bar, type “Command Prompt”. Once the command prompt window is open, navigate to the directory               containing your model you want to run (e.g., imagine this directory is C:\git\stmary) by typing “cd”, followed by a space and      the file path directory. For example:  

           cd C:\git\stmary 

To run the model, type the following line into the command prompt:   

          Raven.exe stmary -o out/ 

3) A new folder called "out" will be created in your new directory. Results will be saved there.

Good luck!
