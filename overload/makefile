PROJ_NAME = jOverload
FILES = jOverload.coffee

make:
	cat $(FILES) | coffee --compile --stdio > $(PROJ_NAME).js

test:
	cat $(FILES) Test.coffee | coffee --compile --stdio > $(PROJ_NAME).js

production: make
	uglifyjs $(PROJ_NAME).js -o $(PROJ_NAME).min.js -c -m drop_console=true -d DEBUG=false
