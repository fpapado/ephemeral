# The following changes were made to our views

## Html.lazy for most things
No need to perform calculations if our lists of items have not changed.

## Html.Keyed.node for the entry list
This was advised online, and used wherever things are added/removed.
We already have unique ids for the entries, so it seemed natural.
Deletion does seem faster on the profile.
TODO: Potentially fixes a visual bug where deletion button would remain highlighted on non-deleted node

## Using Dict instead of List
I am not sure if this is a huge difference, but it used to be that Entries were a list and we'd manually List.filter when there was an update. On insertions, we'd just append to the start.
This will likely reduce performance when adding items, but access and updates are faster.
Does it actually make a difference? Eh, probably not so much.
It does seem to affect the startup time slightly.

## TODO
There is currently a big drop when adding all the markers to the map, partly because there is a message over a Port for each one.
This is an issue when starting up the UI, where we need to fetch from the DB and initialise both the list and the markers. Similarly for  sync updates.
[] Should make it such that there is a single Port message that goes out, with a list of markers to add
[] Compare

## Benchmarks?
I would really like to see a side-by side of the commit with these changes, and the previous one.
