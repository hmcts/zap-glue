# zap-glue
As every automated security testing provides the false positives, using this docker image in reform programme
False positives will be ignored/paused for time.

This repo manages the docker image of Zap and Glue integration which will read the Zap json report using jx parser
and filter/warn on the vulnerabilities
 

# Building 
This is a automated build on Dockerhub.  To build a new version ensure to tag the image and use the tagged image in your script

docker build -t hmcts/zap-glue:<version> .