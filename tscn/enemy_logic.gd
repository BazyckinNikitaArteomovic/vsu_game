extends Node

enum {
	IDLE,
	WANDERING,
	FOLLOWING,
	ATTACK
}
@onready var player = get_parent().get_parent().get_node("Character")
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@export var CanFly: bool = false
@export var cur_health = 10
@export var damage = 2
const WalkSpeed = 100
const RunSpeed = 300
const accel = 7
var state = IDLE
var axis = [Vector2.LEFT, Vector2.RIGHT]


func _ready() -> void:
	var animated_sprite = get_parent().get_node("AnimatedSprite2D")
	animated_sprite.connect("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished"))
	randomize()


func _physics_process(delta: float) -> void:
	if state == IDLE:
		get_parent().get_node("AnimatedSprite2D").play("idle")
		if $TimerIdle.is_stopped():
			get_parent().velocity.x = 0
			$TimerIdle.start(randi_range(0, 4))
			
	elif state == WANDERING:
		if $TimerWandering.is_stopped():
			var cur_axis = axis.pick_random()
			get_parent().get_node("AnimatedSprite2D").play("run")
			if cur_axis == Vector2.LEFT:
				get_parent().get_node("AnimatedSprite2D").flip_h = true
			elif cur_axis == Vector2.RIGHT:
				get_parent().get_node("AnimatedSprite2D").flip_h = false
			$TimerWandering.start(randi_range(1, 3))
			get_parent().velocity = cur_axis * WalkSpeed
	
	elif state == FOLLOWING:
		var direction_x = player.global_position.x - get_parent().global_position.x
		if direction_x < 0:
			get_parent().get_node("AnimatedSprite2D").flip_h = true
		elif direction_x > 0:
			get_parent().get_node("AnimatedSprite2D").flip_h = false
		get_parent().get_node("AnimatedSprite2D").play("run")
		$TimerIdle.stop()
		$TimerWandering.stop()
		if CanFly:
			nav.target_position = player.global_position
			var direction = nav.get_next_path_position() - get_parent().global_position
			direction = direction.normalized()
			get_parent().velocity = get_parent().velocity.lerp(direction * RunSpeed, accel * delta)
		else:
			var path = (player.global_position - get_parent().global_position).normalized()
			get_parent().velocity.x = (-1 if Vector2.RIGHT.dot(path) < Vector2.LEFT.dot(path) else 1) * RunSpeed
		
	elif state == ATTACK:
		get_parent().get_node("AnimatedSprite2D").play("attack")
	if !CanFly:
		check_down()


func check_down():
	var speed = WalkSpeed 
	var velocity = get_parent().velocity.normalized()
	if velocity == Vector2.LEFT and !$RayCastL.is_colliding():
		if state == FOLLOWING:
			state = WANDERING
		get_parent().velocity = Vector2.RIGHT * speed
	if velocity == Vector2.RIGHT and !$RayCastR.is_colliding():
		if state == FOLLOWING:
			state = WANDERING
		get_parent().velocity = Vector2.LEFT * speed


func get_damage(weapon):
	cur_health -= Weapon.get_weapon_damage(weapon)
	get_parent().get_node("AnimatedSprite2D").play("damaged")
	if cur_health <= 0:
		get_parent().queue_free()
	

func _on_timer_idle_timeout() -> void:
	state = WANDERING


func _on_timer_wandering_timeout() -> void:
	state = IDLE


func _on_detect_zone_body_entered(body: Node2D) -> void:
	if body == player:
		state = FOLLOWING


func _on_exit_zone_body_exited(body: Node2D) -> void:
	if body == player or (state == ATTACK or state == FOLLOWING):
		state = IDLE


func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body == player:
		state = ATTACK


func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body == player:
		state = FOLLOWING


func _on_AnimatedSprite2D_animation_finished():
	if (get_parent().get_node("AnimatedSprite2D").animation == "attack"):
		player.get_damage(damage)
