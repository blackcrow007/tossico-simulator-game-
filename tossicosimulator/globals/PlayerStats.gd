# PlayerStats.gd
extends Node

# Risorse del giocatore
var money: float = 50.0  # Soldi iniziali
var mental_health: float = 75.0  # Salute mentale iniziale (0-100)

# Tempo: minuti totali trascorsi dall'inizio della settimana (1 settimana = 7 giorni * 24 ore * 60 minuti)
var current_time_minutes: int = 0  # Inizia dal minuto 0 (es. Lunedì mattina presto)
const MINUTES_IN_WEEK: int = 7 * 24 * 60

# Enum per le Fasi della Giornata
enum DayPhase { MATTINA, POMERIGGIO, SERA, NOTTE }

# Stato psicofisico
enum PhysicalState { SOBRIO, FATTO, ANSIOSO, IN_DOWN }
var physical_state: PhysicalState = PhysicalState.SOBRIO

# Lucidità
var lucidity: float = 100.0 # Lucidità iniziale (0-100)

# Disponibilità del plug
var is_plug_available: bool = true

# Enum per la Qualità dell'Erba
enum WeedQuality { SCADENTE, MEDIA, BUONA }

# Inventario dell'erba
var weed_inventory: Dictionary = {
    # Esempio: WeedQuality.SCADENTE: 1.0 (1.0 grammo)
}

# Event flags
var event_flags: Dictionary = {}

# Definizione degli orari per le fasi (ore del giorno, 0-23)
const MATTINA_START_HOUR = 7  # Dalle 7:00
const POMERIGGIO_START_HOUR = 13 # Dalle 13:00
const SERA_START_HOUR = 18    # Dalle 18:00
const NOTTE_START_HOUR = 23   # Dalle 23:00 (fino alle 6:59 del mattino dopo)

# TODO: Aggiungere funzioni per modificare e recuperare questi valori in modo controllato se necessario
# TODO: Aggiungere segnali per quando i valori cambiano, se l'UI deve reagire dinamicamente
# signal inventory_changed # Segnale per quando l'inventario cambia

func _ready():
    print("PlayerStats autoloaded and ready.")
    # Test iniziale della fase del giorno
    # print("Current day phase: ", DayPhase.keys()[get_current_day_phase()])
    # add_weed_to_inventory(WeedQuality.MEDIA, 0.5)
    # remove_weed_from_inventory(WeedQuality.MEDIA, 0.2)

# Funzione per impostare la disponibilità del plug
func set_plug_availability(available: bool):
	is_plug_available = available
	print("Plug availability set to: ", is_plug_available)

# Esempio di funzione per aggiungere soldi
func add_money(amount: float):
    money += amount
    print("Money: ", money)

# Esempio di funzione per cambiare la salute mentale
func change_mental_health(amount: float): # Renaming for consistency, though modify_mental_health is also fine
    mental_health = clamp(mental_health + amount, 0.0, 100.0)
    print("Mental Health: ", mental_health)

func modify_mental_health(amount: float): # Adding this to match EventManager call
    mental_health = clamp(mental_health + amount, 0.0, 100.0)
    print("Mental Health modified by: ", amount, " New value: ", mental_health)

# Funzione per far avanzare il tempo
func advance_time(minutes_passed: int):
    current_time_minutes += minutes_passed
    if current_time_minutes >= MINUTES_IN_WEEK:
        print("Fine della settimana raggiunta.")
        current_time_minutes = current_time_minutes % MINUTES_IN_WEEK
        print("Tempo resettato all'interno della settimana.")
    print("Time advanced by %d minutes. Current time: %s" % [minutes_passed, get_formatted_time()])

func get_day_of_week() -> String:
    var day_index = int(current_time_minutes / (24 * 60)) % 7
    var days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
    return days[day_index]

func get_hour_of_day() -> int:
    return int(current_time_minutes / 60) % 24

func get_minute_of_hour() -> int:
    return current_time_minutes % 60

func get_formatted_time() -> String:
    var phase_str = DayPhase.keys()[get_current_day_phase()]
    return "%s - %s - %02d:%02d" % [get_day_of_week(), phase_str, get_hour_of_day(), get_minute_of_hour()]

func get_current_day_phase() -> DayPhase:
    var current_hour = get_hour_of_day()
    if current_hour >= MATTINA_START_HOUR and current_hour < POMERIGGIO_START_HOUR:
        return DayPhase.MATTINA
    elif current_hour >= POMERIGGIO_START_HOUR and current_hour < SERA_START_HOUR:
        return DayPhase.POMERIGGIO
    elif current_hour >= SERA_START_HOUR and current_hour < NOTTE_START_HOUR:
        return DayPhase.SERA
    else:
        return DayPhase.NOTTE

func set_physical_state(new_state: PhysicalState):
    physical_state = new_state
    print("Physical State: ", PhysicalState.keys()[physical_state])

func change_lucidity(amount: float):
    lucidity = clamp(lucidity + amount, 0.0, 100.0)
    print("Lucidity: ", lucidity)

# NUOVE FUNZIONI PER L'INVENTARIO DELL'ERBA:
func add_weed_to_inventory(quality: WeedQuality, amount_grams: float):
    if weed_inventory.has(quality):
        weed_inventory[quality] += amount_grams
    else:
        weed_inventory[quality] = amount_grams
    print("Aggiunti %.1fg di erba %s. Inventario attuale: %s" % [amount_grams, WeedQuality.keys()[quality], weed_inventory])
    # emit_signal("inventory_changed")

func remove_weed_from_inventory(quality: WeedQuality, amount_grams: float) -> bool:
    if weed_inventory.has(quality) and weed_inventory[quality] >= amount_grams:
        weed_inventory[quality] -= amount_grams
        if weed_inventory[quality] < 0.01: # Tolleranza per float
            weed_inventory.erase(quality)
        print("Rimossi %.1fg di erba %s. Inventario attuale: %s" % [amount_grams, WeedQuality.keys()[quality], weed_inventory])
        # emit_signal("inventory_changed")
        return true
    else:
        print("Non abbastanza erba %s per rimuovere %.1fg. Inventario attuale: %s" % [WeedQuality.keys()[quality], amount_grams, weed_inventory])
        return false

func get_weed_amount(quality: WeedQuality) -> float:
    if weed_inventory.has(quality):
        return weed_inventory[quality]
    return 0.0

func get_weed_inventory() -> Dictionary:
    return weed_inventory.duplicate(true) # Deep copy, though for enum keys and float values, shallow (false) is often fine. True is safer.

# --- Event Flag System ---
func set_event_flag(flag_name: String, value: bool):
	event_flags[flag_name] = value
	print("Event flag set: %s = %s" % [flag_name, value])

func get_event_flag(flag_name: String) -> bool:
	if event_flags.has(flag_name):
		return event_flags[flag_name]
	return false # Default to false if the flag hasn't been set

func has_event_flag(flag_name: String) -> bool:
	return event_flags.has(flag_name)
