#Lar Runtime

A javascript runtime written in zig that uses javascriptcore as the javascript engine.


## Api List

### Console Api Status

```typescript
console.log(...) // ready
console.assert(value[, ...message]) // ready
console.clear() // ready
console.count([label]) // ready
console.countReset([label]) // soon
console.debug(data[, ...args]) // soon
console.dir(obj[, options]) // soon
console.dirxml(...data) // soon
console.error([data][, ...args]) // soon
console.group([...label]) // soon
console.groupCollapsed() // soon
console.groupEnd() // soon
console.info([data][, ...args]) // soon
console.log([data][, ...args]) // soon
console.table(tabularData[, properties]) // soon
console.time([label]) // soon
console.timeEnd([label]) // soon
console.timeLog([label][, ...data]) // soon
console.trace([message][, ...args]) // soon
console.warn([data][, ...args]) // soon
```

### FS Api Status

``` typescript
lar.writeFile([path], [data]) // ready
lar.readFile([path]) // ready
lar.existsFile([path]) // ready
lar.removeFile([path]) // ready
```

### Learning Project

This is a personal learning project focused on understanding how JavaScript runtimes written in C, Go, or Zig are created. As such, it's not recommended to use the Lar Runtime for production purposes.

### Code Usage

If you decide to use any code from this runtime, I kindly request that you mention Lar Runtime in your project documentation, as well as in your code comments.
