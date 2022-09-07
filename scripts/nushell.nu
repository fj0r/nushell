export extern "nu" [
  --help(-h)                # Display this help message
  --stdin                   # redirect the stdin
  --login(-l)               # start as a login shell
  --interactive(-i)         # start as an interactive shell
  --version(-v)             # print the version
  --perf(-p)                # start and print performance metrics during startup
  --testbin:string          # run internal test binary
  --commands(-c):string     # run the given commands and then exit
  --config:string           # start with an alternate config file
  --env-config:string       # start with an alternate environment config file
  --log-level:string        # log level for performance logs
  --threads:int             # threads to use for parallel commands
  --table-mode(-m):string   # the table mode to use. rounded is default.
  ...script:string
]
