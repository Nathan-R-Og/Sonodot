extends Character

export var insta_shield = true
export var drop_dash = true
export var drp_max = 560.0
export var drp_spd = 480.0

func _ready():
	set_process(false)
	current_attack_shape = $AttackBoxes/Attack1

func _process(delta: float) -> void:
	is_rolling = owner.animation.current_animation == "DropCharge"

func erase_state():
	msm.state_collection.get_state("OnAir").cancel_drop()
