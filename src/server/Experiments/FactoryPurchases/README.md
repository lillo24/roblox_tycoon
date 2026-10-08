# Walk-on purchase server

`Runtime.luau` opts the existing tycoon runtime into walk-on mode only in a generated
preview. `WalkOn.luau` owns 20 Hz oriented pad sampling, requester-only entry offers,
live character/ownership/position rechecks, and pad instructions. It routes accepted
offers through the original server-authoritative purchase callback and catalogue.
`Visits.luau` owns one-use/expiring offers, exit hysteresis, character generations
and disconnect cleanup. A visit consumes one attempt even when blocked or unfunded.
