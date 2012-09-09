XmlStream = require "xml-stream"

exports.parse = (stream, cb) ->
  xml = new XmlStream stream
  xml.collect "path"
  paths = []

  xml.on "endElement: path", (path) ->
    pos = {x: 0, y: 0}
    parsed = path.$.d.match /[MmLlVvHhZz](?:\d|\W|,)*/gm

    absolute_path = []
    for op in parsed
      coords = parse_coords op
      path_is_closed = false # if the path isn't close it will be ignored

      # follow through with the SVG path operation
      # because we are triangulating we assume one M command and a Z command
      switch op[0]
        when "M", "L" # absolute
          pos = coords
          absolute_path.push(coords) if !exists_in_path(absolute_path, coords)

        when "m", "l" # relative
          pos.x += coords.x
          pos.y += coords.y
          absolute_path.push(coords) if !exists_in_path(absolute_path, coords)

        when "V", "v", "H", "h"
          console.log "TODO: vertical and horizontal path operations"

        when "Z", "z" # Close the path
          path_is_closed = true

    paths.push absolute_path if path_is_closed

  xml.on "end", ->
    cb null, paths


parse_coords = (op) ->
  coords = op.slice(1).split ","
  {x: parseFloat(coords[0]), y: parseFloat(coords[1])}


exists_in_path = (path, coord) ->
  for item in path
    return true if coord.x == item.x && coord.y == item.y

  return false