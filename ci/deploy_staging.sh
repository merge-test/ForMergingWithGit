#!/bin/bash
git config core.fileMode false
git checkout rtstaging
git fetch origin 
git pull origin rtstaging

#create deployment package
echo $CI_COMMIT_SHA
git diff HEAD^...$CI_COMMIT_SHA | force-dev-tool changeset create -f -d builds/ny-engineers/rt-nye/deployments $CI_COMMIT_SHA
#login to Staging instance
force-dev-tool remote add development adam@ny-engineers.com.rtstaging Engineers123!5eQuOg93BGfj2TIlmKdOJPiDu https://test.salesforce.com
force-dev-tool login development

#start deployment
echo "Starting deployment on Staging"
force-dev-tool deploy -d builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_SHA development
