% Define the file you want to add
fileToAdd = string(pwd) + filesep + "gitTest.m";  % Replace with the path to your file

% Add the specific file to the staging area
system(['git add ', char(fileToAdd)]);

% Optionally, commit the changes chwith a message
commitMessage = 'Add git test file for automated git requests';
system(['git commit -m "', commitMessage, '"']);
%%
branch = 'main';  % Replace with your branch name
system(['git push -u origin ', branch]);
