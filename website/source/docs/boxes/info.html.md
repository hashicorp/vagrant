---
layout: "docs"
page_title: "Box Info Format"
sidebar_current: "boxes-info"
description: |-
  A box can provide additional information to the user by supplying an info.json
  file within the box.
---

# Additional Box Information

When creating a Vagrant box, you can supply additional information that might be
relevant to the user when running `vagrant box list -i`. For example, you could
package your box to include information about the author of the box and a
website for users to learn more:

```
brian@localghost % vagrant box list -i
hashicorp/precise64     (virtualbox, 1.0.0)
  - author: brian
  - homepage: https://www.vagrantup.com
```

## Box Info

To accomplish this, you simply need to include a file named `info.json` when
creating a [base box](/docs/boxes/base.html) which is a JSON document containing
any and all relevant information that will be displayed to the user when the
`-i` option is used with `vagrant box list`.

```json
{
 "author": "brian",
 "homepage": "https://example.com"
}
```

There are no special keys or values in `info.json`, and Vagrant will print each
key and value on its own line.

The [Box File Format](/docs/boxes/format.html) provides more information about what
else goes into a Vagrant box.
