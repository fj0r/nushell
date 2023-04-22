register /usr/local/bin/nu_plugin_gstat  {
  "sig": {
    "name": "gstat",
    "usage": "Get the git status of a repo",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [
      {
        "name": "path",
        "desc": "path to repo",
        "shape": "Filepath",
        "var_id": null,
        "default_value": null
      }
    ],
    "rest_positional": null,
    "vectorizes_over_list": false,
    "named": [
      {
        "long": "help",
        "short": "h",
        "arg": null,
        "required": false,
        "desc": "Display the help message for this command",
        "var_id": null,
        "default_value": null
      }
    ],
    "input_type": "Any",
    "output_type": "Any",
    "input_output_types": [],
    "allow_variants_without_examples": false,
    "is_filter": false,
    "creates_scope": false,
    "allows_unknown_args": false,
    "category": {
      "Custom": "prompt"
    }
  },
  "examples": []
}

