project = "foo"

app "bar" {
    path = "./bar"

    labels = {
        "pwd": path.pwd,
        "project": path.project,
        "app": path.app,
    }
}
