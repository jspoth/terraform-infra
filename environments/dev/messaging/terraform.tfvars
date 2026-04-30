region      = "us-east-2"
name_prefix = "dev"
# Add a new entry here to provision a queue + DLQ pair.
# name_prefix + key = queue name (e.g. "dev-app-events")
# No changes needed in modules/ or permissions/ when adding queues.
queues = {
  app-events = {}
}

tags = {
  env = "dev"
}
