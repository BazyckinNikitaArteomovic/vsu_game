extends CharacterBody2D

enum {
	MOVE,
	ATTACK,
	ATTACK1,
	ATTACK2,
	ATTACK3
	
}

const mobs = ["Mob", "bomb droid"]
const SPEED = 600.0
const JUMP_VELOCITY = -650.0
var weapon = Weapon.new_weapon(1)
var health = 20.0
var max_health = 20
var heal_effect = 1.0
var combo = false
var was_on_floor = true
@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
var state = MOVE
var mobs_in_attack_zone = []
var mobs_in_attack_3_zone = []

func _physics_process(delta: float) -> void:
	if animPlayer.current_animation not in ["atk", "atk 1", "atk 2", "atk 3"]:
		match state:
			MOVE:
				move_state()
			ATTACK:
				attack_state()
			ATTACK1:
				attack1_state()
			ATTACK2:
				attack2_state()
			ATTACK3:
				attack3_state()
	else:
		if Input.is_action_just_pressed("attack"):
			combo = true
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if not was_on_floor:
			animPlayer.play("land")
			velocity.x = move_toward(velocity.x, 0, 200)

	if (velocity.y > 0 and animPlayer.current_animation != "fall" and 
	state != ATTACK and  state != ATTACK1 and state != ATTACK2 and state != ATTACK3):
		animPlayer.play("fall")

	if (Input.is_action_just_pressed("jump") and is_on_floor() and 
	state != ATTACK and  state != ATTACK1 and state != ATTACK2 and state != ATTACK3):
		velocity.y = JUMP_VELOCITY
		animPlayer.play("jump")
		
	was_on_floor = is_on_floor()
	move_and_slide()

func move_state():
	var direction := Input.get_axis("left", "right")
	if animPlayer.current_animation == "land":
		await animPlayer.animation_finished
	if direction:
		if velocity.y == 0:
			velocity.x = direction * SPEED
			animPlayer.play("run")
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED, 10)
	else:
		if velocity.y == 0:
			animPlayer.play("idle")
			velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, 5)
	if direction == -1:
		anim.flip_h = true
	elif direction == 1:
		anim.flip_h = false
	if Input.is_action_just_pressed("attack"):
		state = ATTACK
	
func attack_state():
	if animPlayer.current_animation == "land":
		return
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("atk")
	await animPlayer.animation_finished
	if combo:
		combo = false
		state = ATTACK1
	else:
		state = MOVE

func attack1_state():
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("atk 1")
	await animPlayer.animation_finished
	if combo:
		combo = false
		state = ATTACK2
	else:
		state = MOVE

func attack2_state():
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("atk 2")
	await animPlayer.animation_finished
	if combo:
		combo = false
		state = ATTACK3
	else:
		state = MOVE

func attack3_state():
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	animPlayer.play("atk 3")
	await animPlayer.animation_finished
	if combo:
		combo = false
		state = ATTACK
	else:
		state = MOVE
	
func is_combo():
	pass
	
	
func heal():
	var heals = int($Stats/HBoxContainer2/heals.text)
	if heals > 0:
		heals -= 1
		health += 12 * heal_effect
		if health > max_health:
			health = max_health
		$Stats/HBoxContainer2/heals.text = heals

func get_damage(damage: float):
	health -= damage
	if health <= 0:
		death()

func death():
	animPlayer.play("death")
	await animPlayer.animation_finished
	get_parent().get_tree().change_scene_to_file("res://tscn/start_scene.tscn")

func _on_attack_3_body_entered(body: Node2D) -> void:
	if body.name in mobs:
		mobs_in_attack_3_zone.append(body)


func _on_attack_3_body_exited(body: Node2D) -> void:
	if body.name in mobs:
		mobs_in_attack_3_zone.erase(body)


func _on_attack_body_entered(body: Node2D) -> void:
	if body.name in mobs:
		mobs_in_attack_zone.append(body)
	

func _on_attack_body_exited(body: Node2D) -> void:
	if body.name in mobs:
		mobs_in_attack_zone.erase(body)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name in ["atk", "atk 1", "atk 2"]:
		if mobs_in_attack_zone != []:
			for i in mobs_in_attack_zone:
				i.get_node("EnemyLogic").get_damage(weapon)
	elif anim_name == "atk 3":
		if mobs_in_attack_3_zone != []:
			for j in mobs_in_attack_3_zone:
				j.get_node("EnemyLogic").get_damage(weapon)
		
