fs = require "fs"
util = require "util"
cli = require "cli"
path_parser = require "./path_parser"
poly2tri = require("./poly2tri").poly2tri

exports.run = ->
  # --help
  package_json = require "../package.json"
  cli.setApp package_json.name, package_json.version
  cli.setUsage "svg_triangulator.js [OPTIONS] filename"

  # --version
  cli.enable "version"

  # parse options even though we don't have any so that the help screen shows up
  cli.parse
    output: ["o", "Output points as raw arrays or {x:n, y:n}", ["raw", "objects"], "objects"]
    pathpoints: ["p", "include the path points extracted from the svg"]

  cli.main (args, options) ->
    return cli.error("Specify a filename") if  args.length == 0

    # make sure the file exists and is ok to use
    fs.stat args[0], (err) ->
      return cli.error(err) if err?

      # create a stream and get the absolute points for each path
      stream = fs.createReadStream args[0]
      path_parser.parse stream, (err, path_points) ->
        return cli.error(err) if err?
        paths = []

        # triangulate the points for each path
        for path in path_points
          contour = (new poly2tri.Point(coord.x, coord.y) for coord in path)
          swctx = new poly2tri.SweepContext contour
          poly2tri.sweep.Triangulate swctx

          # segment is what we show to the user
          segment =
            count: swctx.GetTriangles().length * 3
            points: []

          # add the svg path points to the coord if it was requested
          segment.pathpoints = path if options.pathpoints

          # iterate through all of the triangle pairs and add them to the output
          for val, id in swctx.GetTriangles()
            trPoints = [val.GetPoint(0), val.GetPoint(1), val.GetPoint(2)]
            segment.points = segment.points.concat [
              {x: trPoints[0].x, y: trPoints[0].y}
              {x: trPoints[1].x, y: trPoints[1].y}
              {x: trPoints[2].x, y: trPoints[2].y}
            ]

          paths.push formatter(segment, options)

        console.log util.inspect(paths, false, null)


# format the output of the points
formatter = (segment, options) ->
  if options.output == "raw"
    points = []
    points = points.concat([coord.x, coord.y]) for coord in segment.points
    segment.points = points.join ","

    if options.pathpoints
      pathpoints = []
      pathpoints = pathpoints.concat([coord.x, coord.y]) for coord in segment.pathpoints
      segment.pathpoints = pathpoints.join ","

    return segment

  else if options.output == "objects"
    return segment

  else
    return cli.error "Unknown value supplied for output"
