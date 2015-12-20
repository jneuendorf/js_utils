// Generated by CoffeeScript 1.10.0
(function() {
  var slice = [].slice;

  window.DEBUG = true;

  describe("async", function() {
    describe("Sequence", function() {
      beforeEach(function() {
        var Helper;
        this.sequence = new JSUtils.Sequence([], false);
        Helper = (function() {
          function Helper(delay) {
            if (delay == null) {
              delay = 1000;
            }
            this.cbs = [];
            this.isDone = false;
            this.delay = delay;
          }

          Helper.prototype.go = function(result) {
            return window.setTimeout((function(_this) {
              return function() {
                _this.isDone = true;
                if (result != null) {
                  result.push(_this.delay);
                }
                return _this._done();
              };
            })(this), this.deplay);
          };

          Helper.prototype._done = function() {
            var cb, j, len, ref, results;
            ref = this.cbs;
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
              cb = ref[j];
              results.push(cb());
            }
            return results;
          };

          Helper.prototype.done = function(cb) {
            this.cbs.push(cb);
            if (this.isDone) {
              this._done();
            }
            return this;
          };

          return Helper;

        })();
        return this.helperClass = Helper;
      });
      it("execute synchronous functions in correct order", function(done) {
        var result;
        result = [];
        this.sequence.start([
          {
            func: function() {
              return result.push("func1");
            }
          }, {
            func: function() {
              return result.push("func2");
            }
          }, [
            function() {
              return result.push("func3");
            }
          ]
        ]);
        return this.sequence.done(function() {
          expect(result).toEqual(["func1", "func2", "func3"]);
          return done();
        });
      });
      it("execute asynchronous in correct order", function(done) {
        var Helper, result;
        result = [];
        Helper = this.helperClass;
        this.sequence.start([
          {
            func: function() {
              var h;
              h = new Helper(3000);
              h.go(result);
              return h;
            }
          }, {
            func: function() {
              var h;
              h = new Helper(1000);
              h.go(result);
              return h;
            }
          }, [
            function() {
              var h;
              h = new Helper(1500);
              h.go(result);
              return h;
            }
          ]
        ]);
        return this.sequence.done(function() {
          expect(result).toEqual([3000, 1000, 1500]);
          return done();
        });
      });
      it("apply different contexts to sequence functions", function(done) {
        var result, self;
        result = [];
        this.sequence.start([
          {
            func: function() {
              return result.push(this);
            },
            scope: window
          }, {
            func: function() {
              return result.push(this);
            },
            scope: this
          }
        ]);
        self = this;
        return this.sequence.done(function() {
          expect(result[0] === window).toBe(true);
          expect(result[1] === self).toBe(true);
          return done();
        });
      });
      it("access previous results", function(done) {
        this.sequence.start([
          {
            func: function() {
              return 2;
            }
          }, {
            func: function(a) {
              return a + 8;
            },
            scope: this
          }
        ]);
        return this.sequence.done(function(lastResult) {
          expect(lastResult).toBe(10);
          return done();
        });
      });
      it("execute done-callbacks on completion and aftewards", function(done) {
        var result;
        result = [];
        this.sequence.start([
          {
            func: function() {
              return 2;
            }
          }, {
            func: function(a) {
              return a + 8;
            },
            scope: this
          }
        ]);
        return this.sequence.done((function(_this) {
          return function(lastResult) {
            result.push("first");
            return _this.sequence.done(function() {
              result.push("second");
              expect(result).toEqual(["first", "second"]);
              return done();
            });
          };
        })(this));
      });
      it("nested sequences (and previous result access)", function(done) {
        var result;
        result = [];
        this.sequence.start([
          {
            func: function() {
              return result.push("func1");
            }
          }, {
            func: function() {
              result.push("func2");
              return new JSUtils.Sequence([
                {
                  func: function() {
                    result.push("func2.1");
                    return 2;
                  }
                }, {
                  func: function(shouldBeTwo) {
                    result.push("func2.2 -> " + shouldBeTwo);
                    return shouldBeTwo * 3;
                  }
                }
              ]);
            }
          }, [
            function(shouldBeSix) {
              return result.push("func3 -> " + shouldBeSix);
            }
          ]
        ]);
        return this.sequence.done(function() {
          expect(result).toEqual(["func1", "func2", "func2.1", "func2.2 -> 2", "func3 -> 6"]);
          return done();
        });
      });
      it("stopping (no more functions in sequence will be executed, callbacks will still fire)", function(done) {
        var Helper, h1, result;
        result = [];
        Helper = this.helperClass;
        h1 = null;
        this.sequence.start([
          {
            func: function() {
              h1 = new Helper(3000);
              h1.go(result);
              h1.done((function(_this) {
                return function() {
                  return _this.sequence.stop();
                };
              })(this));
              return h1;
            },
            scope: this
          }, {
            func: function() {
              var h;
              h = new Helper(1000);
              h.go(result);
              return h;
            }
          }, [
            function() {
              var h;
              h = new Helper(1500);
              h.go(result);
              return h;
            }
          ]
        ]);
        return this.sequence.done(function() {
          expect(result).toEqual([3000]);
          return done();
        });
      });
      it("interrupting (no more functions in sequence will be executed, callbacks will not fire)", function(done) {
        var Helper, h1, result;
        result = [];
        Helper = this.helperClass;
        h1 = null;
        this.sequence.start([
          {
            func: function() {
              h1 = new Helper(3000);
              h1.go(result);
              h1.done((function(_this) {
                return function() {
                  _this.sequence.interrupt();
                  return window.setTimeout(function() {
                    expect(result).toEqual([3000]);
                    return done();
                  }, 2000);
                };
              })(this));
              return h1;
            },
            scope: this
          }, {
            func: function() {
              var h;
              h = new Helper(1000);
              h.go(result);
              return h;
            }
          }, [
            function() {
              var h;
              h = new Helper(1500);
              h.go(result);
              return h;
            }
          ]
        ]);
        return this.sequence.done(function() {
          return result.push("should not be in result!");
        });
      });
      it("stopping & interrupting on error", function(done) {
        var Helper, result, self;
        result = [];
        Helper = this.helperClass;
        self = this;
        this.sequence.onError(function() {
          var args, error;
          error = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
          expect(result).toEqual([3000]);
          expect(this === self).toBe(true);
          expect(error.message).toBe("Whatever!");
          expect(args[0]).toBe(1);
          expect(args[1]).toBe(2);
          return done();
        }, this, 1, 2);
        return this.sequence.start([
          {
            func: function() {
              var h;
              h = new Helper(3000);
              h.go(result);
              return h;
            }
          }, {
            func: function() {
              throw new Error("Whatever!");
            }
          }, [
            function() {
              var h;
              h = new Helper(1500);
              h.go(result);
              return h;
            }
          ]
        ]);
      });
      it("returning a doneable object will also make it accessible in the next function", function(done) {
        var Helper, h, result;
        result = [];
        Helper = this.helperClass;
        h = null;
        this.sequence.start([
          {
            func: function() {
              h = new Helper(3000);
              h.go();
              return h;
            },
            scope: this
          }, {
            func: function(prevH) {
              result.push(prevH === h);
              return 2;
            }
          }
        ]);
        return this.sequence.done(function() {
          expect(result).toEqual([true]);
          return done();
        });
      });
      it("use context to pass multiple parameters for next function in sequence", function(done) {
        var Helper, result;
        result = [];
        Helper = this.helperClass;
        this.sequence.start([
          {
            func: function() {
              var h;
              h = new Helper(3000);
              h.go();
              return {
                done: h,
                context: {
                  a: 1,
                  b: 2
                }
              };
            },
            scope: this
          }, {
            func: function(b, a) {
              var h;
              result.push([b, a]);
              h = new Helper(1000);
              h.go();
              return {
                done: h,
                context: ["a", "b", "c"]
              };
            }
          }, [
            function(x, y, z) {
              var h;
              result.push([x, y, z]);
              h = new Helper(1500);
              h.go();
              return h;
            }
          ]
        ]);
        return this.sequence.done(function() {
          expect(result).toEqual([[2, 1], ["a", "b", "c"]]);
          return done();
        });
      });
      it("while", function(done) {
        var result;
        result = [];
        this.sequence["while"](function() {
          return result.push("very first");
        }, function() {
          expect(result).toEqual(["very first", "func1", "func2", "func3"]);
          return done();
        });
        return this.sequence.start([
          {
            func: function() {
              return result.push("func1");
            }
          }, {
            func: function() {
              return result.push("func2");
            }
          }, [
            function() {
              return result.push("func3");
            }
          ]
        ]);
      });
      return it("progress", function(done) {
        var result, sequence;
        result = [];
        sequence = this.sequence;
        sequence.start([
          {
            func: function() {
              return result.push(sequence.progress());
            }
          }, {
            func: function() {
              return result.push(sequence.progress());
            }
          }, [
            function() {
              return result.push(sequence.progress());
            }
          ]
        ]);
        return sequence.done(function() {
          result.push(sequence.progress());
          expect(result).toEqual([0, 1 / 3, 2 / 3, 1]);
          return done();
        });
      });
    });
    return describe("Barrier", function() {
      beforeEach(function() {
        var Helper;
        this.barrier = new JSUtils.Barrier([], false);
        Helper = (function() {
          function Helper(delay) {
            if (delay == null) {
              delay = 1000;
            }
            this.cbs = [];
            this.isDone = false;
            this.delay = delay;
          }

          Helper.prototype.go = function(result) {
            return window.setTimeout((function(_this) {
              return function() {
                _this.isDone = true;
                if (result != null) {
                  result.push(_this.delay);
                }
                return _this._done();
              };
            })(this), this.deplay);
          };

          Helper.prototype._done = function() {
            var cb, j, len, ref, results;
            ref = this.cbs;
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
              cb = ref[j];
              results.push(cb());
            }
            return results;
          };

          Helper.prototype.done = function(cb) {
            this.cbs.push(cb);
            if (this.isDone) {
              this._done();
            }
            return this;
          };

          return Helper;

        })();
        return this.helperClass = Helper;
      });
      it("execute synchronous functions pseudo-concurrently", function(done) {
        this.barrier.start([
          {
            func: function() {
              return 2;
            }
          }, {
            func: function() {
              return 8;
            }
          }
        ]);
        return this.barrier.done(function(barrierResults) {
          expect(barrierResults).toEqual([2, 8]);
          return done();
        });
      });
      it("execute asynchronous functions pseudo-concurrently", function(done) {
        var Helper, result;
        result = [];
        Helper = this.helperClass;
        this.barrier.start([
          {
            func: function() {
              var h;
              h = new Helper(3000);
              h.go(result);
              return h;
            }
          }, {
            func: function() {
              var h;
              h = new Helper(1000);
              h.go(result);
              return h;
            }
          }
        ]);
        return this.barrier.done(function(barrierResults) {
          var res;
          expect(result).toEqual([3000, 1000]);
          expect((function() {
            var j, len, results;
            results = [];
            for (j = 0, len = barrierResults.length; j < len; j++) {
              res = barrierResults[j];
              results.push(res instanceof Helper);
            }
            return results;
          })()).toEqual([true, true]);
          return done();
        });
      });
      it("execute done-callbacks on completion and aftewards", function(done) {
        var result;
        result = [];
        this.barrier.start([
          {
            func: function() {
              return 2;
            }
          }, {
            func: function(a) {
              return a + 8;
            },
            scope: this
          }
        ]);
        return this.barrier.done((function(_this) {
          return function() {
            result.push("first");
            return _this.barrier.done(function() {
              result.push("second");
              expect(result).toEqual(["first", "second"]);
              return done();
            });
          };
        })(this));
      });
      it("set specific barrier's results (using sequences)", function(done) {
        var result;
        result = [];
        this.barrier.start([
          {
            func: function() {
              return new JSUtils.Sequence([
                {
                  func: function() {
                    var h;
                    h = new this.helperClass(1000);
                    h.go(result);
                    return {
                      done: h,
                      context: {
                        h: h
                      }
                    };
                  },
                  scope: this
                }, {
                  func: function(h) {
                    return {
                      a: 2,
                      delay: h.delay
                    };
                  }
                }
              ]);
            },
            scope: this
          }, {
            func: function() {
              return new JSUtils.Sequence([
                {
                  func: function() {
                    var h;
                    h = new this.helperClass(1001);
                    h.go(result);
                    return h;
                  },
                  scope: this
                }, {
                  func: function(h) {
                    return {
                      delay: h.delay
                    };
                  }
                }
              ]);
            },
            scope: this
          }
        ]);
        return this.barrier.done(function(barrierResults) {
          expect(barrierResults).toEqual([
            {
              a: 2,
              delay: 1000
            }, {
              delay: 1001
            }
          ]);
          return done();
        });
      });
      return it("Barrier.forArray", function(done) {
        var barrier;
        barrier = JSUtils.Barrier.forArray([1, 2, 3, 4], function(elem) {
          return elem * elem;
        });
        return barrier.done(function(barrierResults) {
          expect(barrierResults).toEqual([1, 4, 9, 16]);
          return done();
        });
      });
    });
  });

  describe("prototyping", function() {
    describe("nativesPrototyping", function() {
      describe("Math", function() {
        it("isNum", function() {
          expect(Math.isNum instanceof Function).toBe(true);
          expect(Math.isNum(0)).toBe(true);
          expect(Math.isNum(-2.34)).toBe(true);
          expect(Math.isNum("-2.34")).toBe(false);
          expect(Math.isNum(Infinity)).toBe(false);
          expect(Math.isNum(-Infinity)).toBe(false);
          return expect(Math.isNum(true)).toBe(false);
        });
        it("average", function() {
          expect(Math.average instanceof Function).toBe(true);
          expect(Math.average(1, 2)).toBe(1.5);
          expect(Math.average(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)).toBe(5.5);
          return expect(Math.average(-3, 2)).toBe(-0.5);
        });
        it("sign", function() {
          expect(Math.sign instanceof Function).toBe(true);
          expect(Math.sign(0)).toBe(0);
          expect(Math.sign(3)).toBe(1);
          expect(Math.sign(-3)).toBe(-1);
          expect(Math.sign("-3")).toBe(void 0);
          return expect(Math.sign(Infinity)).toBe(void 0);
        });
        return it("log10", function() {
          expect(Math.log10 instanceof Function).toBe(true);
          expect(Math.log10(1)).toBe(0);
          expect(Math.log10(10)).toBe(1);
          expect(Math.log10(100)).toBe(2);
          return expect(Math.log10(1e5)).toBe(5);
        });
      });
      describe("Function", function() {
        return it("clone", function() {
          var f1, f2, i, j, results;
          f1 = function(a) {
            return a + 2;
          };
          f2 = f1.clone();
          results = [];
          for (i = j = -100; j <= 100; i = j += 0.5) {
            results.push(expect(f1(i)).toBe(f2(i)));
          }
          return results;
        });
      });
      describe("Object", function() {
        it("except", function() {
          var a;
          a = {
            a: 10,
            b: 20,
            c: 30
          };
          return expect(Object.except(a, "b")).toEqual({
            a: 10,
            c: 30
          });
        });
        it("values", function() {
          var a;
          a = {
            a: 10,
            b: 20,
            c: 30
          };
          return expect(Object.values(a)).toEqual([10, 20, 30]);
        });
        return it("swapValues", function() {
          var a;
          a = {
            a: 10,
            b: 20,
            c: 30
          };
          return expect(Object.swapValues(a, "a", "c")).toEqual({
            a: 30,
            b: 20,
            c: 10
          });
        });
      });
      return describe("Element", function() {
        return it("remove", function() {
          var body;
          body = $(document.body);
          body.append("<div class='_test' />");
          document.querySelector("._test").remove();
          return expect(body.find("._test").length).toBe(0);
        });
      });
    });
    describe("stringPrototyping", function() {
      it("replaceMultiple", function() {
        var str;
        str = "me me me you me you bla";
        expect(str.replaceMultiple(["me", "I", "you", "you all"], 0)).toBe("I me me you all me you bla");
        expect(str.replaceMultiple(["me", "I", "you", "you all"], "tuples")).toBe("I me me you all me you bla");
        expect(str.replaceMultiple(["me", "you", "him"], 1)).toBe("him me me him me you bla");
        expect(str.replaceMultiple(["me", "you", "him"], "diffByOne")).toBe("him me me him me you bla");
        expect(str.replaceMultiple([
          "me", function(index) {
            return "" + (index + 1);
          }
        ], 2)).toBe("1 2 3 you 4 you bla");
        return expect(str.replaceMultiple([
          "me", function(index) {
            return "" + (index + 1);
          }
        ], "oneByDiff")).toBe("1 2 3 you 4 you bla");
      });
      it("firstToUpper", function() {
        return expect("manylittleletters".firstToUpper()).toBe("Manylittleletters");
      });
      it("firstToLower", function() {
        return expect("MANYBIGLETTERS".firstToLower()).toBe("mANYBIGLETTERS");
      });
      it("capitalize", function() {
        return expect("hello world, this is me".capitalize()).toBe("Hello World, This Is Me");
      });
      it("camelToKebab", function() {
        return expect("MyAwesomeClass".camelToKebab()).toBe("my-awesome-class");
      });
      it("snakeToCamel", function() {
        return expect("my_awesome_function".snakeToCamel()).toBe("myAwesomeFunction");
      });
      it("camelToSnake", function() {
        return expect("myAwesomeFunction".camelToSnake()).toBe("my_awesome_function");
      });
      it("lower & upper", function() {
        expect(String.prototype.upper).toBe(String.prototype.toUpperCase);
        return expect(String.prototype.lower).toBe(String.prototype.toLowerCase);
      });
      it("isNumeric", function() {
        expect("234".isNumeric()).toBe(true);
        expect("+234".isNumeric()).toBe(true);
        expect("-234.567".isNumeric()).toBe(true);
        return expect("some string".isNumeric()).toBe(false);
      });
      it("endsWith", function() {
        expect("myAwesomeFunction".endsWith("Function")).toBe(true);
        return expect("myAwesomeFunction".endsWith("Wunction")).toBe(false);
      });
      it("times", function() {
        expect("word ".times(5)).toBe("word word word word word ");
        return expect("word ".times(1)).toBe("word ");
      });
      return it("encodeHTMLEntities", function() {
        return expect("ü".encodeHTMLEntities()).toBe("&#252;");
      });
    });
    describe("arrayPrototyping", function() {
      it("unique", function() {
        return expect([1, 2, 2, 3, 1, 3, 4, 3, 1, 4, 3, 2].unique()).toEqual([1, 2, 3, 4]);
      });
      it("uniqueBy", function() {
        var i, objs;
        objs = (function() {
          var j, results;
          results = [];
          for (i = j = 0; j <= 10; i = ++j) {
            results.push({
              a: {
                x: [i % 3, i % 3]
              }
            });
          }
          return results;
        })();
        return expect(objs.uniqueBy(function(obj) {
          return obj.a.x;
        }, function(arr1, arr2) {
          return arr1[0] + arr1[1] === arr2[0] + arr2[1];
        })).toEqual([
          {
            a: {
              x: [0, 0]
            }
          }, {
            a: {
              x: [1, 1]
            }
          }, {
            a: {
              x: [2, 2]
            }
          }
        ]);
      });
      it("intersect & intersects", function() {
        expect([1, 2, 3, 4, 5].intersect([2, 5, 6, 7, 8])).toEqual([2, 5]);
        expect([1, 2, 3, 4, 5].intersect([6, 7, 8])).toEqual([]);
        expect([1, 2, 3, 4, 5].intersects([2, 5, 6, 7, 8])).toBe(true);
        return expect([1, 2, 3, 4, 5].intersects([6, 7, 8])).toBe(false);
      });
      it("groupBy", function() {
        var hash1, hash2, i, objs;
        objs = (function() {
          var j, results;
          results = [];
          for (i = j = 0; j < 10; i = ++j) {
            results.push({
              a: i % 3
            });
          }
          return results;
        })();
        hash1 = new JSUtils.Hash();
        hash1.put(0, [objs[0], objs[3], objs[6], objs[9]]);
        hash1.put(1, [objs[1], objs[4], objs[7]]);
        hash1.put(2, [objs[2], objs[5], objs[8]]);
        hash2 = objs.groupBy(function(o) {
          return o.a;
        });
        expect(hash1.keys).toEqual(hash2.keys);
        return expect(hash1.values).toEqual(hash2.values);
      });
      it("insert", function() {
        return expect([1, 2, 2, 3].insert(2, "a", "b")).toEqual([1, 2, "a", "b", 2, 3]);
      });
      it("remove", function() {
        expect([1, 2, 2, 3].remove(2, null, true)).toEqual([1, 3]);
        expect([1, 2, 2, 3].remove(2)).toEqual([1, 2, 3]);
        return expect([1, 2, 2, 3].remove(2, null, false)).toEqual([1, 2, 3]);
      });
      it("removeAt", function() {
        return expect([1, 2, 2, 3].removeAt(0)).toEqual([2, 2, 3]);
      });
      it("moveElem", function() {
        return expect([1, 2, 2, 3].moveElem(0, 3)).toEqual([2, 2, 3, 1]);
      });
      it("flatten", function() {
        return expect([[1, 2], [2, 3]].flatten(0)).toEqual([1, 2, 2, 3]);
      });
      it("cloneDeep", function() {
        var arr;
        arr = [1, [2, 2], 3];
        expect(arr.cloneDeep()).toEqual(arr);
        return expect(arr.cloneDeep() === arr).toBe(false);
      });
      it("except & without", function() {
        expect([1, 2, 2, 3].except(2, 3)).toEqual([1]);
        return expect([1, 2, 2, 3].without(2, 3)).toEqual([1]);
      });
      it("find", function() {
        return expect([1, [2, [2, "a"]], 3].find(function(elem) {
          return elem[1] === "a";
        })).toEqual([2, "a"]);
      });
      it("binIndexOf", function() {
        return expect([1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10].binIndexOf(4)).toBe(4);
      });
      it("sortByProp", function() {
        var i, objs;
        objs = (function() {
          var j, results;
          results = [];
          for (i = j = 0; j < 6; i = ++j) {
            results.push({
              a: i % 3
            });
          }
          return results;
        })();
        expect(objs.sortByProp(function(o) {
          return o.a;
        })).toEqual([
          {
            a: 0
          }, {
            a: 0
          }, {
            a: 1
          }, {
            a: 1
          }, {
            a: 2
          }, {
            a: 2
          }
        ]);
        return expect(objs.sortByProp(function(o) {
          return o.a;
        }, "desc")).toEqual([
          {
            a: 2
          }, {
            a: 2
          }, {
            a: 1
          }, {
            a: 1
          }, {
            a: 0
          }, {
            a: 0
          }
        ]);
      });
      it("getMax", function() {
        var i, objs;
        objs = (function() {
          var j, results;
          results = [];
          for (i = j = 0; j < 6; i = ++j) {
            results.push({
              a: i % 3
            });
          }
          return results;
        })();
        return expect(objs.getMax(function(o) {
          return o.a;
        })).toEqual([
          {
            a: 2
          }, {
            a: 2
          }
        ]);
      });
      it("getMin", function() {
        var i, objs;
        objs = (function() {
          var j, results;
          results = [];
          for (i = j = 0; j < 6; i = ++j) {
            results.push({
              a: i % 3
            });
          }
          return results;
        })();
        return expect(objs.getMin(function(o) {
          return o.a;
        })).toEqual([
          {
            a: 0
          }, {
            a: 0
          }
        ]);
      });
      it("reverseCopy", function() {
        var arr;
        arr = [1, 2, 1, 3];
        expect(arr.reverseCopy()).toEqual([3, 1, 2, 1]);
        return expect(arr.reverseCopy() === arr).toBe(false);
      });
      it("sample", function() {
        var arr;
        arr = [1, 2, 1, 3];
        return expect(arr.sample(2).length).toBe(2);
      });
      xit("shuffle", function() {});
      it("swap", function() {
        return expect([1, 2, 2, 3].swap(1, 3)).toEqual([1, 3, 2, 2]);
      });
      it("times", function() {
        return expect([1, 2, 2, 3].times(3)).toEqual([1, 2, 2, 3, 1, 2, 2, 3, 1, 2, 2, 3]);
      });
      it("and", function() {
        return expect([1, 2, 2, 3].and(0)).toEqual([1, 2, 2, 3, 0]);
      });
      it("merge", function() {
        return expect([1, 2, 2, 3].merge([0, 8, 9])).toEqual([1, 2, 2, 3, 0, 8, 9]);
      });
      it("noNulls", function() {
        return expect([1, false, 2, 0, null, 2, null, void 0, 3].noNulls()).toEqual([1, false, 2, 0, 2, 3]);
      });
      it("getLast", function() {
        expect([1, 2, 2, 3].getLast()).toEqual([3]);
        return expect([1, 2, 2, 3].getLast(2)).toEqual([2, 3]);
      });
      it("average", function() {
        return expect([1, 2, 2, 3].average).toBe(2);
      });
      it("last", function() {
        return expect([1, 2, 2, 3].last).toBe(3);
      });
      it("sum", function() {
        return expect([1, 2, 2, 3].sum).toBe(8);
      });
      it("first", function() {
        return expect([1, 2, 2, 3].first).toBe(1);
      });
      it("second", function() {
        return expect([1, 2, 2, 3].second).toBe(2);
      });
      it("third", function() {
        return expect([1, 2, 2, 3].third).toBe(2);
      });
      it("fourth", function() {
        return expect([1, 2, 2, 3].fourth).toBe(3);
      });
      return it("aliases: prepend, append, clone (without is tested in 'expect')", function() {
        var arr;
        arr = [1, 2, 2, 3];
        expect(arr.prepend(42)).toBe(5);
        expect(arr).toEqual([42, 1, 2, 2, 3]);
        expect(arr.append(43)).toBe(6);
        expect(arr).toEqual([42, 1, 2, 2, 3, 43]);
        expect(arr.clone()).toEqual(arr);
        return expect(arr.clone() === arr).toBe(false);
      });
    });
    return describe("jQueryPrototyping", function() {
      beforeEach(function() {
        this.body = $(document.body);
        this.div = $("<div class=\"test\" />");
        return this.body.append(this.div);
      });
      afterEach(function() {
        return this.div.remove();
      });
      it("content", function() {
        var div;
        div = $("<div class=\"content\">\n    this is what we want!\n    <div>text1</div>\n    <div>text2</div>\n    <div>text3</div>\n</div>");
        this.body.append(div);
        expect(div.content()).toBe("this is what we want!");
        div.content("hello world");
        expect(div.content().trim()).toBe("hello world");
        return div.remove();
      });
      it("toggleAttr", function() {
        this.div.attr("data-test", "haha");
        this.div.toggleAttr("data-test", "state1", "state2");
        expect(this.div.attr("data-test")).toBe("state1");
        this.div.toggleAttr("data-test");
        expect(this.div.attr("data-test")).toBe("state2");
        this.div.toggleAttr("data-test");
        return expect(this.div.attr("data-test")).toBe("state1");
      });
      it("toggleCss", function() {
        this.div.toggleCss("visibility", "hidden", "visible");
        expect(this.div.css("visibility")).toBe("hidden");
        this.div.toggleCss("visibility");
        expect(this.div.css("visibility")).toBe("visible");
        this.div.toggleCss("visibility");
        return expect(this.div.css("visibility")).toBe("hidden");
      });
      it("dimensions & outerDimensions", function() {
        this.div.css({
          width: 100,
          height: 100
        });
        expect(this.div.dimensions()).toEqual({
          x: 100,
          y: 100,
          width: 100,
          height: 100
        });
        expect(this.div.outerDimensions()).toEqual({
          x: 100,
          y: 100,
          width: 100,
          height: 100
        });
        this.div.css({
          padding: 20,
          margin: 20
        });
        expect(this.div.outerDimensions(false)).toEqual({
          x: 140,
          y: 140,
          width: 140,
          height: 140
        });
        expect(this.div.outerDimensions()).toEqual({
          x: 180,
          y: 180,
          width: 180,
          height: 180
        });
        return expect(this.div.outerDimensions(true)).toEqual({
          x: 180,
          y: 180,
          width: 180,
          height: 180
        });
      });
      it("showNow", function() {
        this.div.hide(0);
        expect(this.div.is(":visible")).toBe(false);
        this.div.showNow();
        return expect(this.div.is(":visible")).toBe(true);
      });
      it("hideNow", function() {
        expect(this.div.is(":visible")).toBe(true);
        this.div.hideNow();
        return expect(this.div.is(":visible")).toBe(false);
      });
      it("inDom", function() {
        expect(this.div.inDom()).toBe(true);
        this.div.detach();
        return expect(this.div.inDom()).toBe(false);
      });
      return it("wrapAll", function() {
        this.div.wrapAll("<div class='dom' />");
        expect(this.div.parent().hasClass("dom")).toBe(true);
        this.div.parent().detach();
        this.div.wrapAll("<div class='no-dom' />");
        return expect(this.div.parent().hasClass("no-dom")).toBe(true);
      });
    });
  });

}).call(this);
