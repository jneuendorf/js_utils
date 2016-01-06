# hash module - hashes/dictionaries

The `JSUtils.Hash` class provides a dictionary API.

The advantage is that ANYTHING can be used as a key unlinke plain objects! Also a default return value and a function for equality can be defined.

But beware - this was not build for performance.

## API

#### Standard

- put
- get
- remove
- empty
- size

#### Data about the hash

- getAll
- has
- getKeys
- getValues
- getKeysForValue

#### Potentially useful stuff

- clone
- invert
- each
- fromObject
- toObject

