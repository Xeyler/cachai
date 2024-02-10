---
title: It's a static site generator, cachai?!
---
{% extends "templates/base.html.jinja" %}
{% block content %}

# {{ title }}

## Rendering

Cachai renders all markdown files from the `documents` directory into html:

1. If a markdown file has yaml front matter delimited by three hyphens, it is split into two files.

2. The markdown file is converted into html using cmark.

3. The resulting html file is rendered using jinja2. If the markdown source contained front matter, it is passed to jinja as the context.

### Context

To allow documents to refer to one another, the `documents` variable refers to all markdown files in the `documents` directory. 

Namespaces reflect directory structure and the `.md` extension is excluded. For example, `documents/foo/bar/baz.md` is referred to as `documents.foo.bar.baz`.

Each document is guaranteed to have the attribute, `url`, which refers to the rendered document.

All variables defined in the markdown front matter are available in this context. If `documents/design.md` defined a variable called `title` in its front matter, it would be made available as `documents.design.title`.

{% endblock %}