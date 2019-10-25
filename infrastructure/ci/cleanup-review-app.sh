set -x
number=`curl -H "Accept: application/vnd.github.groot-preview+json" https://api.github.com/repos/UKGovernmentBEIS/beis-opss/commits/$TRAVIS_COMMIT/pulls | jq '.[0] | .number'`

./infrastructure/ci/install-cf.sh
cf login -a api.london.cloud.service.gov.uk -u $CF_USERNAME -p $CF_PASSWORD -o 'beis-opss' -s $SPACE
cf delete cosmetics-pr-$number-web
cf delete-service cosmetics-review-redis-$number
cf logout
