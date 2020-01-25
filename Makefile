CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
JSON=node_modules/.bin/json

all: build/addendum.docx build/addendum.pdf

build/%.pdf: build/%.docx
	unoconv $<

build/%.docx: build/%.form.json build/%.signatures.json build/%.title styles.json | build $(CFDOCX)
	$(CFDOCX) --title "$(shell cat build/$*.title)" --signatures build/$*.signatures.json build/$*.form.json --left-align-title --indent-margins --number outline --styles styles.json > $@

build/%.parsed.json: %.md | build $(CFCM)
	$(CFCM) parse < $< > $@

build/%.form.json: build/%.parsed.json | $(JSON)
	$(JSON) form < $< > $@

build/%.signatures.json: build/%.parsed.json | $(JSON)
	$(JSON) frontMatter.signaturePages < $< > $@

build/%.title: build/%.parsed.json | $(JSON)
	$(JSON) frontMatter.title < $< > $@

build:
	mkdir -p build

$(CFCM):
	npm ci

.PHONY: clean docker

clean:
	rm -rf build

docker:
	docker build -t ccpa-addendum .
	docker run --name ccpa-addendum ccpa-addendum
	docker cp ccpa-addendum:/workdir/build .
	docker rm ccpa-addendum
