PACTICIPANT := "pactflow-example-provider-dotnet"
WEBHOOK_UUID := "46ed3f10-d03f-43cd-b945-ce45ff42d324"
TRIGGER_PROVIDER_BUILD_URL := "https://api.travis-ci.com/repo/pactflow%2Fexample-provider-dotnet/requests"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:latest"

# Only deploy from master
ifeq ($(TRAVIS_BRANCH),master)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

all: test

## ====================
## CI tasks
## ====================

restore:
	dotnet restore src
	dotnet restore tests

build:
	dotnet build --configuration Release --no-restore src
	dotnet build --no-restore tests

ci: restore start test stop can_i_deploy $(DEPLOY_TARGET)

test: start test_non_webhook stop

test_webhook: start test_pact stop

test_pact:
	dotnet test tests --filter FullyQualifiedName~Pact

start: server.PID

server.PID:
	{ dotnet run --project src & echo $$! > $@; }

stop: server.PID
	kill `cat $<` && rm $<

# Run the ci target from a developer machine with the environment variables
# set as if it was on Travis CI.
# Use this for quick feedback when playing around with your workflows.
fake_ci: .env
	CI=true \
	TRAVIS_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	TRAVIS_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	make ci

ci_webhook: .env
#	npm run test:pact
	make ci

fake_ci_webhook:
	CI=true \
	TRAVIS_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	TRAVIS_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci_webhook

## =====================
## Build/test tasks
## =====================

test_no_webhook: .env
	dotnet test tests

## =====================
## Deploy tasks
## =====================

deploy: deploy_app tag_as_prod

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy: .env
	@"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${TRAVIS_COMMIT} --to prod

deploy_app:
	@echo "Deploying to prod"

tag_as_prod:
	@"${PACT_CLI}" broker create-version-tag \
	  --pacticipant ${PACTICIPANT} \
	  --version ${TRAVIS_COMMIT} \
	  --tag prod

## =====================
## Pactflow set up tasks
## =====================

# export the TRAVIS_TOKEN environment variable before running this
# You can get your token from the Settings tab of https://travis-ci.com/account/preferences
create_travis_token_secret:
	@curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"travisToken\",\"description\":\"Travis CI Provider Build Token\",\"value\":\"${TRAVIS_TOKEN}\"}"

# NOTE: the travis token secret must be created (either through the UI or using the
# `create_travis_token_secret` target) before the webhook is invoked.
create_or_update_travis_webhook:
	@"${PACT_CLI}" \
	  broker create-or-update-webhook \
	  "${TRIGGER_PROVIDER_BUILD_URL}" \
	  --header "Content-Type: application/json" "Accept: application/json" "Travis-API-Version: 3" 'Authorization: token $${user.travisToken}' \
	  --request POST \
	  --data @${PWD}/pactflow/travis-ci-webhook.json \
	  --uuid ${WEBHOOK_UUID} \
	  --provider ${PACTICIPANT} \
	  --contract-content-changed \
	  --description "Travis CI webhook for ${PACTICIPANT}"

test_travis_webhook:
	@"${PACT_CLI}" broker test-webhook --uuid ${WEBHOOK_UUID}

## ======================
## Travis CI set up tasks
## ======================

travis_login:
	@docker run --rm -v ${HOME}/.travis:/root/.travis -it lirantal/travis-cli login --pro

travis_encrypt_pact_broker_token:
	@docker run --rm -v ${HOME}/.travis:/root/.travis -v ${PWD}:${PWD} --workdir ${PWD} lirantal/travis-cli encrypt --pro PACT_BROKER_TOKEN="${PACT_BROKER_TOKEN}"

## ======================
## Misc
## ======================

.env:
	touch .env

.PHONY: start stop