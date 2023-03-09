extends Node2D

export var character_values : Resource
onready var msm = $MSM
onready var attack_box = $AttackBoxes
onready var current_attack_shape : CollisionShape2D

var is_rolling = false

class_name Character
