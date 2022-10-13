poll "closed_issue_locker" "locker" {
  schedule             = "0 50 1 * * *"
  closed_for           = "720h" # 30 days
  max_issues           = 500
  sleep_between_issues = "5s"

  no_comment_if_no_activity_for = "4320h" # 180 days

  message = <<-EOF
    I'm going to lock this issue because it has been closed for _30 days_ ⏳. This helps our maintainers find and focus on the active issues.

    If you have found a problem that seems similar to this, please open a new issue and complete the issue template so we can capture all the details necessary to investigate further.
  EOF
}
