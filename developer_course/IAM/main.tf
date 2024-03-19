
resource "aws_iam_user" "users" {
  for_each = toset(var.users)
  name = each.key
}


resource "aws_iam_group" "groups" {
  for_each = tomap(var.groups_and_users)
  name = each.key
}

resource "aws_iam_group_membership" "teams" {
  for_each = tomap(var.groups_and_users)
  name = "group-membership ${each.key}"
  users = [for k in each.value : aws_iam_user.users[k].name]
  group = aws_iam_group.groups[each.key].name
}

