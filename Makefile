.PHONY: build deps init init-if-needed up down rollout lint run test

DOCKER_IMAGE=libops/ojs:php83

deps:
	docker compose pull --ignore-buildable

build: deps
	docker compose build --pull

lint:
	./scripts/lint.sh


init: build
	docker compose run --rm init

init-if-needed: build
	./scripts/init-if-needed.sh

up: init-if-needed
	docker compose up --remove-orphans -d

down:
	docker compose down

rollout:
	./scripts/rollout.sh

run: up

test:
	./scripts/test.sh
