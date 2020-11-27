npm install -g vector-web-setup
vector-web-setup configure
vector-web-setup ota-sync
vector-web-setup serve
start "" http://localhost:8000/



REM Add the new file to the inventory:
REM vector-web-setup ota-add https://github.com/cyb3rdog/victor/raw/master/firmware/prod/1.6.0.3331.ota
REM vector-web-setup ota-sync
REM Install it on a robot by running the software and selecting the new file.
REM Sign the file after you've verified it's good: 
REM vector-web-setup ota-approve 1.6.0.3331.ota
