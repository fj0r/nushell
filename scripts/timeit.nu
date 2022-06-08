let-env __timing = date now

let _ti_execution = {
    load-env {__timing: (date now)}
}

let _ti_prompt = {
    load-env {__timing: ((date now) - $env.__timing)}
}

let-env config = ($env.config
                 | update hooks.pre_execution ($env.config.hooks.pre_execution | append $_ti_execution)
                 | update hooks.pre_prompt ($env.config.hooks.pre_prompt | append $_ti_prompt)
                 )
