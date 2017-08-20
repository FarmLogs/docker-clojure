name = quay.io/farmlogs/clojure
version = v2
tag = $(name):$(version)

all: test

build:
	docker build . -t $(tag)

test/Main.class:
	javac test/Main.java

test/test-standalone.jar: test/Main.class
	cd test && jar cfe test-standalone.jar Main Main.class

build-test-image: build test/test-standalone.jar
	docker build ./test -t farmlogs/clojure-test:test

test: build-test-image
	test/run-tests.sh

push: test
	docker push $(tag)

clean:
	rm -f test/Main.class test/test-standalone.jar
