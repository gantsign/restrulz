#!/bin/bash

set -e

echo ""
echo "*********************************"
echo "* Deploying to Maven repository *"
echo "*********************************"
echo ""

./mvnw deploy --settings .travis/settings.xml -P publish-artifacts --batch-mode

echo ""
echo "************************************"
echo "* Deploying to Eclipse Update Site *"
echo "************************************"
echo ""

.travis/publish-p2-updatesite.sh
