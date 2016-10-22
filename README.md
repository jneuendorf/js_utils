# Jim's shrewd utilities

#### A collection of JavaScript utilities written in CoffeeScript.


The library contains the following modules:

- async
	- sequence
		- execute synchronous and asynchronous functions after each other
	- barrier
		- execute synchronous and asynchronous functions simultaneously
- hash
	- maps that allow anything as key
- overload
	- function overloading
- prototyping
	- adding helpful methods to built-in classes
- tree
	- tree structure
	- leaf class
	- binary tree

All modules are (hopefully) independent so far.


### Usage

See the [API documentation](http://jneuendorf.github.io/js_utils/) (yet incomplete).


### Building

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

The API is generated using [codo](https://github.com/coffeedoc/codo).
It can be regenerated with `./make docs`.
This command uses the `.codoopts` file with can be made with `./make codoopts`.
