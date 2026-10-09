# Parry Lab contract

`Rules.luau` is the frozen source of truth for timing, damage, input limits and
remote/snapshot names. Server time is authoritative. The 110 ms guard is deliberate;
the 150 ms arrival allowance tolerates delayed delivery, not unlimited rewind.
