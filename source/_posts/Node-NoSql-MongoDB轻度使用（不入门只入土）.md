---
title: '[Node][NoSQL]MongoDB 轻度使用（不入门只入土）'
date: 2019-09-29 12:31:56
updated: 2025-10-31 21:34:00
published: false
tags:
  - Node.js
  - MongoDB
  - NoSQL
  - Database
---

## 对比

因业务需要赶紧啃一手 MongoDB，大致过了一遍，对比主流关系型数据库，MongoDB 主要有这些不同：

* 列是动态的，更适合存储不定属性的对象（如某些不同业务的聚合统计）；
* 原生支持 JS 方法调用形式的写法，当然坏处是相对的，只能背 API，没办法用通用的 SQL 方法；
* 不支持事务、回滚，这也限定了 MongoDB 不适合强一致性的场景（基本只用来存插入的业务记录好了，更新都不要想了），没有 join，不适合业务复杂的场景；
* 贵（特指某里云），好在服务可以自建，不考虑高可用的情况下负担可以接受；
* 其他特性和不同我暂时考虑不到。

## 简单使用

怎么直接就入了土呢？我的业务主要用到一个 MapReduce，一个 find，一个 upsert。然后结合实际的使用，总结了一些坑点：

* 请用最新的包（目前是 3.3.2），不要用 2.x 的包。一个是内部环境的问题，这个后面会和 MapReduce 的坑一起讲；再一个是解析问题，connect 的时候新包会提示你打开使用新解析方式的选项，而且后续会废弃掉旧的解析方式，所以旧包应该是有这方面问题的。
* 可视化工具 Windows 下用的是 Robo 3T，一个坑点在于如果是通过 SSH 连跳板机到线上，本地生成 sshkey 时，需要指定 pem 的生成模式，否则是连不上的。（sshkey 有机会再讲）

具体应用的话，find 相当于 select；updateOne 带一个 upsert 的参数，这样就相当于 SQL 中的 insert on duplicate key，但是可以指定匹配键，而非 SQL 中的索引键；这些是比较常用且比较基础的用法。

## MapReduce

比较重要的就是这个 MapReduce 了，主要就是用作数据分析：map 的过程根据一定条件将原始数据映射到不同的集合（集合内只有一个元素时不走 reduce，因此设计返回值时，map 的结构应该尽量和 reduce 保持一致），reduce 过程将每个集合按一定方式处理成想要得到的分析维度。举一个简单的例子：

```javascript
db.collection('test').mapReduce(function(){
  emit(this.id % 10, {
    count: 1,
    avgScore: this.score
  })
}, function(key, values){
  const res = {
    count: 0,
    sum: 0,
    avgScore: 0
  }
  values.forEach(value => {
    res.count += value.count
    res.sum += value.score
    res.avgScore += value.score
  })
  res.avgScore /= values.length
  return res
}, {})

```

这一段，map 部分，将 test 表的所有元素按 id 模 10 的结果分组；reduce 部分，计算了每个组内成绩的平均值；我这里假设样本足够均匀，id 从 0 到 9 都有结尾的，那么最终的结果就是一个这样的数组：

```javascript
[{key: 0, value: { count: 1, avgScore: 20 }}, {key: 1, value: { count: 4, sum: 216, avgScore: 54 }}, ...{key: 9, value: { count: 5, sum: 195, avgScore: 39 }}] // length: 10

```

可以注意到，生成的结果是一个列表，其中每一个元素都是一个对象，都有 key 和 value 两个属性。key 是在 map 中指定的，emit 的第一个参数；value 则是 reduce 的返回值，如果 map 映射到的只有一个数据，那么 emit 的第二个参数直接作为结果对象的 value 属性（如例子中的第一个结果，只匹配到一个数据，因此不走 reduce，也就没有 sum 属性）。

这里注意到 map 函数内有一个 `this.id`，这个 id 是怎么 this 出来的？为什么在 map 函数里面 console.log 会报错？为什么不能传参数进去？

都是因为：map，reduce 这两个部分的函数，是作为参数传进 mapReduce 函数里面的，传入后会 toString 掉，在 MongoDB 内部环境执行。这也是为什么上一节说到，要使用高版本的 npm 包，因为 2.x 版本的包只支持到 ES5 的语法，如果一定要用老包的话，代码会写得很难看（然后被自己嫌弃（误，明明是被 CR 掉）。

如果我真的要传参数进去呢？确实是可以的。传入的参数可以是函数，也可以是字符串，所以……

```javascript
function map (options) {
  return function temp () {
    const options = JSON.parse('$options')
    switch (options) {
      // ...
    }
    emit(key, value)
  }.toString().replace('$options', JSON.stringify(options))
}
```

所以就直接传字符串好了，当然也还是有一些限制，没办法用全局变量，没办法传入构成循环指向的对象，还是没有console……

## 要问到底为什么入土

就是效率比较低，当然也有可能和我没有建好索引，或者 map、reduce 函数写得不好有关系。目前的话，大概 100k 左右的数据量就会崩掉。10k 左右的数据量，CPU 单核会跑满。

确实优点还是有，insert on duplicate key 不需要提前建立索引，不需要考虑字段类型，容量扩展较方便，MapReduce 甚至可以直接写 JS，虽然有些鸡肋，但是心智负担确实比写 SQL 的 group by 稍稍低一些……呸，我有这时间折腾这玩意，业务早写完了……

（完）
