@if (@X)==(@Y) @end /* JScript comment 
        @echo off 
       
        rem :: the first argument is the script name as it will be used for proper help message 
        cscript //E:JScript //nologo "%~f0" "%~nx0" %* 
        exit /b %errorlevel% 
@if (@X)==(@Y) @end JScript comment */ 


var sh=new ActiveXObject("WScript.Shell"); 
var ARGS = WScript.Arguments; 
var scriptName=ARGS.Item(0); 

var title="";

function printHelp() { 
    WScript.Echo(scriptName + " - focus applicaion with given title or PID"); 
    WScript.Echo("Usage:"); 
    WScript.Echo("call " + scriptName + " <title>"); 
    WScript.Echo("title  - the title or PID of the application"); 
} 

function parseArgs() {
    if (ARGS.Length < 2) { 
            WScript.Echo("insufficient arguments"); 
            printHelp(); 
            WScript.Quit(43);
    }

    title=ARGS.Item(1);
}

parseArgs();
if (sh.AppActivate(title)){
	WScript.Quit(0);
} else {
	WScript.Echo("Failed to find application with title " + title);
	WScript.Quit(1);
}
