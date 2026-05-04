class_name VitalsBook
extends Book

# Accounts are vital identifiers (e.g. &"hunger", &"fatigue", &"morale").
# Sign convention: positive balance = satisfied; negative entry = depletion.
# `balance("hunger")` is the actor's current hunger level (running net).
