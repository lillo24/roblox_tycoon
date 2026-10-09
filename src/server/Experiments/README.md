# Opt-in experimental servers

Each feature subfolder owns one temporary Studio experiment. `Runtime.start()` is
called only by a disposable preview bootstrap from `New-ExperimentPlace.ps1`.
The ordinary server bootstrap continues to run the factory. Modules stay within
the existing Rojo-owned server folder; no Workspace mapping or saved-scene hook.
