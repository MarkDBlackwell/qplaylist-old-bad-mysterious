rem Author: Mark D. Blackwell (google me)
rem October 9, 2013 - created
rem October 10, 2013 - comment out firewall-blocked ftp
rem Description:

rem This Windows batch file:
rem 1. obtains the input for a certain program;
rem 2. runs that program;
rem 3. copies the program's output to another directory (wherever desired);
rem 4. runs an FTP program to upload that output file.

rem This batch file, and the associated program,
rem along with that program's input and output files,
rem all reside in the same directory.
rem This directory should reside on a user's computer (and not on the WideOrbit server computer).

rem See the program's source code file for its description.

rem Select disk drive c:
c:
rem Change the current directory to that containing the batch file:
rem %~p0 is the path to the script, per:
rem http://stackoverflow.com/questions/357315/get-list-of-passed-arguments-in-windows-batch-script-bat
cd %~p0

rem Copy input files:
rem Access WideOrbit's server computer by customizing this network drive letter (here, z:) if necessary:
start /wait cmd /C copy /Y z:\NowPlaying\Template.html template.html
start /wait cmd /C copy /Y z:\NowPlaying.xml input.xml

rem Run the program:
start /wait cmd /C ruby playlist.rb

rem Copy output files:
start /wait cmd /C copy /Y output.html z:\NowPlaying\NowPlaying.html

rem FTP the output to a webserver computer:
rem If FTP can succeed locally, uncomment this:
rem start /wait cmd /C ftp -s:z:\NowPlaying\NowPlaying.ftp

rem Otherwise, if FTP fails locally (perhaps due to firewall blockage), then FTP from the z: drive's server computer.
