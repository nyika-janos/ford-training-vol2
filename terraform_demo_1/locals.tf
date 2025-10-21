locals {
  # create dataset compatible name in two step
  name_lower           = lower(var.user_name)
  name_with_underscore = replace(local.name_lower, " ", "_")

  # create bucket and account name compatible name in one step
  name_with_hyphen = replace(lower(var.user_name), " ", "-")
}
