#!/bin/bash

checkTest=false
git config core.fileMode false
git checkout rtstaging
git fetch origin
git pull
git diff origin/rtstaging...origin/$CI_COMMIT_REF_NAME | force-dev-tool changeset create -f -d builds/ny-engineers/rt-nye/deployments $CI_COMMIT_REF_NAME
force-dev-tool remote add development adam@ny-engineers.com.rtstaging Engineers123!5eQuOg93BGfj2TIlmKdOJPiDu https://test.salesforce.com
force-dev-tool login development

while read LINE
do
	if [[ $LINE = *"ApexClass"* ]] || [[ $LINE = *"ApexTrigger"* ]]; then
		checkTest=true
  	fi
done < builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME/package.xml

if $checkTest; then	
	tests=$(php -f ci/extractTestClasses.php builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME/package.xml 2>&1)
	if [ ! -z "${tests// }" ]; then
		echo "Test deployment on Staging with test classes "$tests
		force-dev-tool deploy -ct --runTests "$tests" -d builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME development
	else
		echo "Error: There is no test class specified"
		exit 1
	fi
else
	echo "Test deployment on Staging"
	force-dev-tool deploy -c -d builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME development
fi
