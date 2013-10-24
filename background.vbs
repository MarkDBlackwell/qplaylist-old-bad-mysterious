rem Author: Mark D. Blackwell
rem Date created: November 4, 2010
rem Date last changed: February 8, 2011
rem Usage:
rem   background.vbs <single parameter>
rem Usage example:
rem   background.vbs "ruby -r net/http -e 'loop{begin;Net::HTTP.get %q[google.com],%q[/index.html];rescue;end;sleep 60*5}"
rem==============
rem References:
rem   http://www.winhelponline.com/blog/run-bat-files-invisibly-without-displaying-command-prompt/
rem   http://msdn.microsoft.com/en-us/library/d5fk67ky(VS.85).aspx
rem   http://ns7.webmasters.com/caspdoc/html/vbscript_set_statement.htm
rem   http://leereid.wordpress.com/2008/01/10/sweet-vbscript-command-line-parameters/
Dim sh, s
rem Wscript.echo "hello"
if Wscript.Arguments.Count <= 0 then
  Wscript.echo "Needs an argument"
  Wscript.quit(-1)
end if
s = Wscript.Arguments(0)
rem Wscript.echo s
Set sh = CreateObject("WScript.Shell")
sh.Run s, 0
rem sh.Run s
rem sh.Run s, 7
rem sh.Run s, 99
rem Wscript.echo "came back"
Set sh = Nothing
Set s = Nothing
