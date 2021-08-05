
---
## Note: This is now defunct - it was merged into:
https://github.com/hudmol/yale_as_requests
---

# Yale Aeon Mappings

An ArchivesSpace plugin containing custom Aeon mappings for Yale University.

This plugin is used in conjunction with ArchivesSpace Aeon Fulfillment plugin developed by Atlas Systems:
https://github.com/AtlasSystems/ArchivesSpace-Aeon-Fulfillment-Plugin

It adds custom mappers for ArchivalObjects, Accessions and Containers.

Ensure this plugin loads after the Atlas plugin by placing it later in the array of plugins in config, like this:
```
  AppConfig[:plugins] = [..., 'aeon_fulfillment', 'yale_aeon_mappings', ...]
```

And enable the Aeon request button for container pages by adding this line to config:
```
  AppConfig[:aeon_fulfillment_record_types] = ['archival_object', 'accession', 'top_container']
```

Developed for Yale University by Hudson Molonglo.
