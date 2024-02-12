---
title: hello
---
{% extends "templates/base.html.jinja" %} hallo {% block content %}

Ya, {{ documents.design.is_file }}

{% for doc_name, doc_info in documents.items() if doc_info.is_file %}
    Hello, {{ doc_name }}
    Goodbye, {{ doc_info.is_file }}
{% endfor %}

{% endblock %}