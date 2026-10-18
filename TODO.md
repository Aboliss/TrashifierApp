# TODO

Feature ideas for Trashifier, roughly in priority order within each group.
Tips and the "Which bin?" lookup target generic EU-wide rules; facts need a
real source (local waste authority, Eurostat) before they ship.

## Next up

- [ ] Repeating schedules: "Bio every Tuesday", "Plastic every 2nd Friday" instead of tapping each date
- [ ] "Which bin?" lookup: search an item (pizza box, battery, receipt) and see its bin with a short tip
- [ ] Bin guides: tap a bin for a Yes / No / Careful list of what goes in it
- [ ] "Did you know?" cards: a random recycling fact or tip on Home, said by Bin Buddy in a speech bubble
- [ ] "Bins are out" check-off: mark the evening task done, nudge again later if it isn't

## Reminders and schedule

- [ ] Import a schedule from an `.ics` calendar file published by the town
- [ ] Holiday shifts: move one pickup by a day without changing the repeat rule
- [ ] Custom bin types: glass, textiles, garden or bulky waste, with own color and icon
- [x] Settings: reminder day (day before or pickup day) and time
- [ ] Reminder time per bin (e.g. bio the evening before, paper the same morning)
- [ ] Best-practice tip in the reminder text ("Paper tomorrow. Flatten boxes so more fits.")
- [ ] Special waste info: where batteries, electronics, bulbs, paint and medicine go

## Playful

- [ ] Streaks: pickups in a row put out on time; Bin Buddy gets happier or earns hats
- [ ] Quiz mode: a one-question "Which bin?" game on Home with a weekly score
- [ ] Monthly recap: "You put out 9 bins in October, 4 of them recycling"
- [x] Seasonal Bin Buddy: Pumpkin Buddy in October, Santa Buddy in December (seasonal themes)

## Household

- [x] Share the schedule as a file or QR code so the whole household gets reminders
- [ ] Whose turn is it: rotate who takes the bins out each week

## Platform and polish

- [ ] Native-speaker review of the German, Spanish and Slovak texts (lib/l10n, values-*/strings.xml)
- [x] Export / import a backup of all pickup dates (there is no way to recover them today)
- [ ] Lock screen / Quick Settings tile with the next pickup
- [x] Localization: English, German, Spanish, Slovak (in-app picker; widgets and reminders follow)
- [ ] Widgets flip exactly at midnight and at the 8 AM cutoff instead of up to 6 hours later
- [x] One-time hint that Coming up rows can be swiped right to remove
- [ ] Allow removing the next pickup from the big Home card
- [x] Debug panel: "Reset hints" to bring back the swipe hint without clearing data
