register /usr/local/bin/nu_plugin_custom_values  {
  "sig": {
    "name": "custom-value generate",
    "usage": "PluginSignature for a plugin that generates a custom value",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "category": "Experimental"
  },
  "examples": []
}

register /usr/local/bin/nu_plugin_custom_values  {
  "sig": {
    "name": "custom-value generate2",
    "usage": "PluginSignature for a plugin that generates a different custom value",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "category": "Experimental"
  },
  "examples": []
}

register /usr/local/bin/nu_plugin_custom_values  {
  "sig": {
    "name": "custom-value update",
    "usage": "PluginSignature for a plugin that updates a custom value",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "category": "Experimental"
  },
  "examples": []
}

register /usr/local/bin/nu_plugin_formats  {
  "sig": {
    "name": "from eml",
    "usage": "Parse text as .eml and create record.",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
      },
      {
        "long": "preview-body",
        "short": "b",
        "arg": "Int",
        "required": false,
        "desc": "How many bytes of the body to preview",
        "var_id": null,
        "default_value": null
      }
    ],
    "input_type": "Any",
    "output_type": "Any",
    "input_output_types": [
      [
        "String",
        {
          "Record": []
        }
      ]
    ],
    "allow_variants_without_examples": false,
    "is_filter": false,
    "creates_scope": false,
    "allows_unknown_args": false,
    "category": "Formats"
  },
  "examples": [
    {
      "example": "'From: test@email.com\nSubject: Welcome\nTo: someone@somewhere.com\nTest' | from eml",
      "description": "Convert eml structured data into record",
      "result": {
        "Record": {
          "cols": [
            "Subject",
            "From",
            "To",
            "Body"
          ],
          "vals": [
            {
              "String": {
                "val": "Welcome",
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            },
            {
              "Record": {
                "cols": [
                  "Name",
                  "Address"
                ],
                "vals": [
                  {
                    "Nothing": {
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "String": {
                      "val": "test@email.com",
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            },
            {
              "Record": {
                "cols": [
                  "Name",
                  "Address"
                ],
                "vals": [
                  {
                    "Nothing": {
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "String": {
                      "val": "someone@somewhere.com",
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            },
            {
              "String": {
                "val": "Test",
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            }
          ],
          "span": {
            "start": 0,
            "end": 0
          }
        }
      }
    },
    {
      "example": "'From: test@email.com\nSubject: Welcome\nTo: someone@somewhere.com\nTest' | from eml -b 1",
      "description": "Convert eml structured data into record",
      "result": {
        "Record": {
          "cols": [
            "Subject",
            "From",
            "To",
            "Body"
          ],
          "vals": [
            {
              "String": {
                "val": "Welcome",
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            },
            {
              "Record": {
                "cols": [
                  "Name",
                  "Address"
                ],
                "vals": [
                  {
                    "Nothing": {
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "String": {
                      "val": "test@email.com",
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            },
            {
              "Record": {
                "cols": [
                  "Name",
                  "Address"
                ],
                "vals": [
                  {
                    "Nothing": {
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "String": {
                      "val": "someone@somewhere.com",
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            },
            {
              "String": {
                "val": "T",
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            }
          ],
          "span": {
            "start": 0,
            "end": 0
          }
        }
      }
    }
  ]
}

register /usr/local/bin/nu_plugin_formats  {
  "sig": {
    "name": "from ics",
    "usage": "Parse text as .ics and create table.",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "input_output_types": [
      [
        "String",
        {
          "Table": []
        }
      ]
    ],
    "allow_variants_without_examples": false,
    "is_filter": false,
    "creates_scope": false,
    "allows_unknown_args": false,
    "category": "Formats"
  },
  "examples": [
    {
      "example": "'BEGIN:VCALENDAR\n            END:VCALENDAR' | from ics",
      "description": "Converts ics formatted string to table",
      "result": {
        "List": {
          "vals": [
            {
              "Record": {
                "cols": [
                  "properties",
                  "events",
                  "alarms",
                  "to-Dos",
                  "journals",
                  "free-busys",
                  "timezones"
                ],
                "vals": [
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "List": {
                      "vals": [],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            }
          ],
          "span": {
            "start": 0,
            "end": 0
          }
        }
      }
    }
  ]
}

register /usr/local/bin/nu_plugin_formats  {
  "sig": {
    "name": "from ini",
    "usage": "Parse text as .ini and create table.",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "input_output_types": [
      [
        "String",
        {
          "Record": []
        }
      ]
    ],
    "allow_variants_without_examples": false,
    "is_filter": false,
    "creates_scope": false,
    "allows_unknown_args": false,
    "category": "Formats"
  },
  "examples": [
    {
      "example": "'[foo]\na=1\nb=2' | from ini",
      "description": "Converts ini formatted string to record",
      "result": {
        "Record": {
          "cols": [
            "foo"
          ],
          "vals": [
            {
              "Record": {
                "cols": [
                  "a",
                  "b"
                ],
                "vals": [
                  {
                    "String": {
                      "val": "1",
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  },
                  {
                    "String": {
                      "val": "2",
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            }
          ],
          "span": {
            "start": 0,
            "end": 0
          }
        }
      }
    }
  ]
}

register /usr/local/bin/nu_plugin_formats  {
  "sig": {
    "name": "from vcf",
    "usage": "Parse text as .vcf and create table.",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "input_output_types": [
      [
        "String",
        {
          "Table": []
        }
      ]
    ],
    "allow_variants_without_examples": false,
    "is_filter": false,
    "creates_scope": false,
    "allows_unknown_args": false,
    "category": "Formats"
  },
  "examples": [
    {
      "example": "'BEGIN:VCARD\nN:Foo\nFN:Bar\nEMAIL:foo@bar.com\nEND:VCARD' | from vcf",
      "description": "Converts ics formatted string to table",
      "result": {
        "List": {
          "vals": [
            {
              "Record": {
                "cols": [
                  "properties"
                ],
                "vals": [
                  {
                    "List": {
                      "vals": [
                        {
                          "Record": {
                            "cols": [
                              "name",
                              "value",
                              "params"
                            ],
                            "vals": [
                              {
                                "String": {
                                  "val": "N",
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              },
                              {
                                "String": {
                                  "val": "Foo",
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              },
                              {
                                "Nothing": {
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              }
                            ],
                            "span": {
                              "start": 0,
                              "end": 0
                            }
                          }
                        },
                        {
                          "Record": {
                            "cols": [
                              "name",
                              "value",
                              "params"
                            ],
                            "vals": [
                              {
                                "String": {
                                  "val": "FN",
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              },
                              {
                                "String": {
                                  "val": "Bar",
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              },
                              {
                                "Nothing": {
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              }
                            ],
                            "span": {
                              "start": 0,
                              "end": 0
                            }
                          }
                        },
                        {
                          "Record": {
                            "cols": [
                              "name",
                              "value",
                              "params"
                            ],
                            "vals": [
                              {
                                "String": {
                                  "val": "EMAIL",
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              },
                              {
                                "String": {
                                  "val": "foo@bar.com",
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              },
                              {
                                "Nothing": {
                                  "span": {
                                    "start": 0,
                                    "end": 0
                                  }
                                }
                              }
                            ],
                            "span": {
                              "start": 0,
                              "end": 0
                            }
                          }
                        }
                      ],
                      "span": {
                        "start": 0,
                        "end": 0
                      }
                    }
                  }
                ],
                "span": {
                  "start": 0,
                  "end": 0
                }
              }
            }
          ],
          "span": {
            "start": 0,
            "end": 0
          }
        }
      }
    }
  ]
}

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

register /usr/local/bin/nu_plugin_inc  {
  "sig": {
    "name": "inc",
    "usage": "Increment a value or version. Optionally use the column of a table.",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [
      {
        "name": "cell_path",
        "desc": "cell path to update",
        "shape": "CellPath",
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
      },
      {
        "long": "major",
        "short": "M",
        "arg": null,
        "required": false,
        "desc": "increment the major version (eg 1.2.1 -> 2.0.0)",
        "var_id": null,
        "default_value": null
      },
      {
        "long": "minor",
        "short": "m",
        "arg": null,
        "required": false,
        "desc": "increment the minor version (eg 1.2.1 -> 1.3.0)",
        "var_id": null,
        "default_value": null
      },
      {
        "long": "patch",
        "short": "p",
        "arg": null,
        "required": false,
        "desc": "increment the patch version (eg 1.2.1 -> 1.2.2)",
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
    "category": "Default"
  },
  "examples": []
}

register /usr/local/bin/nu_plugin_query  {
  "sig": {
    "name": "query",
    "usage": "Show all the query commands",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
    "category": "Filters"
  },
  "examples": []
}

register /usr/local/bin/nu_plugin_query  {
  "sig": {
    "name": "query json",
    "usage": "execute json query on json file (open --raw <file> | query json 'query string')",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [
      {
        "name": "query",
        "desc": "json query",
        "shape": "String",
        "var_id": null,
        "default_value": null
      }
    ],
    "optional_positional": [],
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
    "category": "Filters"
  },
  "examples": []
}

register /usr/local/bin/nu_plugin_query  {
  "sig": {
    "name": "query web",
    "usage": "execute selector query on html/web",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [],
    "optional_positional": [],
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
      },
      {
        "long": "query",
        "short": "q",
        "arg": "String",
        "required": false,
        "desc": "selector query",
        "var_id": null,
        "default_value": null
      },
      {
        "long": "as-html",
        "short": "m",
        "arg": null,
        "required": false,
        "desc": "return the query output as html",
        "var_id": null,
        "default_value": null
      },
      {
        "long": "attribute",
        "short": "a",
        "arg": "String",
        "required": false,
        "desc": "downselect based on the given attribute",
        "var_id": null,
        "default_value": null
      },
      {
        "long": "as-table",
        "short": "t",
        "arg": "Table",
        "required": false,
        "desc": "find table based on column header list",
        "var_id": null,
        "default_value": null
      },
      {
        "long": "inspect",
        "short": "i",
        "arg": null,
        "required": false,
        "desc": "run in inspect mode to provide more information for determining column headers",
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
    "category": "Network"
  },
  "examples": [
    {
      "example": "http get https://phoronix.com | query web -q 'header'",
      "description": "Retrieve all `<header>` elements from phoronix.com website",
      "result": null
    },
    {
      "example": "http get https://en.wikipedia.org/wiki/List_of_cities_in_India_by_population\n    | query web -t [Rank City 'Population(2011)[3]' 'Population(2001)' 'State or union territory']",
      "description": "Retrieve a html table from Wikipedia and parse it into a nushell table using table headers as guides",
      "result": null
    },
    {
      "example": "http get https://www.nushell.sh | query web -q 'h2, h2 + p' | group 2 | each {rotate --ccw tagline description} | flatten",
      "description": "Pass multiple css selectors to extract several elements within single query, group the query results together and rotate them to create a table",
      "result": null
    },
    {
      "example": "http get https://example.org | query web --query a --attribute href",
      "description": "Retrieve a specific html attribute instead of the default text",
      "result": null
    }
  ]
}

register /usr/local/bin/nu_plugin_query  {
  "sig": {
    "name": "query xml",
    "usage": "execute xpath query on xml",
    "extra_usage": "",
    "search_terms": [],
    "required_positional": [
      {
        "name": "query",
        "desc": "xpath query",
        "shape": "String",
        "var_id": null,
        "default_value": null
      }
    ],
    "optional_positional": [],
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
    "category": "Filters"
  },
  "examples": []
}

