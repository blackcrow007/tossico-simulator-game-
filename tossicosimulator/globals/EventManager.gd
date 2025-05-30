extends Node

# Dictionary to store currently active events, keyed by event ID.
var active_events: Dictionary = {}

# Dictionary to store all possible event definitions.
var event_definitions: Dictionary = {}

func _ready():
	# Initialize any necessary variables.
	# Define the "plug_arrested" event
	define_event({
		"id": "plug_arrested",
		"description": "You hear sirens. Looks like your plug got busted!",
		# "is_active" will be managed by active_events dictionary
		"duration_days": 3,
		"effects": {"mental_health_change": -20, "plug_unavailable": true}
	})

# Adds an event definition.
func define_event(event_data: Dictionary):
	if event_data.has("id"):
		event_definitions[event_data["id"]] = event_data
	else:
		print("Error: Event data is missing an 'id'.")

# Activates an event.
func trigger_event(event_id: String):
	if not event_definitions.has(event_id):
		print("Error: Event definition not found: ", event_id)
		return

	if is_event_active(event_id):
		print("Info: Event already active: ", event_id)
		# Optionally, re-apply effects or reset duration if needed
		# For now, just log and return
		return

	var event_def = event_definitions[event_id]
	var new_active_event = event_def.duplicate(true) # Create a deep copy

	new_active_event["is_active"] = true # Explicitly set, though redundant with presence in active_events
	if new_active_event.has("duration_days"):
		new_active_event["days_remaining"] = new_active_event["duration_days"]

	active_events[event_id] = new_active_event
	apply_event_effects(event_id)
	print("Event triggered: ", event_id)

# Deactivates an event.
func deactivate_event(event_id: String):
	if active_events.has(event_id):
		active_events.erase(event_id)
		print("Event deactivated and removed from active list: ", event_id)
	else:
		print("Error: Active event not found for deactivation: ", event_id)

# Checks if an event is currently active.
func is_event_active(event_id: String) -> bool:
	return active_events.has(event_id)

# Applies the effects of an active event.
func apply_event_effects(event_id: String):
	if not active_events.has(event_id):
		print("Error: Cannot apply effects. Event not active or not found: ", event_id)
		return

	var event_data = active_events[event_id]
	if event_data.has("effects"):
		var effects = event_data["effects"]
		# Apply effects to PlayerStats
		if PlayerStats != null:
			if effects.has("mental_health_change"):
				PlayerStats.modify_mental_health(effects["mental_health_change"])

			if effects.has("plug_unavailable") and effects["plug_unavailable"] == true:
				if PlayerStats.has_method("set_plug_availability"):
					PlayerStats.set_plug_availability(false)
				elif PlayerStats.has("is_plug_available"): # Fallback for direct variable access
					PlayerStats.is_plug_available = false
				else:
					print("Warning: PlayerStats does not have 'set_plug_availability' method or 'is_plug_available' var for event: ", event_id)
		else:
			print("Error: PlayerStats not found. Cannot apply event effects.")
		print("Applied effects for event: ", event_id)

# A function to be called daily to update timed events.
func process_daily_events():
	var event_ids_to_process = active_events.keys() # Get keys to iterate over

	for event_id in event_ids_to_process:
		if not active_events.has(event_id): # Event might have been deactivated by another process
			continue

		var event = active_events[event_id]

		if event.has("days_remaining"):
			event["days_remaining"] -= 1
			print("Processing daily event: ", event_id, ", Days remaining: ", event["days_remaining"])

			if event["days_remaining"] <= 0:
				# Revert effects if applicable
				if event.has("effects") and event["effects"].has("plug_unavailable") and event["effects"]["plug_unavailable"] == true:
					if PlayerStats != null:
						if PlayerStats.has_method("set_plug_availability"):
							PlayerStats.set_plug_availability(true) # Plug becomes available
						elif PlayerStats.has("is_plug_available"): # Fallback for direct variable access
							PlayerStats.is_plug_available = true
						else:
							print("Warning: PlayerStats does not have 'set_plug_availability' or 'is_plug_available' to revert plug_unavailable effect for event: ", event_id)

					else:
						print("Error: PlayerStats not found. Cannot reset plug availability.")

				deactivate_event(event_id) # This will remove it from active_events
		else:
			# If an active event has no "days_remaining", it might be a persistent event
			# or one that is deactivated by other means. For now, we do nothing.
			pass
