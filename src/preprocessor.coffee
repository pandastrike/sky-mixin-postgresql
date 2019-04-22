# Panda Sky Mixin: PostgreSQL
# This mixin allocates the requested PostgreSQL cluster into your CloudFormation stack.
import {cat, isObject} from "panda-parchment"
import {offset, pickZone, pickWindow, keyLookup} from "./utils"

process = (SDK, config) ->

  # Start by extracting out the PostgreSQL Mixin configuration:
  {env, tags=[]} = config
  c = config.aws.environments[env].mixins.postgresql
  c = if isObject c then c else {}
  c.tags = cat (c.tags || []), tags

  # This mixin only works with a VPC
  if !config.aws.vpc
    throw new Error "The PostgreSQL mixin can only be used in environments featuring a VPC."

  # Expand the cluster configuration with defaults.
  {cluster, tags} = c
  if !cluster.name
    c.cluster.name = config.environmentVariables.fullName

  if !cluster.type
    c.cluster.type = "db.r4.large"

  if !cluster.replicaCount?
    cluster.replicaCount = 0

  if !cluster.backupTTL
    cluster.backupTTL = 1

  if !cluster.backupWindow
    cluster.backupWindow = "06:00-07:00" # 11pm - 12am PST

  if !cluster.maintenanceWindow
    cluster.maintenanceWindow = "Wed:07:00-Wed:08:00"  # 12am - 1am PST
  cluster.maintenanceWindow2 = offset 1, cluster.maintenanceWindow

  if !cluster.allowMajorUpgrades?
    cluster.allowMajorUpgrades = false

  if !cluster.allowMinorUpgrades?
    cluster.allowMinorUpgrades = true

  if cluster.kmsKey
    cluster.kmsKey = await keyLookup SDK, cluster.kmsKey

  # Create the read replica configuration based on the requested number of replicas.
  replicas = []
  for i in [0...cluster.replicaCount]
    replicas.push
      availabilityZone: pickZone i
      maintenanceWindow: pickWindow i, cluster


  {tags, cluster, replicas}

export default process
