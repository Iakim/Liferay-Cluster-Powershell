if not "x%JAVA_OPTS%" == "x" (
  echo "JAVA_OPTS already set in environment; overriding default settings with values: %JAVA_OPTS%"
  goto JAVA_OPTS_SET
)
:JAVA_OPTS_SET
set "JAVA_OPTS=%JAVA_OPTS% -server -Xmx4g -Xms4g -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -XX:SurvivorRatio=6 -Djboss.modules.policy-permissions=true -XX:+DoEscapeAnalysis -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=500 -XX:+UseFastAccessorMethods -XX:ParallelGCThreads=2 -Duser.language=pt -Duser.region=BR -Duser.country=BR -Djava.awt.headless=true  -XX:+UseCompressedOops -Duser.timezone=GMT"
