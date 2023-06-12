# Mr Nerds Jamf Bash (scripts) 
These are some scripts I wrote to give Jamf the specific functionality that I was looking for that was essentially missing.

## The Policy Playlist

This Script can be added in to jamf for running computer scripts in a specific order. 
I just didn't like how Jamf ran their policy ordering, so I made a simple bash script to validate and run all the scripts required in order. 

# The Kitchen Sink

This Script is kind of a "do a lot with very little configuration. Still Requires a bit of tidying but it works. 
Parameters.
$4 == path or URI you want to launch. 
    note: I do try to have this automatically guess what you need. 
    it validates by trying to figure out what the type is.
    pseudo-bash: 
```bash
    if [ "has_slash_and_Colon" ]; then
        must be a uri
    elif [ "has_slash" ]; then
    probably a path
    else 
    maybe it's just an application name
fi
```
$5 = Override Flags
lets you throw in parameter flags for the "Open" command in macos.

```bash
     -a Application
     -n  Open a new instance of the application(s) even if one is already running.
     -g  Do not bring the application to the foreground.
     -j  Launches the app hidden.
     -u  Launch a URL in your browser (Or applicable Application)
```

$6 Run the application in a new process.
    Great if you don't want this to get in the way of running other tools or applications off of jamf. I usually use this alongside a Notifier or Dialog to display something while I launch the application, but knowing what it does, you can definitely get a little creative. 

$7 File Validation path
    This is because I don't like how some things don't have any easy validation. This is more targeted at the lowest **those** users, who will open a task that is sent to them, close it, and jamf will have seen that as "Has Run" and either disappear it
    OR 
    who will see that the button is still there after it runs and then try and click it a million times if you leave a self service policy to ongoing. 

$8 EXTRA_FUNCTIOn
currently just a switch that has 0...3 as parameters accepted. 
if the EXTRA_FUNCTION call is any single on of these parameters it has a different side effect.
if 0 ... it'll run completely normal.
if 1, it'll Kill the task before relaunching it. 
if 2, it'll kill the task. Full stop. 
if 3, it'll run the validation function, to be used in conjunction with the "Validate Path" parameter. 

This is a nice extra little scratch space where you can also just add a lot of other functions and make it more usable for less-bash-friendly technicians.
