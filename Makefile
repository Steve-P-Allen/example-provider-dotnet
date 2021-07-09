PACTICIPANT := "pactflow-example-provider-dotnet"
WEBHOOK_UUID := "46ed3f10-d03f-43cd-b945-ce45ff42d324"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli:latest"

# Only deploy from master
ifeq ($(GITHUB_BRANCH),master)
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
# set as if it was on GITHUB CI.
# Use this for quick feedback when playing around with your workflows.
fake_ci: .env
	CI=true \
	GITHUB_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	GITHUB_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	make ci

ci_webhook: .env
#	npm run test:pact
	make ci

fake_ci_webhook:
	CI=true \
	GITHUB_COMMIT=`git rev-parse --short HEAD`+`date +%s` \
	GITHUB_BRANCH=`git rev-parse --abbrev-ref HEAD` \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci_webhook

## =====================
## Build/test tasks
## =====================

test_non_webhook: .env
	dotnet test tests

## =====================
## Deploy tasks
## =====================

deploy: deploy_app tag_as_prod

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy: .env
	@"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${GITHUB_COMMIT} --to prod

deploy_app:
	@echo "Deploying to prod"

tag_as_prod:
	@"${PACT_CLI}" broker create-version-tag \
	  --pacticipant ${PACTICIPANT} \
	  --version ${GITHUB_COMMIT} \
	  --tag prod

## =====================
## Pactflow set up tasks
## =====================

# nop

## ======================
## Misc
## ======================

.env:
	touch .env

.PHONY: start stop