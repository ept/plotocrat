(->
  $ ->

    chart = (datasets) ->
      kdes = datasets.map (data) -> science.stats.distribution.kde().sample(data).resolution(200)

      feelsLogarithmic = kdes.some((kde) -> kde.feelsLogarithmic)

      if feelsLogarithmic
      # remove all 0s as they play merry havoc with log scales.
        datasets = datasets.map (data) ->
          data.filter (d) -> d != 0

        kdes = datasets.map (data) -> science.stats.distribution.kde().sample(data).resolution(200)

        x = d3.scale.log()
      else
        x = d3.scale.linear()

      kdes.forEach (kde) -> kde.scale x.copy()
      max = d3.max(datasets.map (data) -> d3.max(data))
      min = d3.min(datasets.map (data) -> d3.min(data))

      x.clamp(true).domain([min, max]).range([40, width]).nice()

      y = d3.scale.linear().domain([1, 0]).range([40, height])

      yk = d3.scale.linear().domain([d3.max(kdes, (kde) -> kde.max()), 0]).range([40, height])

      label = d3.select("#cdf").append("div").html(title + " = <br/>cumulative =<br/>density =")
      title = d3.select('#cdf').attr('data-title')

      viz = d3.svg.basicPlot(d3.select("#cdf"), width, height, x, y)

      viz.selectAll("path.pdf").data(kdes).enter()
        .append("svg:path")
        .attr
          class: (d, i) -> "pdf pdf" + i
          d: (kde) -> d3.svg.line().x((d) -> x d[0]).y((d) -> yk d[1])(kde.pdf())

      viz.selectAll("path.cdf").data(kdes).enter()
        .append("svg:path")
        .attr
          class: "cdf"
          d: (kde) -> d3.svg.line().x((d) -> x d[0]).y((d) -> y d[1])(kde.cdf())


      viz.selectAll("circle.mode").data(kdes).enter()
        .append("svg:circle")
        .attr
          class: "mode"
          r: 4
          cx: (kde) -> x kde.mode()
          cy: (kde) -> yk kde(kde.mode())

      viz.selectAll("circle.expectation").data(kdes).enter()
        .append("svg:circle")
        .attr
          class: "expectation"
          r: 4
          cx: (kde) -> x kde.expectation()
          cy: (kde) -> yk kde(kde.expectation()) / 2

      viz.selectAll("g.circles").data(kdes).enter()
        .append("svg:g")
        .attr
          class: "circles"
        .selectAll("circle.percentile")
        .data((kde) -> kde.qf()).enter()
        .append("svg:circle")
        .attr
          class: "percentile"
          r: 4
          cx: (d) -> x d[0]
          cy: (d) -> y d[1]

      viz.selectAll("text.xtitle").data([0]).enter()
        .append("svg:text").attr("class", "xtitle")
        .text(title)
        .attr
          x: 40 + width / 2
          y: height + 60

      viz.onHorizontalInteraction (value) ->
        if value == false
          viz.selectAll(".fugi").style display: 'none'
          return
        else
          viz.selectAll(".fugi").style display: 'block'

        line = viz.selectAll("line.fugi").data([value])
        line.enter().append("svg:line").attr
          class: "fugi"
          y1: y(0)
          y2: y(1)
        line.attr
          x1: x
          x2: x

        value_s = title + " = " + value.toPrecision(4)
        value_s = value_s.replace(/\((.*)\) *= ([0-9e\-\+\.]*)$/, (m, u, v) -> "= " + v + " " + u)
        label.html(value_s)

        kdes.forEach (kde, i) ->
          cumulative = kde.inverseQuantile(value)
          density = kde(value)
          cd = [yk(density), y(cumulative)]

          circles = viz.selectAll("circle.fugi" + i).data(cd)
          circles.enter().append("svg:circle").attr
            r: 5
            class: 'fugi fugi' + i
          circles.attr
            cx: x(value)
            cy: (d) -> d


          cumulative_s = "cumulative = " + (cumulative * 100).toPrecision(4) + "%"
          absolute_s = "density = " + density.toPrecision(3)

          label.html(label.html() + "<br/>" + [cumulative_s, absolute_s].join("<br/>"))

    height = 400
    width = 600

    if $('textarea#data').length
        suffixes = ['']
    else
        suffixes = [1, 2]

    datasets = suffixes.map (i) ->
      data = []
      $('textarea#data' + i).val().split("\n").forEach((x) ->
        return if x.match(/^(#|\s*$)/)
        n = Number(x)
        # TODO warn about unparseable lines?
        data.push(n) unless isNaN(n)
      )

      data.sort(d3.ascending)

    chart datasets

).call this
