# PlugInteraction.gd
extends PanelContainer

# Segnale per quando la UI del plug deve essere chiusa
signal plug_ui_closed

# Riferimenti ai nodi della UI
@onready var quality_option_button: OptionButton = $MainVBox/QualityBox/QualityOptionButton
@onready var quantity_spin_box: SpinBox = $MainVBox/QuantityBox/QuantitySpinBox
@onready var cost_label: Label = $MainVBox/CostLabel
@onready var buy_button: Button = $MainVBox/ButtonsBox/BuyButton
@onready var exit_button: Button = $MainVBox/ButtonsBox/ExitButton

# Prezzi base per grammo per qualità (da definire)
const BASE_PRICES = {
    PlayerStats.WeedQuality.SCADENTE: 5.0,  # €5 al grammo
    PlayerStats.WeedQuality.MEDIA: 10.0, # €10 al grammo
    PlayerStats.WeedQuality.BUONA: 15.0  # €15 al grammo
}

# Quantità disponibili per lo SpinBox (o per altre logiche)
# Per ora lo SpinBox è libero, ma potremmo voler limitare le quantità acquistabili
# const AVAILABLE_QUANTITIES = [0.2, 0.5, 1.0, 2.0]

func _ready():
    # Popola l'OptionButton delle qualità
    populate_quality_options()

    # Connetti i segnali
    quality_option_button.item_selected.connect(_on_selection_changed)
    quantity_spin_box.value_changed.connect(_on_quantity_changed)
    buy_button.pressed.connect(_on_buy_button_pressed)
    exit_button.pressed.connect(_on_exit_button_pressed)

    # Aggiorna il costo iniziale
    update_cost_label()

    # Nascondi questa UI all'inizio, verrà mostrata da DayView
    self.hide()


func populate_quality_options():
    quality_option_button.clear()
    var weed_qualities = PlayerStats.WeedQuality.keys() # ["SCADENTE", "MEDIA", "BUONA"]
    for i in range(weed_qualities.size()):
        var quality_name = weed_qualities[i]
        # Aggiunge l'item con il nome testuale, l'ID sarà l'indice numerico dell'enum
        quality_option_button.add_item(quality_name.capitalize(), PlayerStats.WeedQuality.values()[i])

    # Se ci sono opzioni, seleziona la prima di default
    if quality_option_button.item_count > 0:
        quality_option_button.select(0)
        # update_cost_label() # Aggiorna il costo basato sulla selezione di default - Già chiamato in _ready
    # L'aggiornamento del costo avviene comunque in _ready dopo populate_quality_options


func _on_selection_changed(_index = -1): # L'indice è passato dal segnale item_selected
    update_cost_label()

func _on_quantity_changed(_value = 0.0): # Il valore è passato dal segnale value_changed
    update_cost_label()

func calculate_current_cost() -> float:
    if quality_option_button.get_selected_id() < 0: # Check if a valid item is selected
        return 0.0

    var selected_quality_enum_value = quality_option_button.get_selected_id() # Questo è l'ID (valore enum)
    var quantity = quantity_spin_box.value

    if BASE_PRICES.has(selected_quality_enum_value):
        var price_per_gram = BASE_PRICES[selected_quality_enum_value]
        return price_per_gram * quantity
    return 0.0


func update_cost_label():
    var cost = calculate_current_cost()
    cost_label.text = "Costo: €" + ("%.2f" % cost) # Formatta a due decimali


func _on_buy_button_pressed():
    if not Engine.has_singleton("PlayerStats"):
        printerr("PlayerStats non trovato!")
        return

    if quality_option_button.get_selected_id() < 0:
        print("Nessuna qualità selezionata.")
        # Potremmo mostrare un messaggio all'utente qui
        return

    var selected_quality_enum_value = quality_option_button.get_selected_id()
    var quantity = quantity_spin_box.value
    var cost = calculate_current_cost()

    if PlayerStats.money >= cost:
        PlayerStats.add_money(-cost)
        PlayerStats.add_weed_to_inventory(selected_quality_enum_value, quantity)
        print("Acquisto completato: %.1fg di erba %s per €%.2f" % [quantity, PlayerStats.WeedQuality.keys()[selected_quality_enum_value], cost])
        # PlayerStats.advance_time(15) # Opzionale: interazione consuma tempo

        # Potrebbe essere utile resettare o chiudere la UI
        # _on_exit_button_pressed()
    else:
        print("Non abbastanza soldi per completare l'acquisto.")
        cost_label.text = "Costo: €" + ("%.2f" % cost) + " (Soldi insuff!)"


func _on_exit_button_pressed():
    self.hide()
    emit_signal("plug_ui_closed")


func open_panel():
    if quality_option_button.item_count > 0:
        quality_option_button.select(0)
    quantity_spin_box.value = 0.2 # o quantity_spin_box.min_value
    update_cost_label() # Resetta il testo del costo (rimuove "Soldi insuff!")
    self.show()
