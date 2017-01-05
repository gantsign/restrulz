#!/bin/bash

API=https://api.bintray.com
BINTRAY_OWNER=gantsign
BINTRAY_REPO=eclipse
PCK_NAME=restrulz
PCK_VERSION=${TRAVIS_TAG}
UPDATE_SITE_ZIP=(restrulz.repository/target/restrulz.repository-*.zip)

echo "Uploading: ${UPDATE_SITE_ZIP}"

curl \
	"-u${BINTRAY_USER}:${BINTRAY_API_KEY}" \
	-H Content-Type:application/json \
	-H Accept:application/json \
	-H "X-Bintray-Package:${PCK_NAME}" \
	-H "X-Bintray-Version:${PCK_VERSION}" \
	-H X-Bintray-Publish:1 \
	-H X-Bintray-Override:1 \
	-H X-Bintray-Explode:1 \
	-T "${UPDATE_SITE_ZIP}" \
	"${API}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/"
