#!/bin/bash

checkTest=false
git config core.fileMode false
git checkout master
git fetch origin
git pull
git diff $CI_COMMIT_SHA^...$CI_COMMIT_SHA | force-dev-tool changeset create -f -d builds/ny-engineers/rt-nye/deployments $CI_COMMIT_REF_NAME
force-dev-tool remote add production dinesh@ny-engineers.com Nyei@2019S3L9hl3PbeZi90Re2K6g7aB1 https://login.salesforce.com
force-dev-tool login production

while read LINE
do
	if [[ $LINE = *"ApexClass"* ]] || [[ $LINE = *"ApexTrigger"* ]]; then
		checkTest=true
  	fi
done < builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME/package.xml

if $checkTest; then
	tests=$(php -f ci/extractTestClasses.php builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME/package.xml 2>&1)
	if [ ! -z "${tests// }" ]; then
		echo "Test deployment on production with test classes "$tests
		force-dev-tool deploy -ct --runTests "$tests" -d builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME production
	else
		echo "Error: There is no test class specified"
		exit 1
	fi
else
	echo "Test deployment on production"
	force-dev-tool deploy -ct --runTests=Test_ValidationClass -d builds/ny-engineers/rt-nye/deployments/$CI_COMMIT_REF_NAME production
fi
