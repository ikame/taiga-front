# Copyright 2013 Andrey Antukh <niwi@niwi.be>

# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GmBacklogGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "burndown-chart")
        element.empty()
        element.append(chart)
        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            bezierCurve: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            datasetFillXAxis: 0
            datasetFillYAxis: 0


        data =
            labels : _.map(scope.projectStats.milestones, (ml) -> ml.name)
            datasets : [
                {
                    fillColor : "rgba(0,0,0,0)",
                    strokeColor : "rgba(0,0,0,1)",
                    pointColor : "rgba(0,0,0,0)",
                    pointStrokeColor : "rgba(0,0,0,0)",
                    data : _.map(scope.projectStats.milestones, (ml) -> 0)
                },
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : _.map(scope.projectStats.milestones, (ml) -> ml.optimal)
                },
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.filter(_.map(scope.projectStats.milestones, (ml) -> ml.evolution), (evolution) -> evolution?)
                },
                {
                    fillColor : "rgba(153,51,51,0.3)",
                    strokeColor : "rgba(153,51,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.map(scope.projectStats.milestones, (ml) -> -ml['team-increment'])
                },
                {
                    fillColor : "rgba(255,51,51,0.3)",
                    strokeColor : "rgba(255,51,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.map(scope.projectStats.milestones, (ml) -> -ml['team-increment']-ml['client-increment'])
                }
            ]

        new Chart(ctx).Line(data, options)

    scope.$watch 'projectStats', (value) ->
        if scope.projectStats
            redrawChart()

GmTaskboardGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = () ->
        width = element.width()
        height = width/6

        chart = $("<canvas />").attr("width", width).attr("height", height).attr("id", "dashboard-chart")
        element.empty()
        element.append(chart)
        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            bezierCurve: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            datasetFillXAxis: 0
            datasetFillYAxis: 0

        data =
            labels : _.map(scope.milestoneStats.days, (day) -> day.name)
            datasets : [
                {
                    fillColor : "rgba(120,120,120,0.2)",
                    strokeColor : "rgba(120,120,120,0.2)",
                    pointColor : "rgba(255,255,255,1)",
                    pointStrokeColor : "#ccc",
                    data : _.map(scope.milestoneStats.days, (day) -> day.optimal_points)
                },
                {
                    fillColor : "rgba(102,153,51,0.3)",
                    strokeColor : "rgba(102,153,51,1)",
                    pointColor : "rgba(255,255,255,1)",
                    data : _.map(scope.milestoneStats.days, (day) -> day.open_points)
                }
            ]

        new Chart(ctx).Line(data, options)

    scope.$watch 'milestoneStats', (value) ->
        if scope.milestoneStats
            redrawChart()

GmIssuesPieGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        element.height(width)
        data = _.map(_.values(dataToDraw), (d) -> { data: d.count, label: d.name})
        options =
            series:
                pie:
                    show: true
                    radius: 1
                    label:
                        show: true
                        radius: 3/4
                        formatter: (label, slice) ->
                            "<div class='pieLabelText'>#{label}<br/>#{slice.data[0][1]}</div>"
                        background:
                            opacity: 0.5
                            color: 'white'
            legend:
                show: false
            colors: _.map(_.values(dataToDraw), (d) -> d.color)


        plot = element.plot(data, options).data("plot")


    scope.$watch attrs.gmIssuesPieGraph, () ->
        value = scope.$eval(attrs.gmIssuesPieGraph)
        if value and scope.showGraphs
            redrawChart(value)
    scope.$watch 'showGraphs', () ->
        value = scope.$eval(attrs.gmIssuesPieGraph)
        if value and scope.showGraphs
            setTimeout(->
                redrawChart(value)
            , 200)

GmIssuesAccumulatedGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)


    redrawChart = (dataToDraw) ->
        vectorsSum = (vector1, vector2) ->
            result = []
            for x in [0..27]
                result[x] = vector1[x] + vector2[x]
            return result

        width = element.width()
        element.height(width / 2)

        days = _.map([27..0], (x) ->
            moment().subtract('days', x)
        )
        data = []
        for d in _.values(dataToDraw)
            if accumulated_data?
                accumulated_data = vectorsSum(accumulated_data, d.data)
            else
                accumulated_data = d.data

            data.unshift({
                label: d.name
                data: _.zip(days, accumulated_data)
            })
        options =
            legend:
                position: "nw"
            xaxis:
                tickSize: [1, "day"],
                min: moment().subtract('days', 27),
                max: moment(),
                mode: "time",
                daysNames: days,
                axisLabel: 'Day',
                axisLabelUseCanvas: true,
                axisLabelFontSizePixels: 12,
                axisLabelFontFamily: 'Verdana, Arial, Helvetica, Tahoma, sans-serif',
                axisLabelPadding: 5
            series:
                lines:
                    show: true
                    fill: true
                    fillColor: { colors: _.map(_.values(dataToDraw), (d) -> {'color':d.color}).reverse() }

            colors: _.map(_.values(dataToDraw), (d) -> d.color).reverse()


        plot = element.plot(data, options).data("plot")

    scope.$watch attrs.gmIssuesAccumulatedGraph, () ->
        value = scope.$eval(attrs.gmIssuesAccumulatedGraph)
        if value and scope.showGraphs
            redrawChart(_.values(value))
    scope.$watch 'showGraphs', () ->
        value = scope.$eval(attrs.gmIssuesAccumulatedGraph)
        if value and scope.showGraphs
            setTimeout(->
                redrawChart(_.values(value))
            , 200)

GmIssuesOpenClosedGraphDirective = () -> (scope, elm, attrs) ->
    element = angular.element(elm)

    redrawChart = (dataToDraw) ->
        width = element.width()
        height = width/2
        chart = $("<canvas />").attr("width", width).attr("height", height)

        element.empty()
        element.append(chart)

        ctx = chart.get(0).getContext("2d")

        options =
            animation: false
            scaleFontFamily : "'ColabThi'"
            scaleFontSize : 10
            scaleStepWidth: 1

        data = {}
        data.labels = _.map([27..0], (x) ->
            moment().subtract('days', x).date()
        )
        green = $.Color('green')
        red = $.Color('red')
        data.datasets = [
            {
                fillColor: green.alpha(0.5).toRgbaString()
                strokeColor: green.toRgbaString()
                data: dataToDraw['closed']
            },
            {
                fillColor: red.alpha(0.5).toRgbaString()
                strokeColor: red.toRgbaString()
                data: dataToDraw['open']
            }
        ]

        new Chart(ctx).Bar(data, options)

    scope.$watch attrs.gmIssuesOpenClosedGraph, () ->
        value = scope.$eval(attrs.gmIssuesOpenClosedGraph)
        if value and scope.showGraphs
            redrawChart(value)
    scope.$watch 'showGraphs', () ->
        value = scope.$eval(attrs.gmIssuesOpenClosedGraph)
        if value and scope.showGraphs
            setTimeout(->
                redrawChart(value)
            , 200)

module = angular.module("greenmine.directives.graphs", [])
module.directive("gmBacklogGraph", GmBacklogGraphDirective)
module.directive("gmTaskboardGraph", GmTaskboardGraphDirective)
module.directive("gmIssuesPieGraph", GmIssuesPieGraphDirective)
module.directive("gmIssuesAccumulatedGraph", GmIssuesAccumulatedGraphDirective)
module.directive("gmIssuesOpenClosedGraph", GmIssuesOpenClosedGraphDirective)
