# Jim's shrewd utilities

#### A collection of JavaScript utilities written in CoffeeScript.


The library contains the following modules:

- async
- hash
- overload
- prototyping
- tree

All modules are independent so far.

### Usage

See the `README.md` in the according module directory.

The files `js_utils.js` and `js_utils.min.js` can be created using the `make` shell script (using `./make`).

You can choose which modules to

- include using `./make --with module1 ... moduleN` or
- exclude using `./make --without module1 ... moduleN`.

Both cannot be combinded.


### Developing

Each module directory contains a `files.txt` file that lists all CoffeeScript files in the order they will be concatenated and compiled.

Additionally, there is a `testfiles.txt` file that accordingly lists the test specs files in the order they will be concatenated and compiled.

Unit testing is done using [Jasmine](https://jasmine.github.io/).

The test file can be built using `./make test`.
