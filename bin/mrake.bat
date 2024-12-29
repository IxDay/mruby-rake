@echo off

rem https://stackoverflow.com/questions/32107998/how-to-create-a-unique-temporary-file-path-in-command-prompt-without-external-to#answer-32109191
:uniqLoop
set "script=%tmp%\bat~%RANDOM%.tmp"
if exist "%script%" goto :uniqLoop

echo self.extend Rake::DSL; Rake.application.run > "%script%"
call mruby "%script%" %*
del "%script%"
exit /B
