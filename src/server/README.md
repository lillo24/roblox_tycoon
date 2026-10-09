# Server responsibilities

Bootstrap starts TycoonRuntime, the engine adapter for player lifecycle, attributes, prompts and income. Session owns the unchanged session economy. PlotWorld owns the authored map's factory scaffolding; MapLayout validates the map contract before writes. SupplyRuntime/SupplyEvent own Session's lobby event.

Infinite uses Persistence/Profiles for lifecycle and its sole checkpoint scheduler. PropertyEdits owns non-yielding purchase/layout/palette transactions. PropertyWorld renders accepted property objects by revision; it never runs for Session. Shared Infinite/Catalogue, Placement and Models own definitions, geometry rules and bounded silhouettes.

Infinite's private TycoonProperty RemoteFunction is limited to four requests per second per active player. Profiles validates ready lease, separate arrival epoch, exact lot, bounded primitive payload, monotonic sequence and expected property revision. An exact repeat of the latest request returns its previous result; older/reused sequences refuse. No preview motion sends a request. Server income is reconstructed from ownership, including stored equipment.
