# overload module - overloading functions

To create an overloaded function just call the `JSUtils.overload()` function and start overloading.
The `overload()` function expects a list of parameters where a parameter can either be an `argument-list definition` or a `function definition`.

An `argument-list definition` is either an `Array` or a plain `Object`.

- `Array`: Each array element defines the type of the according argument in the list of parameters.
- `Object`: Each key-value pair defines the type of the argument with the name of the key as the type according to the value.

For each behavior in an overloaded function there can be multiple `argument-list definitions` (that lead to the same behavior). This can be seen in the last block of the example below.


### Example:

```CoffeeScript
class MyClass

    method1: JSUtils.overload(
        {a: Number, b: String}
        (a, b) ->
            return a + parseInt(b, 10)

        {a: String, b: Number}
        (a, b) ->
            return parseInt(a, 10) + b

        [Boolean, String]
        [String, Boolean]
        (x, y) ->
            return x + y
    )
```

See `test.coffee` for details.
