extends "res://scripts/projectile.gd"

var speed = 120
var up = true

func _ready():
	create_shadow(3, 1)
	knockback = Vector2(50, - 250)
	effect_hit = preload("res://scenes/effect_proj_darkgoto_attack_hit.tscn")
	effect_offset = Vector2(8, 0)

func set_up(scale_x, is_up):
	sprite.scale.x = scale_x
	up = is_up
	if sprite.scale.x > 0:
		if up:
			sprite.rotation_degrees -= 45
		else :
			sprite.rotation_degrees += 45
	else :
		if up:
			sprite.rotation_degrees += 45
		else :
			sprite.rotation_degrees -= 45

func reflect(hitbox_owner):
	flip()
	sprite.rotation_degrees = 0
	set_up(sprite.scale.x, not up)
	change_players(hitbox_owner)

func flip():
	sprite.rotation_degrees = 0
	set_up(sprite.scale.x * - 1, up)

func process_move():
	if up:
		linear_vel = Vector2(speed * sprite.scale.x, - speed)
	else :
		linear_vel = Vector2(speed * sprite.scale.x, speed)
	
	.process_move()
