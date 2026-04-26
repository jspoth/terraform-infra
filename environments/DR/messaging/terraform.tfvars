region      = "us-west-2"
name_prefix = "dr"

# Add a new entry here to provision a queue + DLQ pair.
# name_prefix + key = queue name (e.g. "dr-app-events")
# No changes needed in modules/ or permissions/ when adding queues.
queues = {
  app-events = {}
}

tags = {
  env = "dr"
}
