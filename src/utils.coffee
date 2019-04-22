import "datejs"
import {even} from "fairmont"
import Sundog from "sundog"

keyLookup = (SDK, name) ->
  {AWS:{KMS}} = await Sundog SDK
  {get} = KMS()
  try
    {Arn} = await get "alias/#{name}"
    Arn
  catch e
    throw new Error "The KMS key \"#{name}\" is not found."


update = (shift, time) ->
  [day, hour, minute] = time.split ":"
  hour = parseInt hour, 10
  minute = parseInt minute, 10

  Date.parse("next #{day}").set({hour, minute})
  .add(shift).hour()
  .toString("ddd:HH:mm")

offset = (shift, range) ->
  [start, end] = range.split "-"
  "#{update shift, start}-#{update shift, end}"

# We have 2 availability zones.  Stagger the placement and configurations of the cluster's read replicas between them.
pickZone = (index) ->
  zone = if even index then 1 else 0
  """
  [#{zone}, "Fn::Split": [",", {"Ref": AvailabilityZones}]]
  """

pickWindow = (index, {maintenanceWindow, maintenanceWindow2}) ->
  if even index then maintenanceWindow2 else maintenanceWindow

export {offset, pickZone, pickWindow, keyLookup}
