extends Node2D

@onready var money_label: Label = $MoneyLabel
@onready var mental_health_label: Label = $MentalHealthLabel
@onready var time_label: Label = $TimeLabel
@onready var state_label: Label = $StateLabel
@onready var lucidity_label: Label = $LucidityLabel
@onready var actions_container: VBoxContainer = $ActionsContainer
@onready var plug_interaction_ui: PanelContainer = $PlugInteractionUI_Instance
@onready var event_notification_label: Label = $EventNotificationLabel # Added for event messages
@onready var narrative_choice_popup: PanelContainer = $NarrativeChoicePopup # Added for narrative choices

func _ready():
    if not Engine.has_singleton("PlayerStats"):
        printerr("PlayerStats autoload non trovato. Assicurati sia configurato nel project.godot")
        return # Non continuare se PlayerStats non c'è

    if plug_interaction_ui:
        plug_interaction_ui.hide()
        if not plug_interaction_ui.is_connected("plug_ui_closed", Callable(self, "_on_plug_ui_closed")):
            var error_code = plug_interaction_ui.connect("plug_ui_closed", Callable(self, "_on_plug_ui_closed"))
            if error_code != OK:
                printerr("Errore nel connettere plug_ui_closed: ", error_code)
    else:
        printerr("Istanza di PlugInteractionUI non trovata in DayView.")

    if event_notification_label == null:
        printerr("EventNotificationLabel non trovato. Assicurati sia presente nella scena DayView.tscn e nominato correttamente.")
    else:
        event_notification_label.text = "" # Clear on ready or set default

    # Ensure EventManager is available
    if not Engine.has_singleton("EventManager"):
        printerr("EventManager autoload non trovato.")

    # Setup for NarrativeChoicePopup
    if narrative_choice_popup:
        if not narrative_choice_popup.is_connected("choice_selected", Callable(self, "_on_narrative_choice_made")):
            var err = narrative_choice_popup.connect("choice_selected", Callable(self, "_on_narrative_choice_made"))
            if err != OK:
                printerr("Failed to connect 'choice_selected' signal from NarrativeChoicePopup.")
        # ChoicePopup.gd should hide itself in its own _ready(), but we can ensure it here if needed.
        # narrative_choice_popup.hide()
    else:
        printerr("NarrativeChoicePopup node not found in DayView. Make sure it's instanced and named correctly.")

    # Example: Connecting a temporary button to trigger the choice (ensure this button exists in DayView.tscn)
    var trigger_choice_button = find_child("TriggerChoiceButton", true, false) # Search recursively, don't own it
    if trigger_choice_button and trigger_choice_button is Button:
        if not trigger_choice_button.is_connected("pressed", Callable(self, "_on_trigger_choice_button_pressed")):
            trigger_choice_button.connect("pressed", Callable(self, "_on_trigger_choice_button_pressed"))
    elif get_tree().get_nodes_in_group("DEBUG_BUTTONS").size() == 0: # Avoid error spam if button is intentionally not there
        print("Optional: TriggerChoiceButton not found. This is okay if not using it for testing this specific choice.")


    update_ui()

func _process(_delta):
    if Engine.has_singleton("PlayerStats"):
        update_ui()

func update_ui():
    if not Engine.has_singleton("PlayerStats"):
        return

    money_label.text = "Soldi: €" + str(PlayerStats.money)
    mental_health_label.text = "Salute Mentale: " + ("%.1f" % PlayerStats.mental_health) + "%" # Format float
    time_label.text = "Tempo: " + PlayerStats.get_formatted_time()

    var ps_keys = PlayerStats.PhysicalState.keys()
    if PlayerStats.physical_state >= 0 and PlayerStats.physical_state < ps_keys.size():
        state_label.text = "Stato: " + ps_keys[PlayerStats.physical_state]
    else:
        state_label.text = "Stato: N/D"

    lucidity_label.text = "Lucidità: " + ("%.1f" % PlayerStats.lucidity) + "%" # Format float

    # Update event notification label based on current events (optional, could be event-driven)
    # For now, it's mostly updated when new events are triggered or when actions are attempted.
    # if Engine.has_singleton("EventManager") and EventManager.is_event_active("plug_arrested"):
    #    if event_notification_label:
    #        event_notification_label.text = "ATTENZIONE: " + EventManager.active_events["plug_arrested"].description
    # elif event_notification_label:
    #    event_notification_label.text = ""


func _on_sleep_button_pressed():
    if not Engine.has_singleton("PlayerStats"): return
    if Engine.has_singleton("EventManager"):
        EventManager.process_daily_events() # Process events when time passes significantly
    PlayerStats.advance_time(8 * 60)
    PlayerStats.change_mental_health(10)
    PlayerStats.set_physical_state(PlayerStats.PhysicalState.SOBRIO)
    PlayerStats.change_lucidity(5)

func _on_work_button_pressed():
    if not Engine.has_singleton("PlayerStats"): return
    PlayerStats.advance_time(4 * 60)
    PlayerStats.add_money(40)
    PlayerStats.change_mental_health(-15) # Should be modify_mental_health if we stick to that
    PlayerStats.change_lucidity(-5)
    if Engine.has_singleton("EventManager"):
        EventManager.process_daily_events() # Process events if work also passes a day or significant time

func _on_go_to_plug_button_pressed():
    if not Engine.has_singleton("EventManager") or not Engine.has_singleton("PlayerStats"):
        printerr("EventManager or PlayerStats not found.")
        return

    if EventManager.is_event_active("plug_arrested"):
        if event_notification_label:
            var event_details = EventManager.active_events["plug_arrested"]
            event_notification_label.text = "EVENTO: " + event_details.description + " Il plug non è disponibile."
            # Simple timer to clear the message
            var timer = get_tree().create_timer(4.0)
            timer.connect("timeout", Callable(self, "_clear_event_notification"))
        print("Azione bloccata: Evento 'plug_arrested' attivo.")
        # Do not open plug_interaction_ui
    elif not PlayerStats.is_plug_available: # General check, could be set by other factors too
        if event_notification_label:
            event_notification_label.text = "Il plug non è disponibile al momento."
            var timer = get_tree().create_timer(3.0)
            timer.connect("timeout", Callable(self, "_clear_event_notification"))
        print("Azione bloccata: PlayerStats.is_plug_available is false.")
    else:
        if plug_interaction_ui:
            plug_interaction_ui.open_panel()
            print("Opening Plug Interaction UI.")
            if event_notification_label: # Clear any previous event message
                event_notification_label.text = ""
        else:
            printerr("Tentativo di aprire Plug UI ma plug_interaction_ui non è valido/trovato.")

func _on_plug_ui_closed():
    print("Plug UI chiusa, DayView UI verrà aggiornata.")
    update_ui()

func _clear_event_notification():
    if event_notification_label:
        event_notification_label.text = ""

# Temporary button to trigger the event for testing
func _on_trigger_plug_arrest_button_pressed():
    if not Engine.has_singleton("EventManager"):
        printerr("EventManager not found.")
        return

    EventManager.trigger_event("plug_arrested")

    if EventManager.is_event_active("plug_arrested"):
        if event_notification_label:
            event_notification_label.text = "ATTIVATO: " + EventManager.active_events["plug_arrested"].description
    else:
        if event_notification_label:
             event_notification_label.text = "Failed to trigger plug_arrested or it was immediately deactivated."

    update_ui() # Reflect stat changes

# --- NARRATIVE CHOICE SYSTEM ---

func _on_trigger_choice_button_pressed(): # Connected to the temporary "TriggerChoiceButton"
    if not narrative_choice_popup:
        printerr("NarrativeChoicePopup is not available to display choice.")
        return

    var prompt = "Your phone buzzes. It's your mom. What do you do?"
    var choices = ["Answer the call", "Ignore it and go back to scrolling"]
    narrative_choice_popup.display_choice(prompt, choices)

func _on_narrative_choice_made(choice_index: int):
    if not Engine.has_singleton("PlayerStats"):
        printerr("PlayerStats not found, cannot apply choice effects.")
        return

    if event_notification_label == null:
        printerr("EventNotificationLabel not found, cannot display choice outcome text.")
        # Still proceed with logic, but log this issue.

    var outcome_text = ""
    if choice_index == 0: # Answered call
        outcome_text = "You talked to your mom. It was... a conversation."
        PlayerStats.advance_time(15) # Consumes 15 minutes
        PlayerStats.modify_mental_health(-5) # Slightly stressful
        PlayerStats.set_event_flag("mom_call_answered", true)
    elif choice_index == 1: # Ignored call
        outcome_text = "You ignored the call. Maybe later. Or never."
        PlayerStats.advance_time(5) # Less time consumed
        PlayerStats.modify_mental_health(-2) # Minor guilt/anxiety
        PlayerStats.change_lucidity(-3) # Distraction
        PlayerStats.set_event_flag("mom_call_answered", false)
    else:
        outcome_text = "An unexpected choice index was received: " + str(choice_index)
        printerr(outcome_text)

    if event_notification_label:
        event_notification_label.text = outcome_text
        # Optional debug line to show flag value:
        # event_notification_label.text += "\nDebug: mom_call_answered=" + str(PlayerStats.get_event_flag("mom_call_answered"))

        # Optional: Clear the notification after a few seconds
        var timer = get_tree().create_timer(5.0) # 5 seconds
        timer.connect("timeout", Callable(self, "_clear_event_notification"))

    update_ui() # Update UI to reflect changes in stats
